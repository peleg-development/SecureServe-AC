local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
---@class AntiNoClipModule
local AntiNoClip = {
    is_busy = false
}
local lastUnderMapCheck = -9999999
local lastPosition
local teleportPositions = {}
local lastCoords
local lastNoClipTime = -math.huge
local noClipDetections = 0


function AntiNoClip.initialize()
    if not ConfigLoader.get_protection_setting("Anti NoClip", "enabled") then return end

    Citizen.CreateThread(function()
        while true do
            local ped = Cache.Get("ped")
            local coords = Cache.Get("coords")
            local pedHeight = GetEntityHeightAboveGround(ped)
            local isOnVehicle = IsPedOnVehicle(ped)
            local ignoreChecks = false
            if lastCoords then
                local distanceMoved = #(lastCoords - coords)
                if distanceMoved > 150.0 then
                    noClipDetections = 0
                    lastNoClipTime = GetGameTimer()
                end
            end
            if GetGameTimer() - lastNoClipTime < 6000 then
                ignoreChecks = true
            end
            if not ignoreChecks then
                if
                    coords ~= lastPosition and lastPosition ~= nil and pedHeight > 3.0 and not IsPedJumpingOutOfVehicle(ped) and not IsPedClimbing(ped) and
                        IsPedOnFoot(ped) and
                        not IsPedRagdoll(ped) and
                        not IsPedSwimming(ped) and
                        GetGameTimer() - lastUnderMapCheck > 5000
                 then
                    local parachuteState = GetPedParachuteState()
                    if not IsPedJumping(ped) and not isOnVehicle and parachuteState ~= 2 and parachuteState ~= 1 then
                        if #teleportPositions >= 5 then
                            table.remove(teleportPositions, 5)
                        end
                        table.insert(teleportPositions, 1, coords)
                        if #teleportPositions >= 5 then
                            local lastHeight = -9999.9
                            local ascendCount = 0
                            local totalDistance = 0
                            local lastPos
                            local sameHeightCount = 0
                            for i = #teleportPositions, 1, -1 do
                                local pos = teleportPositions[i]
                                if lastPos then
                                    totalDistance = totalDistance + #(pos - lastPos)
                                end
                                lastPos = pos
                                if pos.z > lastHeight + 0.05 then
                                    lastHeight = pos.z
                                    ascendCount = ascendCount + 1
                                end
                                if pos.z == lastHeight then
                                    sameHeightCount = sameHeightCount + 1
                                end
                                lastHeight = pos.z
                                if ascendCount >= 3 and totalDistance > 4.0 and pedHeight > 2.0 or sameHeightCount >= 3 and pedHeight >= 10.0 and coords.z > 0.0 then
                                    noClipDetections = noClipDetections + 1
                                    teleportPositions = {}
                                    local groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)
                                    if groundZ < 1000 then
                                        SetEntityCoords(ped, coords.x, coords.y, groundZ)
                                    end
                                    if noClipDetections >= 2 then
                                        noClipDetections = 0
                                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Noclip", webhook, time)
                                    end
                                    break
                                end
                            end
                        end
                    end
                else
                    teleportPositions = {}
                end
            end
            lastCoords = coords
        end
    end)
end

ProtectionManager.register_protection("noclip", AntiNoClip.initialize)
return AntiNoClip