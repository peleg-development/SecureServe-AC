fx_version "cerulean"
game "gta5"

author "SecureServe.net"
version "1.5.0"

files {
    "bans.json",
    "src/panel/ingame/html/index.html",
    "src/panel/ingame/html/styles.css",
    "src/panel/ingame/html/app.js",
    "secureserve.key"
}

ui_page "src/panel/ingame/html/index.html"

shared_scripts {
    "src/module/module.lua",
    "src/shared/lib/require.lua",
    "src/shared/lib/utils.lua",
    "src/shared/lib/callbacks.lua",
    "src/shared/init.lua",
}

client_scripts {
    "src/client/init.lua",
    "src/client/core/config_loader.lua",
    "src/client/core/perms.lua",
    "src/client/core/cache.lua",
    "src/client/core/client_logger.lua",
    "src/client/core/blue_screen.lua",
    "src/client/protections/protection_manager.lua",
    "src/client/protections/anti_load_resource_file.lua",
    "src/client/protections/anti_invisible.lua",
    "src/client/protections/anti_no_reload.lua",
    "src/client/protections/anti_explosion_bullet.lua",
    "src/client/protections/anti_entity_security.lua",
    "src/client/protections/anti_magic_bullet.lua",
    "src/client/protections/anti_aim_assist.lua",
    "src/client/protections/anti_noclip.lua",
    "src/client/protections/anti_resource_stop.lua",
    "src/client/protections/anti_god_mode.lua",
    "src/client/protections/anti_spectate.lua",
    "src/client/protections/anti_give_weapon.lua",
    "src/client/protections/anti_freecam.lua",
    "src/client/protections/anti_teleport.lua",
    "src/client/protections/anti_weapon_damage_modifier.lua",
    "src/client/protections/anti_ocr.lua",
    "src/client/protections/anti_player_blips.lua",
    "src/client/protections/anti_speed_hack.lua",
    "src/client/protections/anti_state_bag_overflow.lua",
    "src/client/protections/anti_afk_injection.lua",
    "src/client/protections/anti_ai.lua",
    "src/client/protections/anti_bigger_hitbox.lua",
    "src/client/protections/anti_no_recoil.lua",
    "src/client/protections/anti_visions.lua",
    "src/client/protections/anti_weapon_pickup.lua",
    "src/client/main.lua",
    "src/panel/ingame/client.lua"
}
server_scripts {
    "src/server/core/version.lua",
    "config.lua",
    "src/server/main.lua",
    "src/server/core/config_manager.lua",
    "src/server/core/ban_manager.lua",
    "src/server/core/logger.lua",
    "src/server/core/debug_module.lua",
    "src/server/core/discord_logger.lua",
    "src/server/core/perms.lua",
    "src/server/core/admin_whitelist.lua",
    "src/server/protections/resource_manager.lua", 
    "src/server/protections/anti_execution.lua",
    "src/server/protections/anti_entity_spam.lua",
    "src/server/protections/anti_resource_injection.lua",
    "src/server/protections/anti_weapon_damage_modifier.lua",
    "src/server/protections/anti_explosions.lua",
    "src/server/protections/anti_particle_effects.lua",
    "src/server/protections/heartbeat.lua",
    "src/server/core/install.js",
    "src/panel/ingame/server.lua"
}

dependencies {
    "/server:5181",
    "screencapture",
    "keep-alive"
}

lua54 "yes"

server_exports {
    "module_punish"
}