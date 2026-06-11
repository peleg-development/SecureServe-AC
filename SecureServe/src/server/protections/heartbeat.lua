local logger         = require("server/core/logger")
local ban_manager    = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

local Heartbeat = {
    playerHeartbeats        = {},
    alive                   = {},
    allowedStop             = {},
    pendingReady            = {},
    failureCount            = {},
    silentStrikes           = {},
    playerJoinTime          = {},
    aliveNonce              = {},
    checkInterval           = 3000,
    maxFailures             = 7,
    heartbeatCheckInterval  = 5000,
    timeoutThreshold        = 30,
    gracePeriod             = 30,
    silenceStrikes          = 2,
    initialized             = false,
}

local function seconds()
    return os.time()
end

local function cleanup_player(pid)
    Heartbeat.playerHeartbeats[pid] = nil
    Heartbeat.alive[pid]            = nil
    Heartbeat.allowedStop[pid]      = nil
    Heartbeat.pendingReady[pid]     = nil
    Heartbeat.failureCount[pid]     = nil
    Heartbeat.silentStrikes[pid]    = nil
    Heartbeat.playerJoinTime[pid]   = nil
    Heartbeat.aliveNonce[pid]       = nil
end

-- Fix: unpredictable per-challenge nonce; a client must echo it back to prove it is alive (anti-spoof for "addalive").
local nonce_counter = 0
local function make_nonce()
    nonce_counter = nonce_counter + 1
    return string.format("%x-%x-%x", os.time(), nonce_counter, math.random(1, 0x7fffffff))
end

local function mark_joined(pid, at)
    if not pid then return end
    if not Heartbeat.playerJoinTime[pid] then
        Heartbeat.playerJoinTime[pid] = at or seconds()
    end
end

local function mark_ready(pid, at)
    if not pid then return end

    mark_joined(pid, at)
    Heartbeat.pendingReady[pid] = true

    if Heartbeat.playerHeartbeats[pid] then
        Heartbeat.allowedStop[pid] = true
        Heartbeat.pendingReady[pid] = nil
    end
end

local function mark_heartbeat(pid, at)
    if not pid then return end

    local now = at or seconds()
    mark_joined(pid, now)

    Heartbeat.playerHeartbeats[pid] = now
    Heartbeat.silentStrikes[pid] = 0

    if Heartbeat.pendingReady[pid] then
        Heartbeat.allowedStop[pid] = true
        Heartbeat.pendingReady[pid] = nil
    end
end

local function is_connected(pid)
    return pid and GetPlayerName(pid) ~= nil
end

local function is_ready_for_alive_check(pid, now)
    if not is_connected(pid) then return false end

    local joined_at = Heartbeat.playerJoinTime[pid]
    if not joined_at or (now - joined_at) < Heartbeat.gracePeriod then
        return false
    end

    -- Fix: fail-closed. Every connected player past the grace period is challenged. Before, requiring allowedStop+heartbeat let a client that never became "ready" (blocked/removed) escape the check entirely.
    return true
end

local function can_punish_now(playerId, reason)
    local min_seconds = tonumber(SecureServe and SecureServe.MinimumOnlineSecondsBeforeBan) or 0
    if min_seconds <= 0 then return true end

    local joined_at = Heartbeat.playerJoinTime[playerId]
        or (_G.SecureServe_PlayerJoinedAt and _G.SecureServe_PlayerJoinedAt[playerId])

    if not joined_at then return true end

    local online_seconds = seconds() - joined_at
    if online_seconds >= min_seconds then return true end

    logger.warn(("Heartbeat punish ignored for %s; online %ds below %ds: %s")
        :format(tostring(playerId), online_seconds, min_seconds, tostring(reason)))
    return false
end

local function load_config()
    local config = (SecureServe and SecureServe.Module and SecureServe.Module.Heartbeat) or {}

    Heartbeat.checkInterval          = tonumber(config.CheckInterval)          or 3000
    Heartbeat.maxFailures            = tonumber(config.MaxFailures)            or 7
    Heartbeat.heartbeatCheckInterval = tonumber(config.HeartbeatCheckInterval) or 5000
    Heartbeat.timeoutThreshold       = tonumber(config.TimeoutThreshold)       or 30
    Heartbeat.gracePeriod            = tonumber(config.GracePeriod)            or 30
    Heartbeat.silenceStrikes         = tonumber(config.SilenceStrikes)         or 2
