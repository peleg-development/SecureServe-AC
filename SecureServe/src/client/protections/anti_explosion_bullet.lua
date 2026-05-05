local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiExplosionBullet = {}

function AntiExplosionBullet.initialize()
    if not ConfigLoader.get_protection_setting("Anti Explosion Bullet", "enabled") then
        return
    end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1500)

            if Cache.Get("hasPermission", "explosionbullet")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                goto continue
            end

            local weapon = Cache.Get("selectedWeapon")
            if weapon and weapon ~= 0 then
                local damage_type = GetWeaponDamageType(weapon)
                if damage_type == 4 or damage_type == 5 then
                    ProtectionHelper.punish("Anti Explosion Bullet", "Explosive ammo")
                end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("explosion_bullet", AntiExplosionBullet.initialize)
return AntiExplosionBullet
