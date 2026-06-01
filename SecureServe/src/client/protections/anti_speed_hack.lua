local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiSpeedHack = {}

local last_damage_event = 0
local last_explosion    = 0
local last_vehicle_exit = 0

function AntiSpeedHack.initialize()
    if not ConfigLoader.get_protection_setting("Anti Speed Hack", "enabled") then
        return
    end

    local max_speed = tonumber(ConfigLoader.get_protection_setting("Anti Speed Hack", "defaultr")) or 8.0
    local tolerance = tonumber(ConfigLoader.get_protection_setting("Anti Speed Hack", "defaults")) or 4.5
    local threshold = max_speed + tolerance

    local KNOCKBACK_GRACE = 5000

    AddEventHandler('gameEventTriggered', function(event, data)
        if event == 'CEventNetworkEntityDamage' or event == 'CEventNetworkPlayerCollectedAmbientItem' then
            local victim = data and data[1]
            if victim and victim == PlayerPedId() then
                last_damage_event = GetGameTimer()
            end
        end
    end)

    AddEventHandler('CEventExplosion', function()
        last_explosion = GetGameTimer()
    end)

    Citizen.CreateThread(function()
        local was_in_vehicle = false
        while true do
            Citizen.Wait(250)
            local in_v = Cache.Get("isInVehicle")
            if was_in_vehicle ~= in_v then
                last_vehicle_exit = GetGameTimer()
            end
            was_in_vehicle = in_v
        end
    end)

    Citizen.CreateThread(function()
        local strikes = 0
        local STRIKE_LIMIT = 4

        while true do
            Citizen.Wait(2500)

            local is_exempt = Cache.Get("hasPermission", "speedhack")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")

            if is_exempt then
                strikes = 0
                goto continue
            end

            local ped = Cache.Get("ped")
            if not ped or not DoesEntityExist(ped) then
                goto continue
            end

            local now = GetGameTimer()
            if (now - last_damage_event) < KNOCKBACK_GRACE
                or (now - last_explosion) < KNOCKBACK_GRACE
                or (now - last_vehicle_exit) < KNOCKBACK_GRACE
            then
                goto continue
            end

            local in_vehicle = Cache.Get("isInVehicle")
            local detected_reason = nil

            if in_vehicle then
                local vehicle = Cache.Get("vehicle")
                if vehicle and DoesEntityExist(vehicle) then
                    if GetVehicleTopSpeedModifier(vehicle) > 1.1
                        or GetVehicleCheatPowerIncrease(vehicle) > 1.1
                    then
                        detected_reason = "Anti Speed Hack (Multiplier)"
                    end
                end
            else
                local is_ignorable = IsPedFalling(ped)
                    or IsPedInParachuteFreeFall(ped)
                    or IsPedSwimming(ped)
                    or IsPedRagdoll(ped)
                    or IsPedJumping(ped)
                    or IsPedClimbing(ped)
                    or IsPedDiving(ped)
                    or IsPedOnVehicle(ped)
                    or IsPedJumpingOutOfVehicle(ped)
                    or GetIsTaskActive(ped, 2)

                if not is_ignorable then
                    local speed = GetEntitySpeed(ped)
                    if speed > threshold then
                        detected_reason = ("Anti Speed Hack (Foot Speed: %.2f)"):format(speed)
                    end
                end
            end

            if detected_reason then
                strikes = strikes + 1
                if strikes >= STRIKE_LIMIT then
                    strikes = 0
                    ProtectionHelper.punish("Anti Speed Hack", detected_reason)
                end
            else
                if strikes > 0 then strikes = strikes - 1 end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("speed_hack", AntiSpeedHack.initialize)
return AntiSpeedHack
