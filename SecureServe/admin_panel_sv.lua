

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

RegisterNetEvent('unbanPlayer', function(banId)
    local src = source
    local bans = loadBans()
    for i, ban in ipairs(bans) do
        if ban.id == banId then
            table.remove(bans, i)
            break
        end
    end
    saveBans(bans)
    TriggerClientEvent('notification', src, 'Player unbanned successfully', 'success')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        loadBans()
    end
end)



RegisterNetEvent('getPlayers', function()
    local _source = source
    local players = GetPlayers()
    local playerList = {}

    for _, playerId in ipairs(players) do
        local playerName = GetPlayerName(playerId)
        table.insert(playerList, {
            id = playerId,
            name = playerName,
            steamId = GetPlayerIdentifiers(playerId)[1] 
        })
    end

    TriggerClientEvent('receivePlayers', _source, playerList)
end)

RegisterNetEvent('kickPlayer', function(targetId)
    local src = source
    if not IsAdmin(src) then
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
    if not IsAdmin(src) then
        print(("Unauthorized ban attempt by %s"):format(GetPlayerName(src)))
        return
    end
    if targetId then
        local identifiers = GetPlayerIdentifiers(targetId)
        punish_player(src, "You have been banned by an admin.", webhook, time) 
        DropPlayer(targetId, "You have been banned by an admin.")
        print(("Player %s was banned by admin %s"):format(GetPlayerName(targetId), GetPlayerName(src)))
    end
end)