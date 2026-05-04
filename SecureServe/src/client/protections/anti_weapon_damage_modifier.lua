local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiWeaponDamageModifier = {}

function AntiWeaponDamageModifier.initialize()
    if not ConfigLoader.get_protection_setting("Anti Weapon Damage Modifier", "enabled") then return end

    local suspiciousModifiers = 0

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000)

            if Cache.Get("hasPermission", "weapondamage")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                suspiciousModifiers = 0
                goto continue
            end

            local currentWeapon = Cache.Get("selectedWeapon")
            if not currentWeapon or currentWeapon == GetHashKey("WEAPON_UNARMED") then
                goto continue
            end

            local modifier = GetWeaponDamageModifier(currentWeapon)
            if modifier and modifier > 1.5 then
                suspiciousModifiers = suspiciousModifiers + 1

                if suspiciousModifiers >= 3 then
                    SetWeaponDamageModifier(currentWeapon, 1.0)
                    ProtectionHelper.punish('Anti Weapon Damage Modifier',
                        ("Weapon damage modifier detected: %.2f"):format(modifier))
                    suspiciousModifiers = 0
                end
            else
                if suspiciousModifiers > 0 then
                    suspiciousModifiers = suspiciousModifiers - 1
                end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("weapon_damage_modifier", AntiWeaponDamageModifier.initialize)

return AntiWeaponDamageModifier
