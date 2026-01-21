local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiSpeedHackModule
local AntiSpeedHack = {
    max_on_foot_speed = 10.0, -- Aprox 36km/h (Sprint normal es ~7-8)
    margin = 1.5 -- Margen para evitar falsos positivos por lag o saltos
}

function AntiSpeedHack.initialize()
    if not ConfigLoader.get_protection_setting("Anti Speed Hack", "enabled") then return end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2500)
            
            local ped = Cache.Get("ped")
            local is_exempt = Cache.Get("hasPermission", "speedhack") or 
                              Cache.Get("hasPermission", "all") or 
                              Cache.Get("isAdmin")

            if not is_exempt and ped then
                local vehicle = Cache.Get("vehicle")
                local speed = GetEntitySpeed(ped)
                local in_vehicle = Cache.Get("isInVehicle")

                if in_vehicle and vehicle then
                    if GetVehicleTopSpeedModifier(vehicle) > 1.1 or GetVehicleCheatPowerIncrease(vehicle) > 1.1 then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Speed Hack (Multiplier)", webhook, time)
                    end

                    SetVehicleTyresCanBurst(vehicle, true)
                    SetEntityInvincible(vehicle, false)
                
                elseif not in_vehicle then
                    local is_ignorable = IsPedFalling(ped) or IsPedInParachuteFreeFall(ped) or IsPedSwimming(ped)
                    
                    if not is_ignorable and speed > (AntiSpeedHack.max_on_foot_speed + AntiSpeedHack.margin) then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Speed Hack (Foot Speed: "..tostring(speed)..")", webhook, time)
                    end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("speed_hack", AntiSpeedHack.initialize)
return AntiSpeedHack