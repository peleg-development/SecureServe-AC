---@class AntiPedSpamModule
local AntiPedSpam = {}

local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")

local playerPedCounts = {}
local playerPedTimestamps = {}

-- Configuration
local MAX_PEDS_PER_PLAYER = 15        -- Maximum peds per player
local TIME_WINDOW = 60000              -- Time window in ms (1 minute)
local RAPID_SPAWN_THRESHOLD = 5        -- Peds spawned in short time
local RAPID_SPAWN_TIME = 5000          -- Time window for rapid spawn check (5 seconds)

---@description Check if player is spawning peds too rapidly
local function checkRapidSpawn(playerId)
    if not playerPedTimestamps[playerId] then
        playerPedTimestamps[playerId] = {}
    end
    
    local currentTime = os.time() * 1000
    local timestamps = playerPedTimestamps[playerId]
    
    -- Add current timestamp
    table.insert(timestamps, currentTime)
    
    -- Remove old timestamps outside the rapid spawn window
    for i = #timestamps, 1, -1 do
        if currentTime - timestamps[i] > RAPID_SPAWN_TIME then
            table.remove(timestamps, i)
        end
    end
    
    -- Check if too many peds spawned rapidly
    if #timestamps >= RAPID_SPAWN_THRESHOLD then
        return true, #timestamps
    end
    
    return false, #timestamps
end

---@description Initialize anti-ped spam protection
function AntiPedSpam.initialize()
    -- Track ped creation
    AddEventHandler('entityCreated', function(entity)
        if not DoesEntityExist(entity) then return end
        
        local entityType = GetEntityType(entity)
        if entityType ~= 1 then return end -- Not a ped
        
        local owner = NetworkGetFirstEntityOwner(entity)
        if not owner or owner == 0 or owner == -1 then return end
        
        -- Initialize counter for player
        if not playerPedCounts[owner] then
            playerPedCounts[owner] = 0
        end
        
        playerPedCounts[owner] = playerPedCounts[owner] + 1
        
        -- Check for rapid spawning
        local isRapidSpawn, spawnCount = checkRapidSpawn(owner)
        if isRapidSpawn then
            logger.warn(string.format("[AntiPedSpam] Player %s spawned %d peds in %d seconds", 
                GetPlayerName(owner), spawnCount, RAPID_SPAWN_TIME / 1000))
            
            DeleteEntity(entity)
            ban_manager.ban_player(owner, "Ped Spam", 
                string.format("Rapid ped spawning detected: %d peds in %d seconds", 
                spawnCount, RAPID_SPAWN_TIME / 1000))
            return
        end
        
        -- Check total ped count
        if playerPedCounts[owner] > MAX_PEDS_PER_PLAYER then
            logger.warn(string.format("[AntiPedSpam] Player %s exceeded ped limit: %d/%d", 
                GetPlayerName(owner), playerPedCounts[owner], MAX_PEDS_PER_PLAYER))
            
            DeleteEntity(entity)
            
            -- Delete all peds owned by this player
            local allEntities = GetAllPeds()
            local deletedCount = 0
            for _, pedEntity in ipairs(allEntities) do
                if DoesEntityExist(pedEntity) then
                    local pedOwner = NetworkGetFirstEntityOwner(pedEntity)
                    if pedOwner == owner then
                        DeleteEntity(pedEntity)
                        deletedCount = deletedCount + 1
                    end
                end
            end
            
            logger.info(string.format("[AntiPedSpam] Deleted %d peds from player %s", 
                deletedCount, GetPlayerName(owner)))
            
            ban_manager.ban_player(owner, "Ped Spam", 
                string.format("Exceeded ped limit: %d/%d", playerPedCounts[owner], MAX_PEDS_PER_PLAYER))
            
            playerPedCounts[owner] = 0
        end
    end)
    
    -- Track ped deletion
    AddEventHandler('entityRemoved', function(entity)
        if not DoesEntityExist(entity) then return end
        
        local entityType = GetEntityType(entity)
        if entityType ~= 1 then return end
        
        local owner = NetworkGetFirstEntityOwner(entity)
        if owner and playerPedCounts[owner] then
            playerPedCounts[owner] = math.max(0, playerPedCounts[owner] - 1)
        end
    end)
    
    -- Cleanup on player disconnect
    AddEventHandler('playerDropped', function()
        local playerId = source
        playerPedCounts[playerId] = nil
        playerPedTimestamps[playerId] = nil
        
        -- Clean up all peds owned by disconnected player
        local allEntities = GetAllPeds()
        for _, entity in ipairs(allEntities) do
            if DoesEntityExist(entity) then
                local owner = NetworkGetFirstEntityOwner(entity)
                if owner == playerId then
                    DeleteEntity(entity)
                end
            end
        end
    end)
    
    -- Periodic cleanup and reset
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(TIME_WINDOW)
            
            -- Reset timestamps periodically
            for playerId, _ in pairs(playerPedTimestamps) do
                playerPedTimestamps[playerId] = {}
            end
            
            -- Verify ped counts
            for playerId, count in pairs(playerPedCounts) do
                if GetPlayerPing(playerId) <= 0 then
                    playerPedCounts[playerId] = nil
                    playerPedTimestamps[playerId] = nil
                end
            end
        end
    end)
    
    logger.info("[AntiPedSpam] Protection initialized - Max peds per player: " .. MAX_PEDS_PER_PLAYER)
end

return AntiPedSpam
