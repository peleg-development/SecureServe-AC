local Utils = require("shared/lib/utils")
local logger = require("server/core/logger")
local ban_manager = require("server/core/ban_manager")

---@class HeartbeatModule
local Heartbeat = {
    playerHeartbeats = {},
    alive = {},
    allowedStop = {},
    failureCount = {},
    checkInterval = 5000,
    maxFailures = 50
}

---@description Initialize heartbeat protection
function Heartbeat.initialize()
    logger.info("Initializing Heartbeat protection module")
    
    Heartbeat.playerHeartbeats = {}
    Heartbeat.alive = {}
    Heartbeat.allowedStop = {}
    Heartbeat.failureCount = {}
    
    Heartbeat.setupEventHandlers()
    
    Heartbeat.startMonitoringThreads()
    
    logger.info("Heartbeat protection module initialized")
end

---@description Set up event handlers for heartbeat system
function Heartbeat.setupEventHandlers()
    AddEventHandler("playerDropped", function()
        local playerId = source
        Heartbeat.playerHeartbeats[playerId] = nil
        Heartbeat.alive[playerId] = nil
        Heartbeat.allowedStop[playerId] = nil
        Heartbeat.failureCount[playerId] = nil
    end)
    
    RegisterNetEvent("mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS", function(key)
        local playerId = source
        
        if string.len(key) < 15 or string.len(key) > 35 or key == nil then
            Heartbeat.banPlayer(playerId, "Invalid heartbeat key")
        else
            Heartbeat.playerHeartbeats[playerId] = os.time()
        end
    end)
    
    RegisterNetEvent('addalive', function()
        local playerId = source
        Heartbeat.alive[tonumber(playerId)] = true
    end)
    
    RegisterNetEvent('allowedStop', function()
        local playerId = source
        Heartbeat.allowedStop[playerId] = true
    end)
    
    RegisterNetEvent('playerLoaded', function()
        local playerId = source
        Heartbeat.playerHeartbeats[playerId] = os.time()
    end)
    
    RegisterNetEvent('playerSpawneda', function()
        local playerId = source
        Heartbeat.allowedStop[playerId] = true
    end)
end

---@description Start the monitoring threads for heartbeat checks
function Heartbeat.startMonitoringThreads()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10 * 1000)
            
            local currentTime = os.time()
            
            for playerId, lastHeartbeatTime in pairs(Heartbeat.playerHeartbeats) do
                if lastHeartbeatTime ~= nil then
                    local timeSinceLastHeartbeat = currentTime - lastHeartbeatTime
                    
                    if timeSinceLastHeartbeat > 1500 then
                        Heartbeat.banPlayer(playerId, "No heartbeat received")
                        Heartbeat.playerHeartbeats[playerId] = nil
                    end
                end
            end
        end
    end)
    
    Citizen.CreateThread(function()
        while true do
            local players = GetPlayers()
            
            for _, playerId in ipairs(players) do
                Heartbeat.alive[tonumber(playerId)] = false
                TriggerClientEvent('checkalive', tonumber(playerId))
            end
            
            Citizen.Wait(Heartbeat.checkInterval)
            
            for _, playerId in ipairs(players) do
                local numPlayerId = tonumber(playerId)
                
                if not Heartbeat.alive[numPlayerId] and Heartbeat.allowedStop[numPlayerId] then
                    Heartbeat.failureCount[numPlayerId] = (Heartbeat.failureCount[numPlayerId] or 0) + 1
                    
                    if Heartbeat.failureCount[numPlayerId] >= Heartbeat.maxFailures then
                        Heartbeat.banPlayer(numPlayerId, "Failed to respond to alive checks")
                    end
                else
                    Heartbeat.failureCount[numPlayerId] = 0
                end
            end
        end
    end)
end

---@description Ban a player for heartbeat violation
---@param playerId number The player ID to ban
---@param reason string The specific reason for the ban
function Heartbeat.banPlayer(playerId, reason)
    logger.warn("Heartbeat violation detected for player " .. playerId .. ": " .. reason)
    
    if ban_manager then
        ban_manager.ban_player(playerId, 'Anticheat violation detected: ' .. reason, {
            admin = "Heartbeat System",
            time = 2147483647,
            detection = "Heartbeat System - " .. reason
        })
    else
        DropPlayer(playerId, 'Anticheat violation detected')
        logger.error("Ban manager not available, player was only dropped")
    end
end


return Heartbeat