local BanManager = require("server/core/ban_manager")
local logger     = require("server/core/logger")

local PanelServer = {}

local STATS_FILE = "stats.json"
local RATE_LIMITS = {
    default = 1,
    getPlayers = 2,
    getBans = 2,
    screenshot = 5,
    clearEntities = 10,
    restart = 30,
}

local startTime = os.time()
local statsCache = {}
local lastActionAt = {}

local function getName(src)
    return GetPlayerName(src) or "?"
end

local function notify(src, message)
    TriggerClientEvent("anticheat:notify", src, message)
end

local function normalizeSource(value)
    local src = tonumber(value)
    if not src or src <= 0 then return nil end
    if not GetPlayerName(src) then return nil end
    return src
end

local function normalizeRequestId(value)
    if type(value) == "number" then return value end
    if type(value) == "string" and #value <= 32 then return value end
    return nil
end

local function getActionBucket(src)
    local bucket = lastActionAt[src]
    if not bucket then
        bucket = {}
        lastActionAt[src] = bucket
    end
    return bucket
end

local function isRateLimited(src, action)
    local now = os.time()
    local window = RATE_LIMITS[action] or RATE_LIMITS.default
    local bucket = getActionBucket(src)
    local last = bucket[action] or 0

    if (now - last) < window then
        return true
    end

    bucket[action] = now
    return false
end

local function requireAdmin(src, action)
    if not normalizeSource(src) then return false end

    if isRateLimited(src, action or "default") then
        return false
    end

    if not IsMenuAdmin(src) then
        logger.warn(("Unauthorized panel action by %s (id %s)"):format(getName(src), tostring(src)))
        return false
    end

    return true
end

local function getFirstIdentifier(src)
    local identifiers = GetPlayerIdentifiers(src)
    return identifiers and identifiers[1] or ""
end

local function buildPlayerList()
    local list = {}

    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid and GetPlayerName(pid) then
            list[#list + 1] = {
                id      = pid,
                name    = getName(pid),
                steamId = getFirstIdentifier(pid),
                ping    = GetPlayerPing(pid) or 0,
            }
        end
    end

    return list
end

local function mapBan(ban)
    local ids = ban.identifiers or {}
    local expires = tonumber(ban.expires or 0) or 0

    return {
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

local function buildBanList()
    local bans = BanManager.get_all_bans() or {}
    local mapped = {}

    for _, ban in ipairs(bans) do
        mapped[#mapped + 1] = mapBan(ban)
    end

    return mapped
end

local function getPlayerPedSet()
    local playerPeds = {}

    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid then
            local ped = GetPlayerPed(pid)
            if ped and ped ~= 0 then
                playerPeds[ped] = true
            end
        end
    end

    return playerPeds
end

local function deleteEntities(entities, protected)
    local deleted = 0

    for _, entity in ipairs(entities) do
        if DoesEntityExist(entity) and not protected[entity] then
            DeleteEntity(entity)
            deleted = deleted + 1
        end
    end

    return deleted
end

local function clearAllEntities(src)
    Citizen.CreateThread(function()
        local protected = getPlayerPedSet()
        local deleted = 0

        deleted = deleted + deleteEntities(GetAllObjects(), protected)
        Citizen.Wait(50)
        deleted = deleted + deleteEntities(GetAllPeds(), protected)
        Citizen.Wait(50)
        deleted = deleted + deleteEntities(GetAllVehicles(), protected)

        logger.info(("Admin %s cleared %d entities"):format(getName(src), deleted))
        notify(src, ("Cleared %d entities"):format(deleted))
    end)
end

local function loadStats()
    local file = LoadResourceFile(GetCurrentResourceName(), STATS_FILE)
    if not file or file == "" then return {} end

    local ok, result = pcall(json.decode, file)
    if ok and type(result) == "table" then return result end

    logger.warn("Failed to parse stats.json; using empty stats")
    return {}
end

local function saveStats(stats)
    local ok, content = pcall(json.encode, stats, { indent = true })
    if not ok then
        logger.error("Failed to encode stats.json")
        return false
    end

    return SaveResourceFile(GetCurrentResourceName(), STATS_FILE, content, -1) == true
end

local function refreshStats()
    local totalPlayers = #GetPlayers()
    statsCache.totalPlayers = totalPlayers
    statsCache.peakPlayers = math.max(tonumber(statsCache.peakPlayers or 0) or 0, totalPlayers)
    statsCache.serverUptime = string.format("%d hours", math.floor((os.time() - startTime) / 3600))
end

local function initializeStats()
    statsCache = loadStats()
    statsCache.totalPlayers = statsCache.totalPlayers or 0
    statsCache.activeCheaters = statsCache.activeCheaters or 0
    statsCache.serverUptime = statsCache.serverUptime or "0 minutes"
    statsCache.peakPlayers = statsCache.peakPlayers or 0
    refreshStats()
    saveStats(statsCache)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60 * 60 * 1000)
            refreshStats()
            saveStats(statsCache)
        end
    end)
