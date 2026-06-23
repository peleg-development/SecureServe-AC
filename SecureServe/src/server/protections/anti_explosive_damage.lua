-- Fix: dead module (empty initialize(), never required or initialized in main.lua) and redundant with anti_weapon_damage_modifier which already caps damage via weaponDamageEvent. Kept as a no-op stub.
---@class AntiExplosiveDamageModule
local AntiExplosiveDamage = {}

function AntiExplosiveDamage.initialize()
    return
end

return AntiExplosiveDamage
