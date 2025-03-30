local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")
local ConfigLoader = require("client/core/config_loader")

---@class AntiNoReloadModule
local AntiNoReload = {}

---@description Initialize Anti No Reload protection
function AntiNoReload.initialize()
    if not ConfigLoader.get_protection_setting("Anti No Reload", "enabled") then return end
    
    Citizen.CreateThread(function()
        local last_ammo_count = nil
        local last_weapon = nil
        local warns = 0
        local player_ped = Cache.Get("ped")
    
        while true do
            Citizen.Wait(1)
            local weapon_hash = Cache.Get("selectedWeapon")
            local weapon_group = GetWeapontypeGroup(weapon_hash)
    
            if weapon_hash == GetHashKey("WEAPON_UNARMED") then
                Citizen.Wait(2500)
            else
                if weapon_group ~= GetHashKey("WEAPON_GROUP_MELEE") and IsPedWeaponReadyToShoot(player_ped) then
                    if IsPedShooting(player_ped) then
                        local current_ammo_count = GetAmmoInPedWeapon(player_ped, weapon_hash)
                        
                        if last_ammo_count and last_ammo_count == current_ammo_count then
                            warns = warns + 1
                            if warns > 7 then
                                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Player tried to NoReload/infinite ammo", webhook, time)
                            end
                        end
    
                        last_ammo_count = current_ammo_count
                        last_weapon = weapon_hash
                    end
    
                    if last_weapon and GetAmmoInClip(player_ped, last_weapon) == 0 then
                        Citizen.Wait(2000)
    
                        local current_ammo_count = GetAmmoInPedWeapon(player_ped, last_weapon)
                        if last_ammo_count and last_ammo_count == current_ammo_count then
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Player tried to No Reload", webhook, time)
                        end
    
                        last_ammo_count = nil
                        last_weapon = nil
                    end
                else
                    last_ammo_count = nil
                    last_weapon = nil
                    warns = 0
                end
            end
        end
    end)
end

ProtectionManager.register_protection("no_reload", AntiNoReload.initialize)

return AntiNoReload 