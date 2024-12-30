RegisterNetEvent('ssm:kickPlayer', function(playerId)
    DropPlayer(playerId, "You have been kicked by an admin.")
end)

RegisterNetEvent('ssm:banPlayer', function(playerId)
    DropPlayer(playerId, "You have been banned by an admin.")
end)


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

-- server.lua

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

RegisterNetEvent('kickPlayer', function(playerId)
    DropPlayer(playerId, "You have been kicked from the server.")
end)

RegisterNetEvent('banPlayer', function(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    punish_player(source, "You have been banned" , webhook, time)
end)

