local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiSuperJump = {}

function AntiSuperJump.initialize()
    if not ConfigLoader.get_protection_setting("Anti Super Jump", "enabled") then return end

    local jump_flags = 0
    local NORMAL_JUMP_HEIGHT = 2.5

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)

            if Cache.Get("hasPermission", "superjump")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                jump_flags = 0
                goto continue
            end

            local ped = Cache.Get("ped")
            if not ped or not DoesEntityExist(ped) then goto continue end

            if Cache.Get("isInVehicle")
                or Cache.Get("isSwimming")
                or Cache.Get("isSwimmingUnderWater")
                or IsPedRagdoll(ped)
                or IsPedClimbing(ped)
                or IsPedDiving(ped)
                or IsPedInParachuteFreeFall(ped)
                or IsPedOnVehicle(ped)
            then
                goto continue
            end

            local current_pos = Cache.Get("coords")

            if IsPedJumping(ped) then
                Citizen.CreateThread(function()
                    local start_pos = GetEntityCoords(ped)
                    local _, ground_z = GetGroundZFor_3dCoord(start_pos.x, start_pos.y, start_pos.z, true)
                    local start_z = math.min(start_pos.z, ground_z or start_pos.z)
                    local max_height = start_z
                    local interrupted = false

                    for i = 1, 20 do
                        Citizen.Wait(50)
                        if not DoesEntityExist(ped) then return end

                        if IsPedRagdoll(ped) or IsPedClimbing(ped)
                            or IsPedDiving(ped) or IsPedInParachuteFreeFall(ped)
                            or IsPedOnVehicle(ped) or Cache.Get("isInVehicle")
                        then
                            interrupted = true
                            break
                        end

                        local pos = GetEntityCoords(ped)
                        if pos.z > max_height then max_height = pos.z end
                        if not IsPedJumping(ped) then break end
                    end

                    if interrupted then return end

                    local jump_height = max_height - start_z

                    if jump_height > NORMAL_JUMP_HEIGHT and not IsPedFalling(ped) and not IsPedRagdoll(ped) then
                        jump_flags = jump_flags + 1
                        if jump_flags >= 4 then
                            ProtectionHelper.punish('Anti Super Jump',
                                ("Anti Super Jump (height: %.2f)"):format(jump_height))
                            jump_flags = 0
                        end
                    else
                        if jump_flags > 0 then jump_flags = jump_flags - 1 end
                    end
                end)
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("super_jump", AntiSuperJump.initialize)

return AntiSuperJump
