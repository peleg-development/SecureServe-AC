

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

RegisterNetEvent('unbanPlayer', function(banId)
    local src = source
    if not IsMenuAdmin(src) then return end
    if not banId or banId == '' then return end
    local ok = BanManager.unban_player(tostring(banId))
    if ok then
        TriggerClientEvent('anticheat:notify', src, 'Player unbanned successfully')
    else
        TriggerClientEvent('anticheat:notify', src, 'Unban failed')
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
        local ok = BanManager.ban_player(tonumber(targetId), reason, details)
        if ok then
            print(("Player %s was banned by admin %s"):format(GetPlayerName(targetId), GetPlayerName(src)))
        end
    end
end)

RegisterNetEvent('SecureServe:Panel:RequestBans', function(requestId)
    local src = source
    if not IsMenuAdmin(src) then return end
    local bans = BanManager.get_all_bans() or {}
    local mapped = {}
    for _, ban in ipairs(bans) do
        local ids = ban.identifiers or {}
        local expires = tonumber(ban.expires or 0) or 0
        local expireText = expires > 0 and os.date("%Y-%m-%d %H:%M:%S", expires) or "Permanent"
        table.insert(mapped, {
            id = tostring(ban.id or ""),
            name = ban.player_name or "Unknown",
            reason = ban.reason or ban.detection or "",
            steam = ids.steam or "",
            discord = ids.discord or "",
            ip = ids.ip or ids.endpoint or "",
            hwid1 = ids.fivem or ids.guid or "",
            expire = expireText
        })
    end
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
