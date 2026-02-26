local Utils = require("shared/lib/utils")
local logger = require("server/core/logger")
local ban_manager = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

---@class HeartbeatModule
local Heartbeat = {
    playerHeartbeats = {},
    alive = {},
    allowedStop = {},
    failureCount = {},
    playerJoinTime = {},
    checkInterval = 3000,
    maxFailures = 7,
    heartbeatCheckInterval = 5000,
    timeoutThreshold = 10,
    gracePeriod = 15
}

local function normalize_player_id(player_id)
    local numeric = tonumber(player_id)
    if not numeric or numeric <= 0 then
        return nil
    end
    return numeric
end

local function get_positive_number(value, default_value)
    local numeric = tonumber(value)
    if numeric and numeric > 0 then
        return numeric
    end
    return default_value
end

---@description Initialize heartbeat protection
function Heartbeat.initialize()
    logger.info("Initializing Heartbeat protection module")

    local config = SecureServe.Module and SecureServe.Module.Heartbeat or {}
    
    Heartbeat.checkInterval = get_positive_number(config.CheckInterval, 3000)
    Heartbeat.maxFailures = math.floor(get_positive_number(config.MaxFailures, 7))
    Heartbeat.heartbeatCheckInterval = get_positive_number(config.HeartbeatCheckInterval, 5000)
    Heartbeat.timeoutThreshold = get_positive_number(config.TimeoutThreshold, 10)
    Heartbeat.gracePeriod = get_positive_number(config.GracePeriod, 15)

    Heartbeat.playerHeartbeats = {}
    Heartbeat.alive = {}
    Heartbeat.allowedStop = {}
    Heartbeat.failureCount = {}
    Heartbeat.playerJoinTime = {}

    Heartbeat.setupEventHandlers()

    Heartbeat.startMonitoringThreads()

    logger.info("Heartbeat protection module initialized")
end

---@description Set up event handlers for heartbeat system
function Heartbeat.setupEventHandlers()
    AddEventHandler("playerDropped", function()
        local playerId = normalize_player_id(source)
        if not playerId then return end

        Heartbeat.playerHeartbeats[playerId] = nil
        Heartbeat.alive[playerId] = nil
        Heartbeat.allowedStop[playerId] = nil
        Heartbeat.failureCount[playerId] = nil
        Heartbeat.playerJoinTime[playerId] = nil
    end)

    RegisterNetEvent("mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS", function(key)
        local numPlayerId = normalize_player_id(source)
        if not numPlayerId then return end

        if type(key) ~= "string" or string.len(key) < 15 or string.len(key) > 35 then
            DropPlayer(numPlayerId, "Invalid heartbeat key")
        else
            Heartbeat.playerHeartbeats[numPlayerId] = os.time()
            if not Heartbeat.playerJoinTime[numPlayerId] then
                Heartbeat.playerJoinTime[numPlayerId] = os.time()
            end
        end
    end)

    RegisterNetEvent('addalive', function()
        local playerId = normalize_player_id(source)
        if not playerId then return end
        Heartbeat.alive[playerId] = true
    end)

    RegisterNetEvent('allowedStop', function()
        local playerId = normalize_player_id(source)
        if not playerId then return end
        Heartbeat.allowedStop[playerId] = true
    end)

    RegisterNetEvent('playerLoaded', function()
        local numPlayerId = normalize_player_id(source)
        if numPlayerId then
            Heartbeat.playerHeartbeats[numPlayerId] = os.time()
            if not Heartbeat.playerJoinTime[numPlayerId] then
                Heartbeat.playerJoinTime[numPlayerId] = os.time()
            end
        end
    end)

    RegisterNetEvent('playerSpawneda', function()
        local playerId = normalize_player_id(source)
        if not playerId then return end
        Heartbeat.allowedStop[playerId] = true
    end)
end

