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


-- //[Toggle / notify]\\ --
RegisterNetEvent('anticheat:toggleOption', function(option, enabled)
    local src = source
    if not require_admin(src) then return end
    if type(option) ~= "string" then return end
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
RegisterNetEvent('unbanPlayer', function(banId)
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
RegisterNetEvent('getPlayers', function(requestId)
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
    TriggerClientEvent('receivePlayers', src, list, requestId)
end)


-- //[Kick]\\ --
RegisterNetEvent('kickPlayer', function(targetId)
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
RegisterNetEvent('banPlayer', function(targetId)
    local src = source
    if not require_admin(src) then return end
    local pid = valid_target(targetId)
    if not pid then
        TriggerClientEvent('anticheat:notify', src, 'Invalid player ID')
        return
    end

    local reason = "Manual ban"
    local details = { admin = GetPlayerName(src), time = 0 }

    if DiscordLogger and type(DiscordLogger.request_screenshot) == "function" then
        DiscordLogger.request_screenshot(pid, "Ban: Manual ban", function(image)
            if image then details.screenshot = image end
            BanManager.ban_player(pid, reason, details)
        end)
    else
        BanManager.ban_player(pid, reason, details)
    end
end)


-- //[Screenshot]\\ --
RegisterNetEvent('SecureServe:screenshotPlayer', function(targetId)
    local src = source
    if not require_admin(src) then return end
    local pid = valid_target(targetId)
    if not pid then return end

    TriggerClientCallback({
        source    = pid,
        eventName = 'SecureServe:CaptureClientScreenshot',
        args      = { 'jpg', 0.85 },
        timeout   = 15,
        timedout  = function()
            TriggerClientEvent('anticheat:notify', src, 'Screenshot timed out')
        end,
        callback  = function(data)
            if not data then
                TriggerClientEvent('anticheat:notify', src, 'Failed to take screenshot')
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
RegisterNetEvent('executeServerOption:restartServer', function()
    local src = source
    if not require_admin(src) then return end

    TriggerClientEvent('chat:addMessage', -1, {
        args = { '^1SERVER', 'The server is restarting. Please reconnect shortly.' },
    })
    logger.warn(("Server restart initiated by admin %s"):format(GetPlayerName(src) or "?"))

    Citizen.Wait(5000)
    ExecuteCommand("quit graceful shutdown")
end)
