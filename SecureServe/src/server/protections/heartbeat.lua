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
    pendingBan              = {},
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
        Heartbeat.pendingBan[pid]       = nil
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

    RegisterNetEvent('SecureServe:Heartbeat:AddAlive', function()
        local pid = tonumber(source)
        if pid then Heartbeat.alive[pid] = true end
    end)

    RegisterNetEvent('SecureServe:Heartbeat:AllowedStop', function()
        local pid = tonumber(source)
        if pid then Heartbeat.allowedStop[pid] = true end
    end)

    RegisterNetEvent('SecureServe:Heartbeat:Loaded', function()
        local pid = tonumber(source)
        if not pid then return end
        Heartbeat.playerHeartbeats[pid] = os.time()
        Heartbeat.silentStrikes[pid]    = 0
        if not Heartbeat.playerJoinTime[pid] then
            Heartbeat.playerJoinTime[pid] = os.time()
        end
    end)

    RegisterNetEvent('SecureServe:Heartbeat:Spawned', function()
        local pid = tonumber(source)
        if pid then Heartbeat.allowedStop[pid] = true end
    end)
end

function Heartbeat.startMonitoringThreads()
    -- Thread 1: "No heartbeat received" — el cliente dejo de mandar el tick
    -- periodico (mMkH...). Esto detecta a quien NO ejecuta el AC.
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Heartbeat.heartbeatCheckInterval)
            local now = os.time()

            for _, playerId in ipairs(GetPlayers()) do
                local pid = tonumber(playerId)
                -- Re-verificar que el jugador sigue conectado AHORA (no en una
                -- lista cacheada) y que no esta ya pendiente de ban.
                if pid and not Heartbeat.pendingBan[pid] and GetPlayerName(pid) then
                    local last = Heartbeat.playerHeartbeats[pid]

                    if not Heartbeat.playerJoinTime[pid] then
                        Heartbeat.playerJoinTime[pid] = now
                    end

                    -- Ignorar conexiones moribundas: si el ultimo mensaje de red
                    -- del jugador es viejo, es lag/desconexion, NO cheating.
                    local lastMsg = 999999
                    if GetPlayerLastMsg then lastMsg = GetPlayerLastMsg(pid) or 999999 end

                    local timeSinceJoin = now - Heartbeat.playerJoinTime[pid]
                    if timeSinceJoin >= Heartbeat.gracePeriod
                        and last
                        and (now - last) > Heartbeat.timeoutThreshold
                        and lastMsg < 10000  -- la conexion sigue VIVA (no es lag)
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

    -- Thread 2: "alive check" — round-trip server->cliente->server.
    -- Se reescribe para eliminar la race condition: la lista de jugadores se
    -- relee en CADA pasada, y antes de penalizar se comprueba que el jugador
    -- sigue conectado y que su conexion esta viva (no es lag).
    Citizen.CreateThread(function()
        while true do
            -- Pasada de envio: marcar alive=false y pedir confirmacion.
            for _, playerId in ipairs(GetPlayers()) do
                local pid = tonumber(playerId)
                if pid and not Heartbeat.pendingBan[pid] then
                    Heartbeat.alive[pid] = false
                    TriggerClientEvent('SecureServe:Heartbeat:Check', pid)
                end
            end

            Citizen.Wait(Heartbeat.checkInterval)

            -- Pasada de evaluacion: releer jugadores (NO usar lista cacheada).
            for _, playerId in ipairs(GetPlayers()) do
                local pid = tonumber(playerId)
                if pid and not Heartbeat.pendingBan[pid]
                    and Heartbeat.allowedStop[pid]
                    and GetPlayerName(pid)  -- sigue conectado
                then
                    -- No penalizar a conexiones con lag/desconexion en curso.
                    local lastMsg = 999999
                    if GetPlayerLastMsg then lastMsg = GetPlayerLastMsg(pid) or 999999 end

                    if not Heartbeat.alive[pid] and lastMsg < 10000 then
                        Heartbeat.failureCount[pid] = (Heartbeat.failureCount[pid] or 0) + 1
                        if Heartbeat.failureCount[pid] >= Heartbeat.maxFailures then
                            Heartbeat.banPlayer(pid, "Failed alive checks")
                            Heartbeat.failureCount[pid] = 0
                        end
                    else
                        -- Respondio, o esta laggeando: resetear contador.
                        Heartbeat.failureCount[pid] = 0
                    end
                end
            end
        end
    end)
end

function Heartbeat.banPlayer(playerId, reason)
    if Heartbeat.pendingBan[playerId] then return end
    Heartbeat.pendingBan[playerId] = true

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
