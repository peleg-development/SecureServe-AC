local BanManager = require("server/core/ban_manager")
local logger     = require("server/core/logger")

local statsPath  = "stats.json"
local startTime  = os.time()
local statsCache = {}

local function valid_target(target_id)
    local n = tonumber(target_id)
    if not n or n <= 0 then return nil end
    if not GetPlayerName(n) then return nil end
    return n
end

local function require_admin(src)
    if not IsMenuAdmin(src) then
        logger.warn(("Unauthorized panel action by %s (id %s)"):format(GetPlayerName(src) or "?", tostring(src)))
        return false
    end
    return true
end


local SENSITIVE_OPTIONS = {
    ["ESP"] = true,
    ["Player Names"] = true,
    ["God Mode"] = true,
    ["No Clip"] = true,
    ["Invisibility"] = true,
    ["Bones"] = true,
}

local function has_admin_bypass(src)
    if not BanManager then return false end
    local cfg = SecureServe or {}
    local admins = cfg.Admins or {}
    local identifiers = GetPlayerIdentifiers(src) or {}
    for _, id in ipairs(identifiers) do
        for _, admin in ipairs(admins) do
            if id == admin.identifier and (admin.permission == "all" or admin.permission == "panel_options") then
                return true
            end
        end
    end
    return false
end

-- //[Toggle / notify]\\ --
RegisterNetEvent('anticheat:toggleOption', function(option, enabled)
    local src = source
    if not require_admin(src) then return end
    if type(option) ~= "string" then return end

    if SENSITIVE_OPTIONS[option] and not has_admin_bypass(src) then
        TriggerClientEvent('anticheat:notify', src, 'Permission denied for ' .. option)
        logger.warn(("Admin %s tried to toggle sensitive option '%s' without permission"):format(GetPlayerName(src) or "?", option))
        return
    end

    TriggerClientEvent('anticheat:notify', src, tostring(option) .. (enabled and " enabled" or " disabled"))
end)

RegisterNetEvent('anticheat:clearAllEntities', function()
    local src = source
    if not require_admin(src) then return end

    Citizen.CreateThread(function()
        for _, obj in ipairs(GetAllObjects()) do
            if DoesEntityExist(obj) then DeleteEntity(obj) end
        end
        Citizen.Wait(50)
        for _, ped in ipairs(GetAllPeds()) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        Citizen.Wait(50)
        for _, veh in ipairs(GetAllVehicles()) do
            if DoesEntityExist(veh) then DeleteEntity(veh) end
        end
    end)

    logger.info(("Admin %s cleared all entities"):format(GetPlayerName(src) or "?"))
end)


-- //[Unban]\\ --
RegisterNetEvent('SecureServe:Panel:Unban', function(banId)
    local src = source
    if not require_admin(src) then return end
    if not banId or banId == '' then
        TriggerClientEvent('anticheat:notify', src, 'Invalid ban ID provided')
        return
    end

    local ok = BanManager.unban_player(tostring(banId))
    if ok then
        logger.info(("Player unbanned (banId %s) by admin %s"):format(tostring(banId), GetPlayerName(src) or "?"))
        TriggerClientEvent('anticheat:notify', src, 'Player unbanned successfully')
    else
        TriggerClientEvent('anticheat:notify', src, 'Unban failed - ban not found')
    end
end)


-- //[Player list]\\ --
RegisterNetEvent('SecureServe:Panel:RequestPlayers', function(requestId)
    local src = source
    if not require_admin(src) then return end

    local list = {}
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid then
            list[#list + 1] = {
                id      = pid,
                name    = GetPlayerName(pid),
                steamId = GetPlayerIdentifiers(pid)[1],
                ping    = GetPlayerPing(pid) or 0,
            }
        end
    end
    TriggerClientEvent('SecureServe:Panel:ReceivePlayers', src, list, requestId)
end)


