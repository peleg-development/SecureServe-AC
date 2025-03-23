---@class AntiWeaponDamageModifierModule
local AntiWeaponDamageModifier = {
    weapon_damage_history = {},
    weapon_damage_baseline = {}
}

local ban_manager = require("server/core/ban_manager")

---@description Initialize anti-weapon damage modifier protection
function AntiWeaponDamageModifier.initialize()
    AddEventHandler("weaponDamageEvent", function(sender, data)
        if not sender or sender == 0 then
            return
        end
        
        local weapon_hash = data.weaponType
        local damage = data.weaponDamage
        local is_headshot = data.isHeadshot or false
        
        if not AntiWeaponDamageModifier.weapon_damage_history[sender] then
            AntiWeaponDamageModifier.weapon_damage_history[sender] = {}
        end
        
        if not AntiWeaponDamageModifier.weapon_damage_history[sender][weapon_hash] then
            AntiWeaponDamageModifier.weapon_damage_history[sender][weapon_hash] = {}
        end
        
        table.insert(AntiWeaponDamageModifier.weapon_damage_history[sender][weapon_hash], damage)
        
        if #AntiWeaponDamageModifier.weapon_damage_history[sender][weapon_hash] > 10 then
            table.remove(AntiWeaponDamageModifier.weapon_damage_history[sender][weapon_hash], 1)
        end
        
        if not AntiWeaponDamageModifier.weapon_damage_baseline[weapon_hash] or damage > AntiWeaponDamageModifier.weapon_damage_baseline[weapon_hash] then
            AntiWeaponDamageModifier.weapon_damage_baseline[weapon_hash] = damage
        end
        
        if #AntiWeaponDamageModifier.weapon_damage_history[sender][weapon_hash] >= 3 then
            local min_damage = 999999
            local max_damage = 0
            
            for _, dmg in ipairs(AntiWeaponDamageModifier.weapon_damage_history[sender][weapon_hash]) do
                if dmg < min_damage then
                    min_damage = dmg
                end
                
                if dmg > max_damage then
                    max_damage = dmg
                end
            end
            
            local max_normal_damage = AntiWeaponDamageModifier.weapon_damage_baseline[weapon_hash] or max_damage
            local allowed_overhead = is_headshot and 2.0 or 1.5 
            
            if max_damage > max_normal_damage * allowed_overhead then
                ban_manager.ban_player(sender, "Weapon Damage Modifier", "Abnormal weapon damage: " .. max_damage .. " (expected max: " .. max_normal_damage .. ")")
                return
            end
        end
    end)
end

---@param player_id number The player ID to clear history for
function AntiWeaponDamageModifier.clear_player_history(player_id)
    AntiWeaponDamageModifier.weapon_damage_history[player_id] = nil
end

return AntiWeaponDamageModifier
