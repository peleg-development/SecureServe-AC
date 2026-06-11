local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiSuperJump = {}

local NORMAL_JUMP_HEIGHT = 2.5
local STRIKE_LIMIT = 4

local function isExempt()
    return Cache.Get("hasPermission", "superjump")
        or Cache.Get("hasPermission", "all")
        or Cache.Get("isAdmin")
end

local function shouldIgnorePedState(ped)
    return Cache.Get("isInVehicle")
        or Cache.Get("isSwimming")
        or Cache.Get("isSwimmingUnderWater")
        or IsPedRagdoll(ped)
        or IsPedClimbing(ped)
        or IsPedDiving(ped)
        or IsPedInParachuteFreeFall(ped)
        or IsPedOnVehicle(ped)
end

local function watchJump(ped, startPos, onSuspiciousJump)
    Citizen.CreateThread(function()
        local startZ = startPos.z
        local maxHeight = startZ
        local interrupted = false

        for _ = 1, 20 do
            Citizen.Wait(50)
            if not DoesEntityExist(ped) then return end

            if shouldIgnorePedState(ped) then
                interrupted = true
                break
            end

            local pos = GetEntityCoords(ped)
            if pos.z > maxHeight then maxHeight = pos.z end
            if not IsPedJumping(ped) then break end
        end

        if interrupted then return end

        local jumpHeight = maxHeight - startZ
        if jumpHeight > NORMAL_JUMP_HEIGHT and not IsPedFalling(ped) and not IsPedRagdoll(ped) then
            onSuspiciousJump(jumpHeight)
        end
    end)
end

function AntiSuperJump.initialize()
    if not ConfigLoader.get_protection_setting("Anti Super Jump", "enabled") then return end

    Citizen.CreateThread(function()
        local jumpFlags = 0
        local jumpActive = false

        while true do
            Citizen.Wait(1000)

            if isExempt() then
                jumpFlags = 0
                jumpActive = false
            else
                local ped = Cache.Get("ped")
                if not ped or not DoesEntityExist(ped) then
                    jumpFlags = 0
                    jumpActive = false
                elseif shouldIgnorePedState(ped) then
                    jumpActive = false
                elseif IsPedJumping(ped) and not jumpActive then
                    jumpActive = true
                    watchJump(ped, Cache.Get("coords"), function(jumpHeight)
                        jumpFlags = jumpFlags + 1
                        if jumpFlags >= STRIKE_LIMIT then
                            jumpFlags = 0
                            ProtectionHelper.punish(
                                "Anti Super Jump",
                                ("Anti Super Jump (height: %.2f)"):format(jumpHeight)
                            )
                        end
                    end)
                elseif not IsPedJumping(ped) then
                    jumpActive = false
                    if jumpFlags > 0 then jumpFlags = jumpFlags - 1 end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("super_jump", AntiSuperJump.initialize)

return AntiSuperJump
