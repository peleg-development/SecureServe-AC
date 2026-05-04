local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiNoClip = {}

function AntiNoClip.initialize()
    if not ConfigLoader.get_protection_setting("Anti Noclip", "enabled") then
        return
    end

    local STRIKE_LIMIT       = 2
    local TELEPORT_DISTANCE  = 150.0
    local NOCLIP_SPEED       = 12.0
    local POST_TELEPORT_GRACE = 6000

    Citizen.CreateThread(function()
        local strikes = 0
        local last_teleport_at = -math.huge
        local last_pos = nil

        while true do
            Citizen.Wait(1000)

            if Cache.Get("hasPermission", "noclip")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                last_pos = nil
                strikes = 0
                goto continue
            end

            local ped = Cache.Get("ped")
            if not ped or not DoesEntityExist(ped) then
                last_pos = nil
                goto continue
            end

            local coords = Cache.Get("coords")
            local now = GetGameTimer()

            if last_pos then
                local dist = #(coords - last_pos)

                if dist > TELEPORT_DISTANCE then
                    last_teleport_at = now
                    strikes = 0
                    last_pos = coords
                    goto continue
                end

                if (now - last_teleport_at) < POST_TELEPORT_GRACE then
                    last_pos = coords
                    goto continue
                end

                local in_vehicle = Cache.Get("isInVehicle")
                local jumping    = IsPedJumping(ped)
                local climbing   = IsPedClimbing(ped)
                local falling    = IsPedFalling(ped)
                local swimming   = IsPedSwimming(ped)
                local ragdoll    = IsPedRagdoll(ped)
                local parachute  = GetPedParachuteState()
                local on_vehicle = IsPedOnVehicle(ped)

                local valid_movement = in_vehicle or jumping or climbing or falling
                    or swimming or ragdoll or on_vehicle
                    or parachute == 1 or parachute == 2

                if not valid_movement and dist > NOCLIP_SPEED then
                    strikes = strikes + 1

                    local has_ground, ground_z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)
                    if has_ground and ground_z < 1000 then
                        SetEntityCoords(ped, coords.x, coords.y, ground_z, false, false, false, false)
                    end

                    if strikes >= STRIKE_LIMIT then
                        strikes = 0
                        ProtectionHelper.punish("Anti Noclip", "Anti Noclip")
                    end
                else
                    if strikes > 0 then strikes = strikes - 1 end
                end
            end

            last_pos = coords

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("noclip", AntiNoClip.initialize)
return AntiNoClip