-- //[Kick]\\ --
RegisterNetEvent('SecureServe:Panel:Kick', function(targetId)
    local src = source
    if not require_admin(src) then return end
    local pid = valid_target(targetId)
    if not pid then
        TriggerClientEvent('anticheat:notify', src, 'Invalid player ID')
        return
    end
    DropPlayer(pid, "You have been kicked by an admin.")
    logger.info(("Player %s kicked by admin %s"):format(GetPlayerName(pid) or "?", GetPlayerName(src) or "?"))
end)


-- //[Ban]\\ --
RegisterNetEvent('SecureServe:Panel:Ban', function(targetId, payload)
    local src = source
    if not require_admin(src) then return end
    local pid = valid_target(targetId)
    if not pid then
        TriggerClientEvent('anticheat:notify', src, 'Invalid player ID')
        return
    end

    -- Payload opcional desde el NUI:
    --   payload.duration_minutes : numero o -1 (kick) o 0 (permanente, default)
    --   payload.reason           : string opcional
    local reason = "Manual ban"
    local time   = 0

    if type(payload) == "table" then
        if type(payload.reason) == "string" and payload.reason ~= "" then
            reason = payload.reason:sub(1, 200)
        end
        local d = tonumber(payload.duration_minutes)
        if d ~= nil then
            -- -1 = kick, 0 = permanente, >0 = minutos.
            time = d
        end
    end

    local details = { admin = GetPlayerName(src), time = time }

    -- Banear INMEDIATAMENTE. La captura va por su lado en background.
    -- Antes esto esperaba a la captura antes de banear, lo cual:
    --   * Si tu host filtra Discord o screenshot-basic tarda, el ban se
    --     retrasa 5-10s y el panel se queda colgado.
    --   * Genera un "pico" perceptible cada vez que un admin clica Ban.
    -- Ahora el ban es instantaneo y la captura se manda como mensaje aparte
    -- al webhook de screenshots si llega.
    BanManager.ban_player(pid, reason, details)

    if DiscordLogger and type(DiscordLogger.request_screenshot) == "function" then
        Citizen.CreateThread(function()
            DiscordLogger.request_screenshot(pid, "Ban: " .. reason, function(_image)
                -- log_screenshot ya se llama dentro de request_screenshot; nada
                -- mas que hacer aqui. Si la captura fallo, se queda sin imagen
                -- y punto. El ban ya esta aplicado.
            end)
        end)
    end
end)


-- //[Spectate]\\ --
-- El admin pide vigilar a un jugador. Como el objetivo puede estar lejos (fuera
-- del scope del admin), resolvemos sus coords pidiendoselas al cliente objetivo
-- (que es quien las conoce) y se las devolvemos al admin para que se acerque y
-- entre en modo espectador.
RegisterNetEvent('SecureServe:Panel:RequestSpectate', function(targetId)
    local src = source
    if not require_admin(src) then return end
    local pid = valid_target(targetId)
    if not pid then
        TriggerClientEvent('anticheat:notify', src, 'Invalid player ID')
        return
    end

    TriggerClientCallback({
        source    = pid,
        eventName = 'SecureServe:GetMyCoords',
        args      = {},
        timeout   = 10,
        timedout  = function()
            TriggerClientEvent('anticheat:notify', src, 'Could not locate that player')
        end,
        callback  = function(coords)
            if not coords or type(coords) ~= "table" then
                TriggerClientEvent('anticheat:notify', src, 'Could not locate that player')
                return
            end
            -- Devolver al admin las coords + el server id del objetivo.
            TriggerClientEvent('SecureServe:Panel:DoSpectate', src, pid, coords)
        end,
    })
end)


