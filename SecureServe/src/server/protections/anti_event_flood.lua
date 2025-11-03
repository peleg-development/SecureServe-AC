---@class AntiEventFloodModule
local AntiEventFlood = {}

local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")

local playerEventCounts = {}
local playerEventTimestamps = {}
local blockedEvents = {}

-- Configuration
local MAX_EVENTS_PER_SECOND = 25       -- Max events per player per second
local EVENT_WINDOW = 1000               -- Time window in ms (1 second)
local BLOCKED_EVENT_THRESHOLD = 5       -- Times a player can trigger blocked events
local SUSPICIOUS_EVENT_THRESHOLD = 50   -- Events in window that trigger warning

-- Known dangerous/suspicious events that should be monitored
local MONITORED_EVENTS = {
    -- Money/economy events
    "esx:giveInventoryItem",
    "esx:giveItem",
    "bank:deposit",
    "bank:withdraw",
    
    -- Admin events
    "admin:giveWeapon",
    "admin:giveMoney",
    "admin:setJob",
    
    -- Vehicle events
    "esx:spawnVehicle",
    "vehicle:spawn",
    
    -- Weapon events
    "weapons:giveWeapon",
    "GiveWeapon",
}

-- Events that should never come from client
local BLOCKED_CLIENT_EVENTS = {
    "esx:giveInventoryItem",
    "bank:addMoney",
    "bank:removeMoney",
    "__cfx_internal:commandFallback",
}

---@description Check if event is monitored
local function isMonitoredEvent(eventName)
    for _, monitored in ipairs(MONITORED_EVENTS) do
        if string.lower(eventName) == string.lower(monitored) then
            return true
        end
    end
    return false
end

---@description Check if event should be blocked from client
local function isBlockedClientEvent(eventName)
    for _, blocked in ipairs(BLOCKED_CLIENT_EVENTS) do
        if string.lower(eventName) == string.lower(blocked) then
            return true
        end
    end
    return false
end

---@description Check for event flooding
local function checkEventFlood(playerId, eventName)
    if not playerEventCounts[playerId] then
        playerEventCounts[playerId] = {}
        playerEventTimestamps[playerId] = {}
    end
    
    local currentTime = os.time() * 1000
    
    -- Initialize for this event
    if not playerEventCounts[playerId][eventName] then
        playerEventCounts[playerId][eventName] = 0
        playerEventTimestamps[playerId][eventName] = {}
    end
    
    local timestamps = playerEventTimestamps[playerId][eventName]
    
    -- Add current timestamp
    table.insert(timestamps, currentTime)
    
    -- Remove old timestamps
    for i = #timestamps, 1, -1 do
        if currentTime - timestamps[i] > EVENT_WINDOW then
            table.remove(timestamps, i)
        end
    end
    
    -- Check total events in window
    local totalEvents = 0
    for _, eventTimestamps in pairs(playerEventTimestamps[playerId]) do
        totalEvents = totalEvents + #eventTimestamps
    end
    
    -- Check for flooding
    if #timestamps > MAX_EVENTS_PER_SECOND then
        return true, #timestamps, "event_specific"
    end
    
    if totalEvents > SUSPICIOUS_EVENT_THRESHOLD then
        return true, totalEvents, "total_flood"
    end
    
    return false, #timestamps, "normal"
end

---@description Initialize anti-event flood protection
function AntiEventFlood.initialize()
    -- Hook into server event handler
    local originalTriggerServerEvent = TriggerServerEvent
    
    -- Monitor all server events
    AddEventHandler('__cfx_internal:commandFallback', function()
        local playerId = source
        local eventName = GetInvokingResource()
        
        if not playerId or playerId <= 0 then return end
        
        -- Check if event should be blocked
        if isBlockedClientEvent(eventName) then
            if not blockedEvents[playerId] then
                blockedEvents[playerId] = 0
            end
            
            blockedEvents[playerId] = blockedEvents[playerId] + 1
            
            logger.warn(string.format("[AntiEventFlood] Player %s attempted blocked event: %s", 
                GetPlayerName(playerId), eventName))
            
            if blockedEvents[playerId] >= BLOCKED_EVENT_THRESHOLD then
                ban_manager.ban_player(playerId, "Event Manipulation", 
                    string.format("Attempted %d blocked events (Last: %s)", 
                    blockedEvents[playerId], eventName))
            end
            
            CancelEvent()
            return
        end
    end)
    
    -- Create event flood monitor
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(100) -- Check every 100ms
            
            for playerId, eventCounts in pairs(playerEventCounts) do
                if GetPlayerPing(playerId) > 0 then
                    for eventName, count in pairs(eventCounts) do
                        local isFlooding, eventCount, floodType = checkEventFlood(playerId, eventName)
                        
                        if isFlooding then
                            if floodType == "event_specific" then
                                logger.warn(string.format("[AntiEventFlood] Player %s flooding event '%s': %d calls/sec", 
                                    GetPlayerName(playerId), eventName, eventCount))
                                
                                ban_manager.ban_player(playerId, "Event Flood", 
                                    string.format("Event flooding: '%s' - %d calls/sec", eventName, eventCount))
                            elseif floodType == "total_flood" then
                                logger.warn(string.format("[AntiEventFlood] Player %s total event flood: %d events/sec", 
                                    GetPlayerName(playerId), eventCount))
                                
                                ban_manager.ban_player(playerId, "Event Flood", 
                                    string.format("Total event flooding: %d events/sec", eventCount))
                            end
                            
                            -- Clear this player's data after ban
                            playerEventCounts[playerId] = nil
                            playerEventTimestamps[playerId] = nil
                            break
                        end
                    end
                else
                    -- Clean up disconnected player
                    playerEventCounts[playerId] = nil
                    playerEventTimestamps[playerId] = nil
                end
            end
        end
    end)
    
    -- Register handler for monitored events
    for _, eventName in ipairs(MONITORED_EVENTS) do
        RegisterNetEvent(eventName, function(...)
            local playerId = source
            if not playerId or playerId <= 0 then return end
            
            -- Track this event
            if not playerEventCounts[playerId] then
                playerEventCounts[playerId] = {}
            end
            
            if not playerEventCounts[playerId][eventName] then
                playerEventCounts[playerId][eventName] = 0
            end
            
            playerEventCounts[playerId][eventName] = playerEventCounts[playerId][eventName] + 1
            
            logger.debug(string.format("[AntiEventFlood] Player %s triggered monitored event: %s", 
                GetPlayerName(playerId), eventName))
        end)
    end
    
    -- Cleanup on player disconnect
    AddEventHandler('playerDropped', function()
        local playerId = source
        playerEventCounts[playerId] = nil
        playerEventTimestamps[playerId] = nil
        blockedEvents[playerId] = nil
    end)
    
    -- Periodic cleanup
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) -- Every minute
            
            -- Reset blocked event counters
            for playerId, count in pairs(blockedEvents) do
                if GetPlayerPing(playerId) <= 0 then
                    blockedEvents[playerId] = nil
                else
                    blockedEvents[playerId] = math.max(0, count - 1)
                end
            end
        end
    end)
    
    logger.info("[AntiEventFlood] Protection initialized - Max events/sec: " .. MAX_EVENTS_PER_SECOND)
end

return AntiEventFlood
