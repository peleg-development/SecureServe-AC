

RegisterNetEvent('anticheat:toggleOption', function(option, enabled)
    local _source = source
    if enabled then
        TriggerClientEvent('anticheat:notify', _source, option .. " enabled")
    else
        TriggerClientEvent('anticheat:notify', _source, option .. " disabled")
    end
end)

RegisterNetEvent('anticheat:clearAllEntities', function()
    for i, obj in pairs(GetAllObjects()) do
        DeleteEntity(obj)
    end
    for i, ped in pairs(GetAllPeds()) do
        DeleteEntity(ped)
    end
    for i, veh in pairs(GetAllVehicles()) do
        DeleteEntity(veh)
    end
end)





local function loadBans()
    local bansFile = LoadResourceFile(GetCurrentResourceName(), 'bans.json')
    if bansFile then
        return json.decode(bansFile)
    else
        print('Could not open bans.json')
        return {}
    end
end

local function saveBans(bans)
    local bansContent = json.encode(bans, { indent = true })
    SaveResourceFile(GetCurrentResourceName(), 'bans.json', bansContent, -1)
end

---@type BanManagerModule
local BanManager = require("server/core/ban_manager")
local logger = require("server/core/logger")

RegisterNetEvent('unbanPlayer', function(banId)
    local src = source
    local admin_name = GetPlayerName(src) or "Unknown"
    
    logger.debug("UNBAN DEBUG: Unban event triggered by " .. admin_name .. " (ID: " .. src .. ")")
    logger.debug("UNBAN DEBUG: Received banId: " .. tostring(banId) .. " (type: " .. type(banId) .. ")")
    
    if not IsMenuAdmin(src) then 
        logger.error("UNBAN DEBUG: Unauthorized unban attempt by " .. admin_name .. " (ID: " .. src .. ")")
        return 
    end
    
    if not banId or banId == '' then 
        logger.error("UNBAN DEBUG: Invalid banId provided: " .. tostring(banId))
        TriggerClientEvent('anticheat:notify', src, 'Invalid ban ID provided')
        return 
    end
    
    logger.debug("UNBAN DEBUG: Calling BanManager.unban_player with banId: " .. tostring(banId))
    local ok = BanManager.unban_player(tostring(banId))
    
    logger.debug("UNBAN DEBUG: BanManager.unban_player returned: " .. tostring(ok))
    
    if ok then
        logger.info("UNBAN DEBUG: Successfully unbanned player with banId: " .. tostring(banId) .. " by admin: " .. admin_name)
        TriggerClientEvent('anticheat:notify', src, 'Player unbanned successfully')
    else
        logger.error("UNBAN DEBUG: Failed to unban player with banId: " .. tostring(banId) .. " by admin: " .. admin_name)
        TriggerClientEvent('anticheat:notify', src, 'Unban failed - ban not found')
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        loadBans()
    end
end)



RegisterNetEvent('getPlayers', function(requestId)
    local _source = source
    if not IsMenuAdmin(_source) then return end
    local players = GetPlayers()
    local playerList = {}

    for _, playerId in ipairs(players) do
        local playerName = GetPlayerName(playerId)
        local ping = GetPlayerPing(playerId) or 0
        table.insert(playerList, {
            id = tonumber(playerId),
            name = playerName,
            steamId = GetPlayerIdentifiers(playerId)[1],
            ping = ping
        })
    end

    TriggerClientEvent('receivePlayers', _source, playerList, requestId)
end)

RegisterNetEvent('kickPlayer', function(targetId)
    local src = source
    if not IsMenuAdmin(src) then
        print(("Unauthorized kick attempt by %s"):format(GetPlayerName(src)))
        return
    end
    if targetId then
        DropPlayer(targetId, "You have been kicked by an admin.")
        print(("Player %s was kicked by admin %s"):format(GetPlayerName(targetId), GetPlayerName(src)))
    end
end)

RegisterNetEvent('banPlayer', function(targetId)
    local src = source
    if not IsMenuAdmin(src) then
        print(("Unauthorized ban attempt by %s"):format(GetPlayerName(src)))
        return
    end
    if targetId then
        local reason = "Manual ban"
        local details = { admin = GetPlayerName(src), time = 0 }

        print("PANEL DEBUG: Ban event triggered for player " .. targetId .. " by admin " .. GetPlayerName(src))
        print("PANEL DEBUG: Checking screenshot availability...")
        print("PANEL DEBUG: DiscordLogger exists: " .. tostring(DiscordLogger ~= nil))
        print("PANEL DEBUG: request_screenshot exists: " .. tostring(DiscordLogger and type(DiscordLogger.request_screenshot) == "function"))

        if DiscordLogger and type(DiscordLogger.request_screenshot) == "function" then
            print("PANEL DEBUG: Taking screenshot before ban...")
            DiscordLogger.request_screenshot(tonumber(targetId), "Ban: Manual ban", function(image)
                print("PANEL DEBUG: Screenshot callback received for player " .. targetId)
                print("PANEL DEBUG: Image data received: " .. tostring(image ~= nil))
                if image then
                    details.screenshot = image
                    print("PANEL DEBUG: Screenshot assigned to details")
                else
                    print("PANEL DEBUG: No screenshot data received")
                end
                local ok = BanManager.ban_player(tonumber(targetId), reason, details)
                if ok then
                    print(("Player %s was banned by admin %s"):format(GetPlayerName(targetId), GetPlayerName(src)))
                end
            end)
        else
            print("PANEL DEBUG: Screenshot helper unavailable, banning without screenshot")
            local ok = BanManager.ban_player(tonumber(targetId), reason, details)
            if ok then
                print(("Player %s was banned by admin %s"):format(GetPlayerName(targetId), GetPlayerName(src)))
            end
        end
    end
end)

