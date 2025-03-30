local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiSpeedHackModule
local AntiSpeedHack = {}

---@description Initialize Anti Speed Hack protection
function AntiSpeedHack.initialize()
    if not ConfigLoader.get_protection_setting("Anti Speed Hack", "enabled") then return end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2750)

            if Cache.Get("isInVehicle") then
                local vehicle = Cache.Get("vehicle")
                if vehicle and GetVehicleTopSpeedModifier(vehicle) > -1.0 then
                    if GetVehiclePedIsIn(GetPlayerPed(-1), false) then return end

                    DeleteEntity(vehicle)
                    if not Cache.Get("isSwimming") and not Cache.Get("isSwimmingUnderWater") and not Cache.Get("isFalling") then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Speed Hack", ConfigLoader.get_protection_setting("Anti Speed Hack", "webhook"), ConfigLoader.get_protection_setting("Anti Speed Hack", "time"))
                    end
                end

                SetVehicleTyresCanBurst(vehicle, true)
                SetEntityInvincible(vehicle, false)
            end
        end
    end)
end

ProtectionManager.register_protection("speed_hack", AntiSpeedHack.initialize)

return AntiSpeedHack 