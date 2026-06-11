local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiNoClip = {}

local STRIKE_LIMIT = 2
local TELEPORT_DISTANCE = 150.0
local NOCLIP_SPEED = 12.0
local POST_TELEPORT_GRACE = 6000

local function isExempt()
    return Cache.Get("hasPermission", "noclip")
        or Cache.Get("hasPermission", "all")
        or Cache.Get("isAdmin")
end

local function isValidMovement(ped)
    local parachute = GetPedParachuteState()

    return Cache.Get("isInVehicle")
        or IsPedJumping(ped)
        or IsPedClimbing(ped)
        or IsPedFalling(ped)
        or IsPedSwimming(ped)
        or IsPedRagdoll(ped)
        or IsPedOnVehicle(ped)
        or parachute == 1
        or parachute == 2
end

local function pullToGround(ped, coords)
    local hasGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)
    if hasGround and groundZ < 1000 then
        SetEntityCoords(ped, coords.x, coords.y, groundZ, false, false, false, false)
    end
end

function AntiNoClip.initialize()
    if not ConfigLoader.get_protection_setting("Anti Noclip", "enabled") then return end

    Citizen.CreateThread(function()
        local strikes = 0
        local lastTeleportAt = -math.huge
        local lastPosition = nil

        while true do
            Citizen.Wait(1000)

            if isExempt() then
                lastPosition = nil
                strikes = 0
            else
                local ped = Cache.Get("ped")
                if not ped or not DoesEntityExist(ped) then
                    lastPosition = nil
                else
                    local coords = Cache.Get("coords")
                    local now = GetGameTimer()

                    if not lastPosition then
                        lastPosition = coords
                    else
                        local distance = #(coords - lastPosition)

                        if distance > TELEPORT_DISTANCE then
                            lastTeleportAt = now
                            strikes = 0
                            lastPosition = coords
                        elseif (now - lastTeleportAt) < POST_TELEPORT_GRACE then
                            lastPosition = coords
                        elseif not isValidMovement(ped) and distance > NOCLIP_SPEED then
                            strikes = strikes + 1
                            pullToGround(ped, coords)

                            if strikes >= STRIKE_LIMIT then
                                strikes = 0
                                ProtectionHelper.punish("Anti Noclip", "Anti Noclip")
                            end

                            lastPosition = coords
                        else
                            if strikes > 0 then strikes = strikes - 1 end
                            lastPosition = coords
                        end
                    end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("noclip", AntiNoClip.initialize)

return AntiNoClip
