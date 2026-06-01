local AntiWeaponDamageModifier = {
    weapon_damage_history = {},
}

local ban_manager    = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

local SAMPLES_BEFORE_DECISION = 3
local HISTORY_CAP             = 10

function AntiWeaponDamageModifier.initialize()
    AddEventHandler("weaponDamageEvent", function(sender, data)
        if not sender or sender == 0 then return end

        local weapon_hash = data.weaponType
        if not weapon_hash then return end

        local baseline = config_manager.get_weapon_max_damage(weapon_hash)
        if not baseline then return end

        local damage     = data.weaponDamage or 0
        local is_headshot = data.isHeadshot == true

        local hist = AntiWeaponDamageModifier.weapon_damage_history[sender]
        if not hist then
            hist = {}
            AntiWeaponDamageModifier.weapon_damage_history[sender] = hist
        end
        local entries = hist[weapon_hash]
        if not entries then
            entries = {}
            hist[weapon_hash] = entries
        end

        entries[#entries + 1] = damage
        if #entries > HISTORY_CAP then
            table.remove(entries, 1)
        end

        if #entries < SAMPLES_BEFORE_DECISION then return end

        local max_damage = 0
        for _, dmg in ipairs(entries) do
            if dmg > max_damage then max_damage = dmg end
        end

        local allowed_overhead = is_headshot and 2.0 or 1.5
        if max_damage > baseline * allowed_overhead then
            ban_manager.ban_player(sender, "Weapon Damage Modifier", {
                admin     = "Anti-Cheat System",
                time      = 2147483647,
                detection = ("Abnormal weapon damage: %s (baseline %s)"):format(max_damage, baseline),
            })
        end
    end)

    AddEventHandler("playerDropped", function()
        local src = source
        if src then
            AntiWeaponDamageModifier.weapon_damage_history[src] = nil
        end
    end)
end

function AntiWeaponDamageModifier.clear_player_history(player_id)
    AntiWeaponDamageModifier.weapon_damage_history[player_id] = nil
end

return AntiWeaponDamageModifier
