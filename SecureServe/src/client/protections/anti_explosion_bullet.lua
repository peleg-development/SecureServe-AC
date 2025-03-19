local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiExplosionBulletModule
local AntiExplosionBullet = {}

---@description Initialize Anti Explosion Bullet protection
function AntiExplosionBullet.initialize()
    if not Anti_Explosion_Bullet_enabled then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2500)
            local weapon = Cache.Get("selectedWeapon")
            local damage_type = GetWeaponDamageType(weapon)
            SetWeaponDamageModifier(GetHashKey("WEAPON_EXPLOSION"), 0.0)
            if damage_type == 4 or damage_type == 5 then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Explosive ammo", Anti_Explosion_Bullet_webhook, Anti_Explosion_Bullet_time)
            end
        end
    end)
end

ProtectionManager.register_protection("explosion_bullet", AntiExplosionBullet.initialize)

return AntiExplosionBullet 