end

function Heartbeat.initialize()
    if Heartbeat.initialized then return end
    Heartbeat.initialized = true

    logger.info("Initializing Heartbeat protection module")

    load_config()
    Heartbeat.setupEventHandlers()
    Heartbeat.startMonitoringThreads()

    logger.info("Heartbeat protection module initialized")
end

function Heartbeat.setupEventHandlers()
    AddEventHandler("playerJoining", function()
        mark_joined(tonumber(source), seconds())
    end)

    AddEventHandler("playerDropped", function()
        local pid = tonumber(source)
        if pid then cleanup_player(pid) end
    end)

    RegisterNetEvent("mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS", function(key)
        local pid = tonumber(source)
        if not pid then return end

        if type(key) ~= "string" or #key < 15 or #key > 35 then
            DropPlayer(tostring(pid), "Invalid heartbeat key")
            return
        end

        mark_heartbeat(pid, seconds())
    end)

    RegisterNetEvent("addalive", function(nonce)
        local pid = tonumber(source)
        if not pid then return end

        -- Fix: we only accept the alive proof if the nonce matches the current challenge; otherwise a client could spam "addalive" to declare itself alive without running.
        local expected = Heartbeat.aliveNonce[pid]
        if not expected or nonce ~= expected then return end

        Heartbeat.aliveNonce[pid] = nil
        Heartbeat.alive[pid] = true
        Heartbeat.failureCount[pid] = 0
    end)

    RegisterNetEvent("allowedStop", function()
        mark_ready(tonumber(source), seconds())
    end)

    RegisterNetEvent("playerLoaded", function()
        local pid = tonumber(source)
        if not pid then return end

        mark_heartbeat(pid, seconds())
        Heartbeat.allowedStop[pid] = true
        Heartbeat.pendingReady[pid] = nil
    end)

    RegisterNetEvent("playerSpawneda", function()
        mark_ready(tonumber(source), seconds())
    end)
end

function Heartbeat.startMonitoringThreads()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Heartbeat.heartbeatCheckInterval)
            local now = seconds()

            for _, playerId in ipairs(GetPlayers()) do
                local pid = tonumber(playerId)
                if pid then
                    mark_joined(pid, now)

                    local last = Heartbeat.playerHeartbeats[pid]
                    local timeSinceJoin = now - Heartbeat.playerJoinTime[pid]

                    if last and timeSinceJoin >= Heartbeat.gracePeriod
                        and (now - last) > Heartbeat.timeoutThreshold
                    then
                        Heartbeat.silentStrikes[pid] = (Heartbeat.silentStrikes[pid] or 0) + 1
                        if Heartbeat.silentStrikes[pid] >= Heartbeat.silenceStrikes then
                            Heartbeat.banPlayer(pid, "No heartbeat received")
                            Heartbeat.playerHeartbeats[pid] = nil
                            Heartbeat.silentStrikes[pid] = 0
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
            local now = seconds()
            local challenged = {}

            for _, playerId in ipairs(GetPlayers()) do
                local pid = tonumber(playerId)
                if pid and is_ready_for_alive_check(pid, now) then
                    Heartbeat.alive[pid] = false
                    -- Fix: we emit a unique nonce per challenge; only a running client can echo it back.
                    local nonce = make_nonce()
                    Heartbeat.aliveNonce[pid] = nonce
                    challenged[#challenged + 1] = pid
                    TriggerClientEvent("checkalive", pid, nonce)
                end
            end

            Citizen.Wait(Heartbeat.checkInterval)

            local checked_at = seconds()
            for _, pid in ipairs(challenged) do
                if is_ready_for_alive_check(pid, checked_at) then
                    if not Heartbeat.alive[pid] then
                        Heartbeat.aliveNonce[pid] = nil
                        Heartbeat.failureCount[pid] = (Heartbeat.failureCount[pid] or 0) + 1

                        -- Fix: we no longer rely on heartbeat freshness (spoofable); repeated nonce-challenge failures are the reliable proof that no SecureServe client is running.
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
    if not can_punish_now(playerId, reason) then return end

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