---@param targetId number
RegisterNetEvent('SecureServe:screenshotPlayer', function(targetId)
    local src = source
    if not IsMenuAdmin(src) then return end
    if not targetId or targetId <= 0 then return end
    if not _G.exports or not _G.exports['screencapture'] then
        TriggerClientEvent('anticheat:notify', src, 'Screenshot system unavailable')
        return
    end

    _G.exports['screencapture']:serverCapture(tostring(targetId), {
        encoding = 'jpg'
    }, function(data)
        if not data then
            TriggerClientEvent('anticheat:notify', src, 'Failed to take screenshot')
            return
        end
        TriggerClientEvent('SecureServe:Panel:DisplayScreenshot', src, data)
    end)
end)

RegisterNetEvent('SecureServe:Panel:RequestBans', function(requestId)
    local src = source
    if not IsMenuAdmin(src) then return end
    
    logger.debug("BAN FETCH DEBUG: Requesting bans for admin " .. GetPlayerName(src) .. " (ID: " .. src .. ")")
    
    local bans = BanManager.get_all_bans() or {}
    logger.debug("BAN FETCH DEBUG: BanManager.get_all_bans() returned " .. #bans .. " bans")
    
    if not bans or #bans == 0 then
        logger.debug("BAN FETCH DEBUG: No bans from BanManager, trying to load from file")
        local fileBans = loadBans()
        if type(fileBans) == "table" then
            bans = fileBans
            logger.debug("BAN FETCH DEBUG: Loaded " .. #bans .. " bans from file")
        else
            logger.debug("BAN FETCH DEBUG: Failed to load bans from file")
        end
    end
    
    local mapped = {}
    for i, ban in ipairs(bans) do
        logger.debug("BAN FETCH DEBUG: Processing ban " .. i .. " - ID: " .. tostring(ban.id) .. ", Player: " .. tostring(ban.player_name))
        
        local ids = ban.identifiers or {}
        local expires = tonumber(ban.expires or 0) or 0
        local expireText = expires > 0 and os.date("%Y-%m-%d %H:%M:%S", expires) or "Permanent"
        
        local mappedBan = {
            id = tostring(ban.id or ""),
            name = ban.player_name or "Unknown",
            reason = ban.reason or ban.detection or "",
            steam = ids.steam or "",
            discord = ids.discord or "",
            ip = ids.ip or ids.endpoint or "",
            hwid1 = ids.fivem or ids.guid or "",
            expire = expireText
        }
        
        logger.debug("BAN FETCH DEBUG: Mapped ban - ID: " .. mappedBan.id .. ", Name: " .. mappedBan.name)
        table.insert(mapped, mappedBan)
    end
    
    logger.debug("BAN FETCH DEBUG: Sending " .. #mapped .. " mapped bans to client")
    TriggerClientEvent('SecureServe:Panel:SendBans', src, mapped, requestId)
end)



local statsPath = "stats.json"
local startTime = os.time()  

local function loadStats()
    local statsFile = LoadResourceFile(GetCurrentResourceName(), statsPath)
    if statsFile then
        return json.decode(statsFile)
    else
        print("^1[SecureServe] Could not open " .. statsPath .. ".^0")
        return {}
    end
end

local function saveStats(stats)
    local statsContent = json.encode(stats, { indent = true })
    SaveResourceFile(GetCurrentResourceName(), statsPath, statsContent, -1)
end

local statsCache = {}

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    statsCache = loadStats()
    
    statsCache.totalPlayers    = statsCache.totalPlayers    or 0
    statsCache.activeCheaters  = statsCache.activeCheaters  or 0
    statsCache.serverUptime    = statsCache.serverUptime    or "0 minutes"
    statsCache.peakPlayers     = statsCache.peakPlayers     or 0

    saveStats(statsCache)

    print("^2[SecureServe] stats.json loaded. Current stats: ^0")
    print(json.encode(statsCache, { indent = true }))

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60 * 60 * 1000)  
            updateUptime()
        end
    end)
end)

function updateUptime()
    local now = os.time()
    local elapsedSeconds = now - startTime
    local elapsedHours = math.floor(elapsedSeconds / 3600)

    statsCache.serverUptime = string.format("%d hours", elapsedHours)
    
    saveStats(statsCache)
end

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local playerCount = #GetPlayers() + 1  
    statsCache.totalPlayers = playerCount
    
    if playerCount > statsCache.peakPlayers then
        statsCache.peakPlayers = playerCount
    end

    saveStats(statsCache)
end)

AddEventHandler("playerDropped", function(reason)
    local playerCount = #GetPlayers()
    statsCache.totalPlayers = playerCount
    
    saveStats(statsCache)
end)



RegisterNetEvent("secureServe:requestStats", function()
    local src = source
    if not src then return end
    statsCache = loadStats()
    
    statsCache.totalPlayers    = statsCache.totalPlayers    or 0
    statsCache.activeCheaters  = statsCache.activeCheaters  or 0
    statsCache.serverUptime    = statsCache.serverUptime    or "0 minutes"
    statsCache.peakPlayers     = statsCache.peakPlayers     or 0
    
    TriggerClientEvent("secureServe:returnStats", src, statsCache)
end)

RegisterNetEvent('executeServerOption:restartServer', function()
    TriggerClientEvent('chat:addMessage', -1, {
        args = { '^1SERVER', 'The server is restarting. Please reconnect shortly.' }
    })

    print('[SERVER] Restart initiated by an admin.')

    Citizen.Wait(5000)

    os.exit() 
end)
