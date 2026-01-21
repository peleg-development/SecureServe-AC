

RegisterCommand('ssm', function()
    local Perms = Perms or require("client/core/perms")
    if Perms.IsMenuAdmin(GetPlayerServerId(PlayerId())) then
        SetNuiFocus(true, true)
        local defaults = { players = 5000, bans = 15000, stats = 10000 }
        local refresh = ConfigLoader.get("AdminMenu.AutoRefresh", defaults) or defaults
        SendNUIMessage({ action = 'open', refresh = refresh })
    end
end, false)

function ac_notify(message) 
    SendNUIMessage({ action = 'notification', message = message })
end 

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)


RegisterNUICallback("clearAllEntities", function(data, cb)
    TriggerServerEvent('anticheat:clearAllEntities')
    cb('ok')
end)

local playerOptions = {
    ESP = false,
    ["Player Names"] = false,
    ["God Mode"] = false,
    ["No Clip"] = false,
    Invisibility = false,
    Bones = false
}

RegisterNUICallback('toggleOptiona', function(data, cb)
    local option = data.option
    local enabled = data.enabled

    playerOptions[option] = enabled
    TriggerServerEvent('anticheat:toggleOption', option, enabled)
    
    if option == "ESP" then
        toggleESP(enabled)
    elseif option == "Player Names" then
        togglePlayerNames(enabled)
    elseif option == "God Mode" then
        toggleGodMode(enabled)
    elseif option == "No Clip" then
        toggleNoClip(enabled)
    elseif option == "Invisibility" then
        toggleInvisibility(enabled)
    elseif option == "Bones" then
        toggleBones(enabled)
    end

    cb('ok')
end)

RegisterNetEvent('anticheat:notify', function(message)
    SendNUIMessage({ action = 'notification', message = message })
end)

function toggleESP(enable)
    if enable then
        Citizen.CreateThread(function()
            while playerOptions.ESP do
                Citizen.Wait(0)
                local PlayerList = GetActivePlayers()
                for i = 1, #PlayerList do
                    local curplayerped = GetPlayerPed(PlayerList[i])
                    local bone = GetEntityBoneIndexByName(curplayerped, "SKEL_HEAD")
                    local x, y, z = table.unpack(GetPedBoneCoords(curplayerped, bone, 0.0, 0.0, 0.0))
                    local px, py, pz = table.unpack(GetGameplayCamCoord())

                    if GetDistanceBetweenCoords(x, y, z, px, py, pz, true) < 300 + 0.0 then
                        if (curplayerped ~= PlayerPedId() or true) and IsEntityOnScreen(curplayerped) then
                            z = z + 0.9
                            local Distance = GetDistanceBetweenCoords(x, y, z, px, py, pz, true) * 0.002 / 2
                            if Distance < 0.0042 then
                                Distance = 0.0042
                            end

                            local color = { r = 255, g = 255, b = 255 }
                            local retval, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
                            local width = 0.00045
                            local height = 0.0023

                            DrawRect(_x, _y, width / Distance, 0.0015, color.r, color.g, color.b, 200)
                            DrawRect(_x, _y + height / Distance, width / Distance, 0.0015, color.r, color.g, color.b, 200)
                            DrawRect(_x + width / 2 / Distance, _y + height / 2 / Distance, 0.001, height / Distance,
                                color.r, color.g, color.b, 200)
                            DrawRect(_x - width / 2 / Distance, _y + height / 2 / Distance, 0.001, height / Distance,
                                color.r, color.g, color.b, 200)
                            -- DrawText3Ds(x,y,z-0.5,("%s"):format("hello"))
                            local health = GetEntityHealth(curplayerped)
                            if health > 200 then
                                health = 200
                            end

                            DrawRect(_x - 0.00028 / Distance, _y + height / 2 / Distance, 0.0016 / Distance * 0.015,
                                height / Distance, 0, 0, 0, 200)
                            DrawRect(_x - 0.00028 / Distance,
                                _y + height / Distance - GetEntityHealth(curplayerped) / 175000 / Distance,
                                0.0016 / Distance * 0.015, GetEntityHealth(curplayerped) / 87500 / Distance, 0, 255, 0,
                                200)
                            DrawRect(_x - 0.00033 / Distance, _y + height / 2 / Distance, 0.0016 / Distance * 0.015,
                                height / Distance, 0, 0, 0, 200)

                            DrawRect(_x - 0.00033 / Distance,
                                _y + height / Distance - GetPedArmour(curplayerped) / 87500 / Distance,
                                0.0016 / Distance * 0.015, GetPedArmour(curplayerped) / 43750 / Distance, 0, 77, 166, 255)
                        end
                    end
                end
            end
        end)
    end
