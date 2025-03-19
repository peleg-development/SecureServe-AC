---@class AntiWeaponDamageModifierModule
local AntiWeaponDamageModifier = {}

local ban_manager = require("server/core/ban_manager")

local weapon_damage_history = {}
local weapon_damage_baseline = {}

---@description Initialize anti-weapon damage modifier protection
function AntiWeaponDamageModifier.initialize()
    AddEventHandler("weaponDamageEvent", function(sender, data)
        if not sender or sender == 0 then
            return
        end
        
        local weapon_hash = data.weaponType
        local damage = data.weaponDamage
        local is_headshot = data.isHeadshot or false
        
        if not weapon_damage_history[sender] then
            weapon_damage_history[sender] = {}
        end
        
        if not weapon_damage_history[sender][weapon_hash] then
            weapon_damage_history[sender][weapon_hash] = {}
        end
        
        table.insert(weapon_damage_history[sender][weapon_hash], damage)
        
        if #weapon_damage_history[sender][weapon_hash] > 10 then
            table.remove(weapon_damage_history[sender][weapon_hash], 1)
        end
        
        if not weapon_damage_baseline[weapon_hash] or damage > weapon_damage_baseline[weapon_hash] then
            weapon_damage_baseline[weapon_hash] = damage
        end
        
        if #weapon_damage_history[sender][weapon_hash] >= 3 then
            local min_damage = 999999
            local max_damage = 0
            
            for _, dmg in ipairs(weapon_damage_history[sender][weapon_hash]) do
                if dmg < min_damage then
                    min_damage = dmg
                end
                
                if dmg > max_damage then
                    max_damage = dmg
                end
            end
            
            local max_normal_damage = weapon_damage_baseline[weapon_hash] or max_damage
            local allowed_overhead = is_headshot and 2.0 or 1.5 
            
            if max_damage > max_normal_damage * allowed_overhead then
                ban_manager.ban_player(sender, "Weapon Damage Modifier", "Abnormal weapon damage: " .. max_damage .. " (expected max: " .. max_normal_damage .. ")")
                return
            end
            
            local damage_ratio = max_damage / (min_damage > 0 and min_damage or 1)
            
            if damage_ratio > 5.0 then
                ban_manager.ban_player(sender, "Weapon Damage Modifier", "Inconsistent weapon damage: ratio " .. damage_ratio)
                return
            end
        end
    end)
end

---@param player_id number The player ID to clear history for
function AntiWeaponDamageModifier.clear_player_history(player_id)
    weapon_damage_history[player_id] = nil
end

return AntiWeaponDamageModifier
