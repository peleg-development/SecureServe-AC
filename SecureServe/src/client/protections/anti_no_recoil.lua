local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiNoRecoilModule
local AntiNoRecoil = {
    max_detections = 5, 
    min_recoil_value = 0.1 
}

-- Armas ignoradas (Cuerpo a cuerpo, arrojadizas, taser, etc)
local WhitelistedWeapons = {
    [GetHashKey("WEAPON_UNARMED")] = true,
    [GetHashKey("WEAPON_STUNGUN")] = true,
    [GetHashKey("WEAPON_FIREEXTINGUISHER")] = true,
    [GetHashKey("WEAPON_PETROLCAN")] = true,
    [GetHashKey("WEAPON_SNIPERRIFLE")] = true,
    [GetHashKey("WEAPON_HEAVYSNIPER")] = true,
    [GetHashKey("WEAPON_HEAVYSNIPER_MK2")] = true,
    [GetHashKey("WEAPON_RPG")] = true,
    [GetHashKey("WEAPON_HOMINGLAUNCHER")] = true
}

function AntiNoRecoil.initialize()
    if not ConfigLoader.get_protection_setting("Anti No Recoil", "enabled") then return end
    
    local detections = 0
    
    Citizen.CreateThread(function()
        while true do
            local sleep = 1000 
            local player_ped = Cache.Get("ped")

            if IsPedShooting(player_ped) then
                sleep = 100 

                local is_exempt = Cache.Get("hasPermission", "norecoil") or 
                                  Cache.Get("hasPermission", "all") or 
                                  Cache.Get("isAdmin")

                if not is_exempt and not Cache.Get("isInVehicle") then
                    local weapon_hash = Cache.Get("selectedWeapon")
                    
                    if weapon_hash and not WhitelistedWeapons[weapon_hash] then
                        
                        local recoil_shake = GetWeaponRecoilShakeAmplitude(weapon_hash)
                        
                        if recoil_shake < AntiNoRecoil.min_recoil_value then
                            detections = detections + 1
                            
                            if detections > AntiNoRecoil.max_detections then
                                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", 
                                    nil, 
                                    "Anti No Recoil (Shake: " .. string.format("%.2f", recoil_shake) .. ")", 
                                    webhook, 
                                    time
                                )
                                detections = 0 
                            end
                        else
                            
                            if detections > 0 then detections = detections - 1 end
                        end
                    end
                end
            else
                detections = 0
            end

            Citizen.Wait(sleep)
        end
    end)
end

ProtectionManager.register_protection("no_recoil", AntiNoRecoil.initialize)

return AntiNoRecoil