end
function DrawText3Ds(x, y, z, text)
    SetTextScale(0.45, 0.45)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextDropShadow()
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    -- DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function togglePlayerNames(enable)
    if enable then
        Citizen.CreateThread(function()
            while playerOptions.PlayerNames do
                Citizen.Wait(0)
                local PlayerList = GetActivePlayers()
                local x2, y2, z2 = table.unpack(GetEntityCoords(PlayerPedId()))
                for i = 1, #PlayerList do
                    local curplayerped = GetPlayerPed(PlayerList[i])
                    local x1, y1, z1 = table.unpack(GetEntityCoords(curplayerped))
                    local talking = "~s~[~y~TALKING~s~]"
                    local dist = math.floor(GetDistanceBetweenCoords(x2, y2, z2, x1, y1, z1, true) + 0.5)
                    if not NetworkIsPlayerTalking(PlayerList[i]) then talking = "" else talking = talking end
                    local bone = GetEntityBoneIndexByName(curplayerped, "SKEL_HEAD")
                    local x, y, z = table.unpack(GetPedBoneCoords(curplayerped, bone, 0.0, 0.0, 0.0))
                    if dist < 3000 then
                        DrawText3Ds(x, y, z + 0.9,
                            ("%s ~s~[~w~%s~s~] ~w~%s~s~"):format(talking, GetPlayerServerId(PlayerList[i]),
                                GetPlayerName(PlayerList[i])))
                        DrawText3Ds(x, y, z - 1, ("%sm"):format(dist))
                    end
                end
            end
        end)
    end
end

function toggleGodMode(enable)
    local playerPed = PlayerPedId()
    SetEntityInvincible(playerPed, enable)
end

