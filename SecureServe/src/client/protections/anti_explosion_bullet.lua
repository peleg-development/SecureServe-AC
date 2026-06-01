local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiExplosionBullet = {}

-- Weapons that legitimately have damage_type 4 (explosive) or 5 (fire).
-- If the current weapon is in this set, damage_type 4/5 is NORMAL.
local LEGIT_EXPLOSIVE_WEAPONS = {
    [GetHashKey("WEAPON_RPG")]                = true,
    [GetHashKey("WEAPON_HOMINGLAUNCHER")]     = true,
    [GetHashKey("WEAPON_GRENADELAUNCHER")]    = true,
    [GetHashKey("WEAPON_GRENADELAUNCHER_SMOKE")] = true,
    [GetHashKey("WEAPON_COMPACTLAUNCHER")]    = true,
    [GetHashKey("WEAPON_GRENADE")]            = true,
    [GetHashKey("WEAPON_STICKYBOMB")]         = true,
    [GetHashKey("WEAPON_PROXMINE")]           = true,
    [GetHashKey("WEAPON_PIPEBOMB")]           = true,
    [GetHashKey("WEAPON_MOLOTOV")]            = true,
    [GetHashKey("WEAPON_FIREWORK")]           = true,
    [GetHashKey("WEAPON_FLAREGUN")]           = true,
    [GetHashKey("WEAPON_FLARE")]              = true,
    [GetHashKey("WEAPON_PETROLCAN")]          = true,
    [GetHashKey("WEAPON_FIREEXTINGUISHER")]   = true,
    [GetHashKey("WEAPON_RAILGUN")]            = true,
    [GetHashKey("WEAPON_MINIGUN")]            = true,
    [GetHashKey("WEAPON_RAYMINIGUN")]         = true,
}

function AntiExplosionBullet.initialize()
    if not ConfigLoader.get_protection_setting("Anti Explosion Bullet", "enabled") then
        return
    end

    Citizen.CreateThread(function()
        local strikes = 0
        local STRIKE_LIMIT = tonumber(ConfigLoader.get_protection_setting("Anti Explosion Bullet", "strike_limit")) or 3
        local INTERVAL     = tonumber(ConfigLoader.get_protection_setting("Anti Explosion Bullet", "check_interval_ms")) or 1500

        while true do
            Citizen.Wait(INTERVAL)

            if Cache.Get("hasPermission", "explosionbullet")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                strikes = 0
                goto continue
            end

            local weapon = Cache.Get("selectedWeapon")
            if not weapon or weapon == 0 or weapon == GetHashKey("WEAPON_UNARMED") then
                if strikes > 0 then strikes = strikes - 1 end
                goto continue
            end

            -- If the weapon legitimately fires explosive/fire ammo, skip.
            if LEGIT_EXPLOSIVE_WEAPONS[weapon] then
                if strikes > 0 then strikes = strikes - 1 end
                goto continue
            end

            local damage_type = GetWeaponDamageType(weapon)
            -- 4 = explosive, 5 = fire. Suspicious only for normal bullet weapons.
            if damage_type == 4 or damage_type == 5 then
                strikes = strikes + 1
                if strikes >= STRIKE_LIMIT then
                    strikes = 0
                    ProtectionHelper.punish("Anti Explosion Bullet",
                        ("Explosive ammo on non-launcher weapon (hash=%s, dmg_type=%d)")
                            :format(tostring(weapon), damage_type))
                end
            else
                if strikes > 0 then strikes = strikes - 1 end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("explosion_bullet", AntiExplosionBullet.initialize)
return AntiExplosionBullet