end

local function registerEvents()
    RegisterNetEvent("anticheat:toggleOption", function(option, enabled)
        local src = source
        if not requireAdmin(src, "toggle") then return end
        if type(option) ~= "string" or #option > 64 then return end
        notify(src, option .. (enabled and " enabled" or " disabled"))
    end)

    RegisterNetEvent("anticheat:clearAllEntities", function()
        local src = source
        if not requireAdmin(src, "clearEntities") then return end
        clearAllEntities(src)
    end)

    RegisterNetEvent("unbanPlayer", function(banId)
        local src = source
        if not requireAdmin(src, "unban") then return end
        if type(banId) ~= "string" and type(banId) ~= "number" then
            notify(src, "Invalid ban ID provided")
            return
        end

        local id = tostring(banId)
        if id == "" or #id > 64 then
            notify(src, "Invalid ban ID provided")
            return
        end

        if BanManager.unban_player(id) then
            logger.info(("Ban %s removed by admin %s"):format(id, getName(src)))
            notify(src, "Player unbanned successfully")
        else
            notify(src, "Unban failed - ban not found")
        end
    end)

    RegisterNetEvent("getPlayers", function(requestId)
        local src = source
        if not requireAdmin(src, "getPlayers") then return end
        TriggerClientEvent("receivePlayers", src, buildPlayerList(), normalizeRequestId(requestId))
    end)

    RegisterNetEvent("kickPlayer", function(targetId)
        local src = source
        if not requireAdmin(src, "kick") then return end

        local target = normalizeSource(targetId)
        if not target then
            notify(src, "Invalid player ID")
            return
        end

        logger.info(("Player %s kicked by admin %s"):format(getName(target), getName(src)))
        DropPlayer(target, "You have been kicked by an admin.")
    end)

    RegisterNetEvent("banPlayer", function(targetId)
        local src = source
        if not requireAdmin(src, "ban") then return end

        local target = normalizeSource(targetId)
        if not target then
            notify(src, "Invalid player ID")
            return
        end

        local reason = "Manual ban"
        local details = { admin = getName(src), time = 0 }

        if DiscordLogger and type(DiscordLogger.request_screenshot) == "function" then
            DiscordLogger.request_screenshot(target, "Ban: Manual ban", function(image)
                if image then details.screenshot = image end
                BanManager.ban_player(target, reason, details)
            end)
        else
            BanManager.ban_player(target, reason, details)
        end
    end)

    RegisterNetEvent("SecureServe:screenshotPlayer", function(targetId)
        local src = source
        if not requireAdmin(src, "screenshot") then return end

        local target = normalizeSource(targetId)
        if not target then
            notify(src, "Invalid player ID")
            return
        end

        TriggerClientCallback({
            source    = target,
            eventName = "SecureServe:CaptureClientScreenshot",
            args      = { "jpg", 0.85 },
            timeout   = 15,
            timedout  = function()
                notify(src, "Screenshot timed out")
            end,
            callback  = function(data)
                if not data then
                    notify(src, "Failed to take screenshot")
                    return
                end
                TriggerClientEvent("SecureServe:Panel:DisplayScreenshot", src, data)
            end,
        })
    end)

    RegisterNetEvent("SecureServe:Panel:RequestBans", function(requestId)
        local src = source
        if not requireAdmin(src, "getBans") then return end
        TriggerClientEvent("SecureServe:Panel:SendBans", src, buildBanList(), normalizeRequestId(requestId))
    end)

    RegisterNetEvent("secureServe:requestStats", function()
        local src = source
        if not requireAdmin(src, "stats") then return end
        refreshStats()
        TriggerClientEvent("secureServe:returnStats", src, statsCache)
    end)

    RegisterNetEvent("executeServerOption:restartServer", function()
        local src = source
        if not requireAdmin(src, "restart") then return end

        TriggerClientEvent("chat:addMessage", -1, {
            args = { "^1SERVER", "The server is restarting. Please reconnect shortly." },
        })
        logger.warn(("Server restart initiated by admin %s"):format(getName(src)))

        Citizen.Wait(5000)
        ExecuteCommand("quit graceful shutdown")
    end)
end

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    initializeStats()
end)

AddEventHandler("playerConnecting", function()
    refreshStats()
end)

AddEventHandler("playerDropped", function()
    local src = source
    lastActionAt[src] = nil
    refreshStats()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    refreshStats()
    saveStats(statsCache)
end)

registerEvents()

return PanelServer