local noclip = false
function toggleNoClip(enable)
    noclip = enable
    if not enable then
        local me = PlayerPedId()
        SetEntityVisible(me, true, false)
        SetLocalPlayerVisibleLocally(true)
        FreezeEntityPosition(me, false, false)
        SetEntityInvincible(me, false)
        SetEntityCollision(me, true, true)
        return
    end
    
    Citizen.CreateThread(function()
        local me = PlayerPedId()

        while noclip and playerOptions["No Clip"] do
            Citizen.Wait(0)
            local me = PlayerPedId()
            local lastVehicle = nil
            local isInVehicle = false
            local vehicle = GetVehiclePedIsIn(me, false)
            isInVehicle = vehicle ~= nil and vehicle ~= 0
            SetLocalPlayerVisibleLocally(true)
            FreezeEntityPosition(me, true, false)

            if not isInVehicle then
                local x, y, z = table.unpack(GetEntityCoords(me, true))
                local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
                local pitch = GetGameplayCamRelativePitch()

                local dx = -math.sin(heading * math.pi / 180.0)
                local dy = math.cos(heading * math.pi / 180.0)
                local dz = math.sin(pitch * math.pi / 180.0)

                local len = math.sqrt(dx * dx + dy * dy + dz * dz)
                if len ~= 0 then
                    dx = dx / len
                    dy = dy / len
                    dz = dz / len
                end

                local speed = 0.5

                SetEntityVelocity(me, 0.0001, 0.0001, 0.0001)

                if IsControlPressed(0, 21) then 
                    speed = speed + 1
                end

                if IsControlPressed(0, 19) then 
                    speed = 0.25
                end

                if IsControlPressed(0, 32) then 
                    x = x + speed * dx
                    y = y + speed * dy
                    z = z + speed * dz
                end

                if IsControlPressed(0, 34) then 
                    local leftVector = vector3(-dy, dx, 0.0)
                    x = x + speed * leftVector.x
                    y = y + speed * leftVector.y
                end

                if IsControlPressed(0, 269) then 
                    x = x - speed * dx
                    y = y - speed * dy
                    z = z - speed * dz
                end

                if IsControlPressed(0, 9) then 
                    local rightVector = vector3(dy, -dx, 0.0)
                    x = x + speed * rightVector.x
                    y = y + speed * rightVector.y
                end

                if IsControlPressed(0, 22) then 
                    z = z + speed
                end

                if IsControlPressed(0, 62) then 
                    z = z - speed
                end

                SetEntityCoordsNoOffset(me, x, y, z, true, true, true)
                SetEntityHeading(me, heading)
            else
                local x, y, z = table.unpack(GetEntityCoords(vehicle, true))
                local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(vehicle)
                local pitch = GetGameplayCamRelativePitch()

                local dx = -math.sin(heading * math.pi / 180.0)
                local dy = math.cos(heading * math.pi / 180.0)
                local dz = math.sin(pitch * math.pi / 180.0)

                local len = math.sqrt(dx * dx + dy * dy + dz * dz)
                if len ~= 0 then
                    dx = dx / len
                    dy = dy / len
                    dz = dz / len
                end

                local speed = 0.5

                if IsControlPressed(0, 21) then 
                    speed = speed + 1
                end

                if IsControlPressed(0, 19) then 
                    speed = 0.25
                end

                if IsControlPressed(0, 32) then
                    x = x + speed * dx
                    y = y + speed * dy
                    z = z + speed * dz
                end

                if IsControlPressed(0, 34) then 
                    local leftVector = vector3(-dy, dx, 0.0)
                    x = x + speed * leftVector.x
                    y = y + speed * leftVector.y
                end

                if IsControlPressed(0, 269) then 
                    x = x - speed * dx
                    y = y - speed * dy
                    z = z - speed * dz
                end

                if IsControlPressed(0, 9) then 
                    local rightVector = vector3(dy, -dx, 0.0)
                    x = x + speed * rightVector.x
                    y = y + speed * rightVector.y
                end

                if IsControlPressed(0, 22) then
                    z = z + speed
                end

                if IsControlPressed(0, 62) then 
                    z = z - speed
                end

                SetEntityCoordsNoOffset(vehicle, x, y, z, true, true, true)
                SetEntityHeading(vehicle, heading)
            end
        end
        SetEntityVisible(PlayerPedId(), true, false)
        SetLocalPlayerVisibleLocally(true)
        FreezeEntityPosition(me, false, false)
        SetEntityInvincible(PlayerPedId(), false)
        SetEntityCollision(PlayerPedId(), true, true)
    end)
end

function toggleInvisibility(enable)
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, not enable, false)
end
GetPedBoneCoordsF = function(ped, boneId)
    local cam = GetFinalRenderedCamCoord()
    local ret, coords, shape = GetShapeTestResult(
        StartShapeTestRay(
            vector3(cam), vector3(GetPedBoneCoords(ped, 0x0)), -1
        )
    )
    if coords then
        a = Vdist(cam, shape) / Vdist(cam, GetPedBoneCoords(ped, 0x0))
    else
        a = 0.83
    end
    if a > 1 then
        a = 0.83
    end
    if ret then
        return (((GetPedBoneCoords(ped, boneId) - cam) * ((a) * 0.83)) + cam)
    end