-- //[Screenshot]\\ --
RegisterNetEvent('SecureServe:screenshotPlayer', function(targetId)
    local src = source
    if not require_admin(src) then return end
    local pid = valid_target(targetId)
    if not pid then
        TriggerClientEvent('anticheat:notify', src, 'Invalid player ID')
        return
    end

    TriggerClientEvent('anticheat:notify', src, 'Requesting screenshot...')

    TriggerClientCallback({
        source    = pid,
        eventName = 'SecureServe:CaptureClientScreenshot',
        -- Calidad mas baja para que el data URI base64 no sea tan grande y
        -- pase bien por el sistema de callbacks de red.
        args      = { 'jpg', 0.6 },
        timeout   = 20,
        timedout  = function()
            TriggerClientEvent('anticheat:notify', src, 'Screenshot timed out (target may not have screenshot-basic running)')
        end,
        callback  = function(data)
            if not data or data == "" then
                TriggerClientEvent('anticheat:notify', src, 'Failed to take screenshot (is screenshot-basic running?)')
                return
            end
            TriggerClientEvent('SecureServe:Panel:DisplayScreenshot', src, data)
        end,
    })
end)


-- //[Ban list]\\ --
RegisterNetEvent('SecureServe:Panel:RequestBans', function(requestId)
    local src = source
    if not require_admin(src) then return end

    local bans = BanManager.get_all_bans() or {}
    local mapped = {}
    for _, ban in ipairs(bans) do
        local ids = ban.identifiers or {}
        local expires = tonumber(ban.expires or 0) or 0
        mapped[#mapped + 1] = {
            id      = tostring(ban.id or ""),
            name    = ban.player_name or "Unknown",
            reason  = ban.reason or ban.detection or "",
            steam   = ids.steam or "",
            discord = ids.discord or "",
            ip      = ids.ip or ids.endpoint or "",
            hwid1   = ids.fivem or ids.guid or "",
            expire  = expires > 0 and os.date("%Y-%m-%d %H:%M:%S", expires) or "Permanent",
        }
    end
    TriggerClientEvent('SecureServe:Panel:SendBans', src, mapped, requestId)
end)


-- //[Stats]\\ --
local function loadStats()
    local file = LoadResourceFile(GetCurrentResourceName(), statsPath)
    return (file and json.decode(file)) or {}
end

local function saveStats(stats)
    SaveResourceFile(GetCurrentResourceName(), statsPath, json.encode(stats, { indent = true }), -1)
end

local function updateUptime()
    local hours = math.floor((os.time() - startTime) / 3600)
    statsCache.serverUptime = string.format("%d hours", hours)
    saveStats(statsCache)
end

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    statsCache = loadStats()
    statsCache.totalPlayers   = statsCache.totalPlayers   or 0
    statsCache.activeCheaters = statsCache.activeCheaters or 0
    statsCache.serverUptime   = statsCache.serverUptime   or "0 minutes"
    statsCache.peakPlayers    = statsCache.peakPlayers    or 0
    saveStats(statsCache)

    logger.info("^2[SecureServe] stats.json loaded^0")

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60 * 60 * 1000)
            updateUptime()
        end
    end)
end)

AddEventHandler("playerConnecting", function()
    statsCache.totalPlayers = #GetPlayers() + 1
    if statsCache.totalPlayers > (statsCache.peakPlayers or 0) then
        statsCache.peakPlayers = statsCache.totalPlayers
    end
end)

AddEventHandler("playerDropped", function()
    statsCache.totalPlayers = #GetPlayers()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    saveStats(statsCache)
end)

RegisterNetEvent("secureServe:requestStats", function()
    local src = source
    if not require_admin(src) then return end
    TriggerClientEvent("secureServe:returnStats", src, statsCache)
end)


-- //[Restart]\\ --
RegisterNetEvent('SecureServe:Panel:RestartServer', function()
    local src = source
    if not require_admin(src) then return end

    TriggerClientEvent('chat:addMessage', -1, {
        args = { '^1SERVER', 'The server is restarting. Please reconnect shortly.' },
    })
    logger.warn(("Server restart initiated by admin %s"):format(GetPlayerName(src) or "?"))

    Citizen.Wait(5000)
    ExecuteCommand("quit graceful shutdown")
end)