---@description Start the monitoring threads for heartbeat checks
function Heartbeat.startMonitoringThreads()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Heartbeat.heartbeatCheckInterval)

            local currentTime = os.time()
            local players = GetPlayers()

            for _, playerId in ipairs(players) do
                local numPlayerId = normalize_player_id(playerId)
                if not numPlayerId then
                    goto continue
                end
                
                local lastHeartbeatTime = Heartbeat.playerHeartbeats[numPlayerId]
                
                if not lastHeartbeatTime then
                    if not Heartbeat.playerJoinTime[numPlayerId] then
                        Heartbeat.playerJoinTime[numPlayerId] = currentTime
                        goto continue
                    end

                    local timeSinceJoinWithoutHeartbeat = currentTime - Heartbeat.playerJoinTime[numPlayerId]
                    if timeSinceJoinWithoutHeartbeat > (Heartbeat.gracePeriod + Heartbeat.timeoutThreshold) then
                        Heartbeat.banPlayer(numPlayerId, "No initial heartbeat received")
                        Heartbeat.playerHeartbeats[numPlayerId] = nil
                    end
                    goto continue
                end
                
                if not Heartbeat.playerJoinTime[numPlayerId] then
                    Heartbeat.playerJoinTime[numPlayerId] = currentTime
                end
                
                local joinTime = Heartbeat.playerJoinTime[numPlayerId]
                local timeSinceJoin = currentTime - joinTime
                
                if timeSinceJoin < Heartbeat.gracePeriod then
                    goto continue
                end
                
                local timeSinceLastHeartbeat = currentTime - lastHeartbeatTime
                if timeSinceLastHeartbeat > Heartbeat.timeoutThreshold then
                    Heartbeat.banPlayer(numPlayerId, "No heartbeat received")
                    Heartbeat.playerHeartbeats[numPlayerId] = nil
                end
                
                ::continue::
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            local players = GetPlayers()

            for _, playerId in ipairs(players) do
                local numPlayerId = normalize_player_id(playerId)
                if numPlayerId then
                    Heartbeat.alive[numPlayerId] = false
                    TriggerClientEvent('checkalive', numPlayerId)
                end
            end

            Citizen.Wait(Heartbeat.checkInterval)

            for _, playerId in ipairs(players) do
                local numPlayerId = normalize_player_id(playerId)
                if not numPlayerId then
                    goto continue
                end

                if not Heartbeat.alive[numPlayerId] and Heartbeat.allowedStop[numPlayerId] then
                    Heartbeat.failureCount[numPlayerId] = (Heartbeat.failureCount[numPlayerId] or 0) + 1

                    if Heartbeat.failureCount[numPlayerId] >= Heartbeat.maxFailures then
                        DropPlayer(numPlayerId, "Failed to respond to alive checks")
                    end
                else
                    Heartbeat.failureCount[numPlayerId] = 0
                end

                ::continue::
            end
        end
    end)
end

---@description Ban a player for heartbeat violation
---@param playerId number The player ID to ban
---@param reason string The specific reason for the ban
function Heartbeat.banPlayer(playerId, reason)
    logger.warn("Heartbeat violation detected for player " .. playerId .. ": " .. reason)

    local config = config_manager.get_config()
    local shouldBan = true
    
    if config and config.Module and config.Module.Heartbeat then
        shouldBan = config.Module.Heartbeat.BanOnViolation ~= false
    end

    if shouldBan and ban_manager then
        ban_manager.ban_player(playerId, 'Anticheat violation detected: ' .. reason, {
            admin = "Heartbeat System",
            time = 2147483647,
            detection = "Heartbeat System - " .. reason
        })
    else
        DropPlayer(playerId, 'Anticheat violation detected: ' .. reason)
        if not shouldBan then
            logger.info("Heartbeat violation: Player dropped (banning disabled in config)")
        else
            logger.error("Ban manager not available, player was only dropped")
        end
    end
end

return Heartbeat
