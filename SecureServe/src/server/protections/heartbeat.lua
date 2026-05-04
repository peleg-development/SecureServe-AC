local Utils          = require("shared/lib/utils")
local logger         = require("server/core/logger")
local ban_manager    = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

local Heartbeat = {
    playerHeartbeats        = {},
    alive                   = {},
    allowedStop             = {},
    failureCount            = {},
    silentStrikes           = {},
    playerJoinTime          = {},
    checkInterval           = 3000,
    maxFailures             = 7,
    heartbeatCheckInterval  = 5000,
    timeoutThreshold        = 30,
    gracePeriod             = 30,
    silenceStrikes          = 2,
}

function Heartbeat.initialize()
    logger.info("Initializing Heartbeat protection module")

    local config = (SecureServe and SecureServe.Module and SecureServe.Module.Heartbeat) or {}

    Heartbeat.checkInterval          = config.CheckInterval          or 3000
    Heartbeat.maxFailures            = config.MaxFailures            or 7
    Heartbeat.heartbeatCheckInterval = config.HeartbeatCheckInterval or 5000
    Heartbeat.timeoutThreshold       = config.TimeoutThreshold       or 30
    Heartbeat.gracePeriod            = config.GracePeriod            or 30
    Heartbeat.silenceStrikes         = config.SilenceStrikes         or 2

    Heartbeat.setupEventHandlers()
    Heartbeat.startMonitoringThreads()

    logger.info("Heartbeat protection module initialized")
end

function Heartbeat.setupEventHandlers()
    AddEventHandler("playerDropped", function()
        local pid = tonumber(source)
        if not pid then return end
        Heartbeat.playerHeartbeats[pid] = nil
        Heartbeat.alive[pid]            = nil
        Heartbeat.allowedStop[pid]      = nil
        Heartbeat.failureCount[pid]     = nil
        Heartbeat.silentStrikes[pid]    = nil
        Heartbeat.playerJoinTime[pid]   = nil
    end)

    RegisterNetEvent("mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS", function(key)
        local pid = tonumber(source)
        if not pid then return end

        if type(key) ~= "string" or #key < 15 or #key > 35 then
            DropPlayer(tostring(pid), "Invalid heartbeat key")
            return
        end

        Heartbeat.playerHeartbeats[pid] = os.time()
        Heartbeat.silentStrikes[pid]    = 0
        if not Heartbeat.playerJoinTime[pid] then
            Heartbeat.playerJoinTime[pid] = os.time()
        end
    end)

    RegisterNetEvent('addalive', function()
        local pid = tonumber(source)
        if pid then Heartbeat.alive[pid] = true end
    end)

    RegisterNetEvent('allowedStop', function()
        local pid = tonumber(source)
        if pid then Heartbeat.allowedStop[pid] = true end
    end)

    RegisterNetEvent('playerLoaded', function()
        local pid = tonumber(source)
        if not pid then return end
        Heartbeat.playerHeartbeats[pid] = os.time()
        Heartbeat.silentStrikes[pid]    = 0
        if not Heartbeat.playerJoinTime[pid] then
            Heartbeat.playerJoinTime[pid] = os.time()
        end
    end)

    RegisterNetEvent('playerSpawneda', function()
        local pid = tonumber(source)
        if pid then Heartbeat.allowedStop[pid] = true end
    end)
end

function Heartbeat.startMonitoringThreads()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Heartbeat.heartbeatCheckInterval)
            local now = os.time()

            for _, playerId in ipairs(GetPlayers()) do
                local pid = tonumber(playerId)
                if pid then
                    local last = Heartbeat.playerHeartbeats[pid]

                    if not Heartbeat.playerJoinTime[pid] then
                        Heartbeat.playerJoinTime[pid] = now
                    end

                    local timeSinceJoin = now - Heartbeat.playerJoinTime[pid]
                    if timeSinceJoin >= Heartbeat.gracePeriod and last
                        and (now - last) > Heartbeat.timeoutThreshold
                    then
                        Heartbeat.silentStrikes[pid] = (Heartbeat.silentStrikes[pid] or 0) + 1
                        if Heartbeat.silentStrikes[pid] >= Heartbeat.silenceStrikes then
                            Heartbeat.banPlayer(pid, "No heartbeat received")
                            Heartbeat.playerHeartbeats[pid] = nil
                            Heartbeat.silentStrikes[pid]    = 0
                        end
                    else
                        Heartbeat.silentStrikes[pid] = 0
                    end
                end
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            local players = GetPlayers()

            for _, playerId in ipairs(players) do
                local pid = tonumber(playerId)
                if pid then
                    Heartbeat.alive[pid] = false
                    TriggerClientEvent('checkalive', pid)
                end
            end

            Citizen.Wait(Heartbeat.checkInterval)

            for _, playerId in ipairs(players) do
                local pid = tonumber(playerId)
                if pid and Heartbeat.allowedStop[pid] then
                    if not Heartbeat.alive[pid] then
                        Heartbeat.failureCount[pid] = (Heartbeat.failureCount[pid] or 0) + 1
                        if Heartbeat.failureCount[pid] >= Heartbeat.maxFailures then
                            Heartbeat.banPlayer(pid, "Failed alive checks")
                            Heartbeat.failureCount[pid] = 0
                        end
                    else
                        Heartbeat.failureCount[pid] = 0
                    end
                end
            end
        end
    end)
end

function Heartbeat.banPlayer(playerId, reason)
    logger.warn("Heartbeat violation for player " .. tostring(playerId) .. ": " .. reason)

    local cfg = config_manager.get_config()
    local shouldBan = true
    if cfg and cfg.Module and cfg.Module.Heartbeat then
        shouldBan = cfg.Module.Heartbeat.BanOnViolation ~= false
    end

    if shouldBan and ban_manager then
        ban_manager.ban_player(playerId, "Anticheat violation: " .. reason, {
            admin     = "Heartbeat System",
            time      = 2147483647,
            detection = "Heartbeat - " .. reason,
        })
    else
        DropPlayer(tostring(playerId), "Anticheat violation: " .. reason)
    end
end

return Heartbeat
