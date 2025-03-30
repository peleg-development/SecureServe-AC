local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiExplosionBulletModule
local AntiExplosionBullet = {}

---@description Initialize Anti Explosion Bullet protection
function AntiExplosionBullet.initialize()
    if not ConfigLoader.get_protection_setting("Anti Explosion Bullet", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2500)
            local weapon = Cache.Get("selectedWeapon")
            local damage_type = GetWeaponDamageType(weapon)
            SetWeaponDamageModifier(GetHashKey("WEAPON_EXPLOSION"), 0.0)
            if damage_type == 4 or damage_type == 5 then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Explosive ammo", webhook, time)
            end
        end
    end)
end

ProtectionManager.register_protection("explosion_bullet", AntiExplosionBullet.initialize)

return AntiExplosionBullet