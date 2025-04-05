local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiWeaponDamageModifierModule
local AntiWeaponDamageModifier = {}

---@description Initialize Anti Weapon Damage Modifier protection
function AntiWeaponDamageModifier.initialize()
    if not ConfigLoader.get_protection_setting("Anti Weapon Damage Modifier", "enabled") then return end
    
    local lastCheckedWeapon = nil
    local suspiciousModifiers = 0
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000)
            
            if not Cache.Get("isAdmin") then
                local currentWeapon = Cache.Get("selectedWeapon")
                
                if currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
                    if Citizen.InvokeNative(0x4757f00bc6323cfe, currentWeapon, 1.0) > 1.5 then
                        suspiciousModifiers = suspiciousModifiers + 1
                        
                        if suspiciousModifiers >= 3 then
                            local damage = Citizen.InvokeNative(0x4757f00bc6323cfe, currentWeapon, 1.0)
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                                "Weapon damage modifier detected: " .. damage, 
                                webhook, 
                                time)
                            
                            N_0x4757f00bc6323cfe(currentWeapon, 1.0)
                            suspiciousModifiers = 0
                        end
                    else
                        if suspiciousModifiers > 0 then
                            suspiciousModifiers = suspiciousModifiers - 1
                        end
                    end
                end
                
                lastCheckedWeapon = currentWeapon
            end
        end
    end)
end

ProtectionManager.register_protection("weapon_damage_modifier", AntiWeaponDamageModifier.initialize)

return AntiWeaponDamageModifier 