end
function toggleBones(enable)
    if enable then
        Citizen.CreateThread(function()
            while playerOptions.Bones do
                Citizen.Wait(0)
                for k, v in pairs(GetActivePlayers()) do
                    local ped = GetPlayerPed(v)
                    if GetDistanceBetweenCoords(GetEntityCoords(ped), GetEntityCoords(PlayerPedId()), true) < 300 + 0.0 and (ped ~= PlayerPedId() or true) then
                        DrawLine(GetPedBoneCoordsF(ped, 31086, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0x9995, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0x9995, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0xE0FD, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0x5C57, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0xE0FD, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0x192A, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0xE0FD, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0x3FCF, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0x192A, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0xCC4D, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0x3FCF, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0xB3FE, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0x5C57, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0xB3FE, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0x3779, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0x9995, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0xB1C5, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0xB1C5, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0xEEEB, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0xEEEB, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0x49D9, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0x9995, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0x9D4D, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0x9D4D, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0x6E5C, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                        DrawLine(GetPedBoneCoordsF(ped, 0x6E5C, 0.0, 0.0, 0.0),
                            GetPedBoneCoordsF(ped, 0xDEAD, 0.0, 0.0, 0.0), 255, 255, 255, 255)
                    end
                end
            end
        end)
    end
end


function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end




RegisterNUICallback('unbanPlayer', function(data, cb)
    local banId = data.banId
    print("UNBAN DEBUG: Client NUI callback triggered with data: " .. json.encode(data))
    print("UNBAN DEBUG: Extracted banId: " .. tostring(banId) .. " (type: " .. type(banId) .. ")")
    
    if not banId then
        print("UNBAN DEBUG: No banId provided in data")
        cb('error')
        return
    end
    
    print("UNBAN DEBUG: Triggering server event 'unbanPlayer' with banId: " .. tostring(banId))
    TriggerServerEvent('unbanPlayer', banId)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    local vehicleName = data.vehicleName
    if not vehicleName or vehicleName == '' then
        cb('ok')
        return
    end
    
    local vehicleHash = GetHashKey(vehicleName)
    RequestModel(vehicleHash)
    
    local timeout = 0
    while not HasModelLoaded(vehicleHash) and timeout < 1000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end
    
    if HasModelLoaded(vehicleHash) then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        local vehicle = CreateVehicle(vehicleHash, coords.x + 3.0, coords.y, coords.z, heading, true, false)
        SetPedIntoVehicle(playerPed, vehicle, -1)
        SetModelAsNoLongerNeeded(vehicleHash)
        ac_notify('Vehicle spawned: ' .. vehicleName)
    else
        ac_notify('Failed to spawn vehicle: ' .. vehicleName)
    end
    
    cb('ok')
end)

RegisterNUICallback('spawnObject', function(data, cb)
    local objectName = data.objectName
    if not objectName or objectName == '' then
        cb('ok')
        return
    end
    
    local objectHash = GetHashKey(objectName)
    RequestModel(objectHash)
    
    local timeout = 0
    while not HasModelLoaded(objectHash) and timeout < 1000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end
    
    if HasModelLoaded(objectHash) then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        local obj = CreateObject(objectHash, coords.x + 2.0, coords.y, coords.z, true, true, true)
        SetEntityHeading(obj, heading)
        SetModelAsNoLongerNeeded(objectHash)
        ac_notify('Object spawned: ' .. objectName)
    else
        ac_notify('Failed to spawn object: ' .. objectName)
    end
    
    cb('ok')
end)

RegisterNUICallback('changePed', function(data, cb)
    local pedModel = data.pedModel
    if not pedModel or pedModel == '' then
        cb('ok')
        return
    end
    
    local pedHash = GetHashKey(pedModel)
    RequestModel(pedHash)
    
    local timeout = 0
    while not HasModelLoaded(pedHash) and timeout < 1000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end
    
    if HasModelLoaded(pedHash) then
        SetPlayerModel(PlayerId(), pedHash)
        SetModelAsNoLongerNeeded(pedHash)
        ac_notify('Ped changed to: ' .. pedModel)
    else
        ac_notify('Failed to change ped: ' .. pedModel)
    end
    
    cb('ok')
end)


local pendingPlayersPromise = nil
RegisterNetEvent('receivePlayers', function(playerList, requestId)
    SendNUIMessage({
        action = 'players',
        players = playerList
    })
    if pendingPlayersPromise and pendingPlayersPromise.id == requestId then
        pendingPlayersPromise.resolve(playerList)
        pendingPlayersPromise = nil
    end
end)

RegisterNUICallback('getPlayers', function(data, cb)
    local reqId = math.random(100000, 999999)
    local p = promise.new()
    pendingPlayersPromise = { id = reqId, resolve = function(result) p:resolve(result) end }
    TriggerServerEvent('getPlayers', reqId)
    local ok, result = pcall(function() return Citizen.Await(p) end)
    if ok then
        cb({ players = result })
    else
        cb({ players = {} })
    end
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    local playerId = data.playerId
    TriggerServerEvent('kickPlayer', playerId)
    cb({ success = true })
end)

RegisterNUICallback('banPlayer', function(data, cb)
    local playerId = data.playerId
    TriggerServerEvent('banPlayer', playerId)
    cb({ success = true })
end)

RegisterNUICallback('spectatePlayer', function(data, cb)
    local playerId = data.playerId
    local targetPed = GetPlayerPed(GetPlayerFromServerId(playerId))
    
    if DoesEntityExist(targetPed) then
        local playerPed = PlayerPedId()
        local targetCoords = GetEntityCoords(targetPed)

        RequestCollisionAtCoord(targetCoords.x, targetCoords.y, targetCoords.z)
        NetworkSetInSpectatorMode(true, targetPed)

        ac_notify("Spectating player " .. playerId .. ". Press BACKSPACE to exit.")

        Citizen.CreateThread(function()
            while NetworkIsInSpectatorMode() do
                Citizen.Wait(0)
                if IsControlJustReleased(0, 177) then -- 177 = Backspace
                    NetworkSetInSpectatorMode(false, playerPed)
                    ac_notify("Exited spectating mode.")
                    break
                end
            end
        end)

        cb({ success = true })
    else
        cb({ success = false })
    end
end)

-- old receivePlayers kept for backward compatibility in case server doesn't send requestId
RegisterNetEvent('receivePlayers', function(playerList)
    SendNUIMessage({ action = 'players', players = playerList })
end)


local pendingStatsPromise = nil
RegisterNetEvent("secureServe:returnStats", function(stats)
    SendNUIMessage({
        action = "dashboardStats",
        totalPlayers    = stats.totalPlayers,
        activeCheaters  = stats.activeCheaters,
        serverUptime    = stats.serverUptime,
        peakPlayers     = stats.peakPlayers
    })
    if pendingStatsPromise then
        pendingStatsPromise:resolve(stats)
        pendingStatsPromise = nil
    end
end)

RegisterNUICallback("getDashboardStats", function(data, cb)
    local p = promise.new()
    pendingStatsPromise = p
    TriggerServerEvent("secureServe:requestStats")
    local stats = Citizen.Await(p)
    cb({
        totalPlayers    = stats.totalPlayers or 0,
        activeCheaters  = stats.activeCheaters or 0,
        serverUptime    = stats.serverUptime or "0 minutes",
        peakPlayers     = stats.peakPlayers or 0
    })
end)
    

RegisterNUICallback('screenshotPlayer', function(data, cb)
    local playerId = data.playerId
    TriggerServerEvent('SecureServe:screenshotPlayer', playerId)
    cb({ success = true })
end)

RegisterNetEvent('SecureServe:Panel:DisplayScreenshot', function(imageData)
    SendNUIMessage({
        action = 'displayScreenshot',
        imageUrl = imageData
    })
end)

RegisterNUICallback('executeServerOption', function(data, cb)
    if data.action == 'restart' then
        TriggerServerEvent('executeServerOption:restartServer')
    end

    cb({ success = true })
end)

local pendingBansPromiseMap = {}
RegisterNetEvent('SecureServe:Panel:SendBans', function(bans, requestId)
    
    local entry = pendingBansPromiseMap[requestId]
    if entry then
        entry:resolve(bans)
        pendingBansPromiseMap[requestId] = nil
    else
    end
    
    SendNUIMessage({ action = 'bans', bans = bans })
end)

RegisterNUICallback('getBans', function(data, cb)
    local reqId = math.random(100000, 999999)
    
    local p = promise.new()
    pendingBansPromiseMap[reqId] = p
    TriggerServerEvent('SecureServe:Panel:RequestBans', reqId)
    
    local bans = Citizen.Await(p)
    

    
    cb({ bans = bans })
end)
