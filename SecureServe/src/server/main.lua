local config_manager = require("server/core/config_manager")
local ban_manager = require("server/core/ban_manager")
local player_manager = require("server/core/player_manager")
local logger = require("server/core/logger")
local debug_module = require("server/core/debug_module")
local auto_config = require("server/core/auto_config")

local resource_manager = require("server/protections/resource_manager")
local anti_execution = require("server/protections/anti_execution")
local anti_entity_spam = require("server/protections/anti_entity_spam")
local anti_resource_injection = require("server/protections/anti_resource_injection")
local anti_weapon_damage_modifier = require("server/protections/anti_weapon_damage_modifier")
local anti_explosions = require("server/protections/anti_explosions")
local anti_particle_effects = require("server/protections/anti_particle_effects")

local initialized = false

local function setupErrorHandler()
    SecureServeErrorHandler = function(err)
        if type(err) ~= "string" then
            err = tostring(err)
        end
        
        local formattedError = "^1[ERROR] ^7" .. err
        print(formattedError)
        
        if debug_module and debug_module.handle_error then
            debug_module.handle_error(err, debug.traceback("", 2))
        end
    end
    
    AddEventHandler('onServerResourceStart', function(resource)
        if resource == GetCurrentResourceName() then
            local oldError = error
            error = function(err, level)
                if SecureServeErrorHandler then
                    SecureServeErrorHandler(err)
                end
                return oldError(err, level or 1)
            end
        end
    end)
end

local function registerServerCommands()
    RegisterCommand("secureban", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end
        
        if #args < 2 then
            print("^1[ERROR] Usage: secureban <player_id/name> <reason> [duration_in_minutes]^7")
            print("^1Example: secureban 5 \"Cheating\" 1440^7 (bans player ID 5 for 24 hours)")
            return
        end
        
        local target_id_or_name = args[1]
        local reason = args[2]
        local duration = tonumber(args[3]) or 0  
        
        local target_id = tonumber(target_id_or_name)
        if not target_id then
            for _, player_id in ipairs(GetPlayers()) do
                if GetPlayerName(tonumber(player_id)):lower():find(target_id_or_name:lower()) then
                    target_id = tonumber(player_id)
                    break
                end
            end
        end
        
        if not target_id then
            print("^1[ERROR] Player not found: " .. target_id_or_name .. "^7")
            return
        end
        
        local player_name = GetPlayerName(target_id)
        if not player_name then
            print("^1[ERROR] Player ID " .. target_id .. " not connected^7")
            return
        end
        
        local success = ban_manager.ban_player(target_id, reason, {
            admin = "Console",
            time = duration,
            detection = "Manual Ban"
        })
        
        if success then
            print("^2[SUCCESS] Banned player " .. player_name .. " (ID: " .. target_id .. ")^7")
            print("^2Reason: " .. reason .. "^7")
            print("^2Duration: " .. (duration > 0 and duration .. " minutes" or "Permanent") .. "^7")
        else
            print("^1[ERROR] Failed to ban player " .. target_id .. "^7")
        end
    end, true)
    
    RegisterCommand("secureunban", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end
        
        if #args < 1 then
            print("^1[ERROR] Usage: secureunban <identifier>^7")
            return
        end
        
        local identifier = args[1]
        local success = ban_manager.unban_player(identifier)
        
        if success then
            print("^2[SUCCESS] Unbanned player with identifier: " .. identifier .. "^7")
            logger.info("Unbanned player with identifier: " .. identifier)
        else
            print("^1[ERROR] Failed to unban player or player not found: " .. identifier .. "^7")
        end
    end, true)
    
    RegisterCommand("securebanlist", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end
        
        local count = 10
        if #args > 0 then
            count = tonumber(args[1]) or 10
        end
        
        local bans = ban_manager.get_recent_bans(count)
        
        print("^3===== SecureServe Ban List (" .. #bans .. " most recent) =====^7")
        for i, ban in ipairs(bans) do
            print(string.format("^3%d. ^7%s - Reason: %s - Date: %s", 
                i, 
                ban.identifier or "Unknown", 
                ban.reason or "No reason provided", 
                ban.timestamp and os.date("%Y-%m-%d %H:%M:%S", ban.timestamp) or "Unknown"
            ))
        end
        print("^3===================================================^7")
    end, true)
    
    RegisterCommand("securehelp", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end
        
        print("^3===== SecureServe Anti-Cheat Commands =====^7")
        print("^2secureban <player_id/name> <reason> [duration]^7 - Ban a player")
        print("^2secureunban <identifier>^7 - Unban a player by identifier")
        print("^2securebanlist [count]^7 - Show recent bans (default: 10)")
        print("^2securewhitelist event <event_name>^7 - Add event to whitelist")
        print("^2securewhitelist resource <resource_name>^7 - Add resource to whitelist")
        print("^2securedebug <on/off>^7 - Enable/disable debug mode")
        print("^2securedevmode <on/off>^7 - Enable/disable developer mode")
        print("^2securestats^7 - Show system statistics")
        print("^2securereload^7 - Reload configuration")
        print("^3===========================================^7")
    end, true)
    
    RegisterCommand("securewhitelist", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end
        
        if #args < 2 then
            print("^1[ERROR] Usage: securewhitelist <type> <name>^7")
            print("^1Types: event, resource^7")
            return
        end
        
        local type = args[1]
        local name = args[2]
        
        if type == "event" then
            local success = config_manager.whitelist_event(name)
            if success then
                print("^2[SUCCESS] Added event to whitelist: " .. name .. "^7")
                logger.info("Added event to whitelist: " .. name)
            else
                print("^1[ERROR] Failed to add event to whitelist or already whitelisted: " .. name .. "^7")
            end
        elseif type == "resource" then
            local success = anti_resource_injection.whitelist_resource(name)
            if success then
                print("^2[SUCCESS] Added resource to whitelist: " .. name .. "^7")
                logger.info("Added resource to whitelist: " .. name)
            else
                print("^1[ERROR] Failed to add resource to whitelist or already whitelisted: " .. name .. "^7")
            end
        else
            print("^1[ERROR] Invalid type. Use 'event' or 'resource'^7")
        end
    end, true)
    
    RegisterCommand("securedebug", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end
        
        if #args < 1 then
            print("^1[ERROR] Usage: securedebug <on/off>^7")
            return
        end
        
        local mode = args[1]:lower()
        if mode == "on" then
            debug_module.set_debug_mode(true)
            print("^2[SUCCESS] Debug mode enabled^7")
        elseif mode == "off" then
            debug_module.set_debug_mode(false)
            print("^2[SUCCESS] Debug mode disabled^7")
        else
            print("^1[ERROR] Invalid option. Use 'on' or 'off'^7")
        end
    end, true)
    
    RegisterCommand("securedevmode", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end
        
        if #args < 1 then
            print("^1[ERROR] Usage: securedevmode <on/off>^7")
            return
        end
        
        local mode = args[1]:lower()
        if mode == "on" then
            debug_module.set_dev_mode(true)
            print("^2[SUCCESS] Developer mode enabled^7")
        elseif mode == "off" then
            debug_module.set_dev_mode(false)
            print("^2[SUCCESS] Developer mode disabled^7")
        else
            print("^1[ERROR] Invalid option. Use 'on' or 'off'^7")
        end
    end, true)
    
    RegisterCommand("securestats", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end
        
        print("^3===== SecureServe System Statistics =====^7")
        
        local debug_stats = debug_module.get_error_stats()
        print("^2Debug:^7")
        print("  Total Errors: " .. debug_stats.total_errors)
        print("  Recent Errors: " .. debug_stats.recent_errors)
        print("  Debug Mode: " .. (debug_stats.debug_enabled and "Enabled" or "Disabled"))
        print("  Developer Mode: " .. (debug_stats.dev_mode and "Enabled" or "Disabled"))
        
        local ban_count = #ban_manager.get_all_bans()
        print("^2Bans:^7")
        print("  Total Bans: " .. ban_count)
        
        print("^2Players:^7")
        
        local player_count = 0
        if player_manager and player_manager.get_player_count then
            player_count = player_manager.get_player_count()
        else
            player_count = #GetPlayers()
        end
        
        print("  Active Players: " .. player_count)
        
        print("^3=======================================^7")
    end, true)
    
    RegisterCommand("securereload", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end
        
        config_manager.initialize()
        print("^2[SUCCESS] Configuration reloaded^7")
        logger.info("Configuration reloaded via console command")
    end, true)
    
    logger.info("Server console commands registered")
end

local function main()
    if initialized then
        return
    end
    
    setupErrorHandler()
    
    print([[^8
  /$$$$$$                                                /$$$$$$                                        
 /$$__  $$                                              /$$__  $$                                       
| $$  \__/  /$$$$$$   /$$$$$$$ /$$   /$$  /$$$$$$     | $$  \__/  /$$$$$$   /$$$$$$  /$$    /$$ /$$$$$$
|  $$$$$$  /$$__  $$ /$$_____/| $$  | $$ /$$__  $$    |  $$$$$$  /$$__  $$ /$$__  $$|  $$  /$$//$$__  $$
 \____  $$| $$$$$$$$| $$      | $$  | $$| $$  \__/     \____  $$| $$$$$$$$| $$  \__/ \  $$/$$/| $$$$$$$$
 /$$  \ $$| $$_____/| $$      | $$  | $$| $$           /$$  \ $$| $$_____/| $$        \  $$$/ | $$_____/
|  $$$$$$/|  $$$$$$$|  $$$$$$$|  $$$$$$/| $$          |  $$$$$$/|  $$$$$$$| $$         \  $/  |  $$$$$$$
 \______/  \_______/ \_______/ \______/ |__/           \______/  \_______/|__/          \_/    \_______/
                                                                                                         
^7]])
    
    print("^8╔══════════════════════════════════════════════════════════════════════════╗^7")
    print("^8║                  ^2SecureServe AntiCheat v1.2.0 Initializing^8               ║^7")
    print("^8╚══════════════════════════════════════════════════════════════════════════╝^7")
    
    print("\n^2╭─── Core Modules ^7")
    
    print("^2│ ^5⏳^7 Config Manager^7")
    config_manager.initialize()
    print("^2│ ^2✓^7 Config Manager^7 initialized")
    
    print("^2│ ^5⏳^7 Logger^7")
    logger.initialize(SecureServe)
    print("^2│ ^2✓^7 Logger^7 initialized")
    
    print("^2│ ^5⏳^7 Debug Module^7")
    debug_module.initialize(SecureServe)
    print("^2│ ^2✓^7 Debug Module^7 initialized")
    
    print("^2│ ^5⏳^7 Ban Manager^7")
    ban_manager.initialize()
    print("^2│ ^2✓^7 Ban Manager^7 initialized")
    
    print("^2│ ^5⏳^7 Player Manager^7")
    player_manager.initialize()
    print("^2│ ^2✓^7 Player Manager^7 initialized")
    
    print("^2│ ^5⏳^7 Auto Config^7")
    auto_config.initialize()
    print("^2│ ^2✓^7 Auto Config^7 initialized")
    print("^2╰───────────────^7")
    
    print("\n^3╭─── Protection Modules ^7")
    
    print("^3│ ^5⏳^7 Resource Manager^7")
    resource_manager.initialize()
    print("^3│ ^2✓^7 Resource Manager^7 initialized")
    
    print("^3│ ^5⏳^7 Anti Execution^7")
    anti_execution.initialize()
    print("^3│ ^2✓^7 Anti Execution^7 initialized")
    
    print("^3│ ^5⏳^7 Anti Entity Spam^7")
    anti_entity_spam.initialize()
    print("^3│ ^2✓^7 Anti Entity Spam^7 initialized")
    
    print("^3│ ^5⏳^7 Anti Resource Injection^7")
    anti_resource_injection.initialize()
    print("^3│ ^2✓^7 Anti Resource Injection^7 initialized")
    
    print("^3│ ^5⏳^7 Anti Weapon Damage Modifier^7")
    anti_weapon_damage_modifier.initialize()
    print("^3│ ^2✓^7 Anti Weapon Damage Modifier^7 initialized")
    
    print("^3│ ^5⏳^7 Anti Explosions^7")
    anti_explosions.initialize()
    print("^3│ ^2✓^7 Anti Explosions^7 initialized")
    
    print("^3│ ^5⏳^7 Anti Particle Effects^7")
    anti_particle_effects.initialize()
    print("^3│ ^2✓^7 Anti Particle Effects^7 initialized")
    print("^3╰───────────────^7")
    
    registerServerCommands()
    
    AddEventHandler("onResourceStop", function(resource_name)
        if resource_name == GetCurrentResourceName() then
            logger.info("SecureServe AntiCheat is stopping...")
            print("^1SecureServe AntiCheat is stopping...^7")
        end
    end)
    
    AddEventHandler("playerBanned", function(player_id, reason, admin_id)
        logger.log_ban(player_id, reason, admin_id)
    end)
    
    AddEventHandler("eventTriggered", function(event_name, source, ...)
        if SecureServe.AutoConfig and auto_config and auto_config.process_auto_whitelist then
            auto_config.process_auto_whitelist(source, "Event triggered: " .. event_name, nil, nil)
        end
        
        if event_name and SecureServe.SafeEvents then
            local safe_events = SecureServe.SafeEvents
            if type(safe_events) == "table" and #safe_events > 0 then
                for _, safe_event in ipairs(safe_events) do
                    if safe_event == event_name then
                        return
                    end
                end
            end
        end
    end)
    
    AddEventHandler("resourceStarted", function(resource_name)
        local resource_to_check = resource_name
        if resource_to_check and SecureServe.SafeResources then
            local safe_resources = SecureServe.SafeResources
            if type(safe_resources) == "table" and #safe_resources > 0 then
                for _, safe_resource in ipairs(safe_resources) do
                    if safe_resource == resource_to_check then
                        return
                    end
                end
            end
        end
    end)
    
    initialized = true
    
    print("\n^8╔══════════════════════════════════════════════════════════════════════════╗^7")
    print("^8║              ^2SecureServe AntiCheat v1.2.0 Loaded Successfully^8            ║^7")
    print("^8║                 ^3All Modules Initialized and Protection Active^8            ║^7")
    print("^8╚══════════════════════════════════════════════════════════════════════════╝^7")
    print("^6⚡ Support: ^3https://discord.gg/z6qGGtbcr4^7")
    print("^6⚡ Type ^3securehelp ^6in server console for commands^7")
    
    logger.info("SecureServe AntiCheat v1.2.0 initialized successfully")
end

CreateThread(function()
    Wait(1000)
    main()
end)

exports("get_ban_manager", function()
    return ban_manager
end)

exports("get_config_manager", function()
    return config_manager
end)

exports("get_player_manager", function()
    return player_manager
end)

exports("get_logger", function()
    return logger
end)

exports("get_debug_module", function()
    return debug_module
end)

exports("get_auto_config", function()
    return auto_config
end)

exports("is_player_banned", function(identifier)
    return ban_manager.is_banned(identifier)
end)

exports("whitelist_resource", function(resource_name)
    return anti_resource_injection.whitelist_resource(resource_name)
end)

exports("whitelist_explosion", function(source, explosion_type)
    return anti_explosions.whitelist_explosion(source, explosion_type)
end)

exports("ban_player", function(source, reason, details)
    return ban_manager.ban_player(source, reason, details)
end)

exports("whitelist_event", function(event_name)
    if config_manager and config_manager.whitelist_event then
        return config_manager.whitelist_event(event_name)
    end
    return false
end)

exports("validate_event", function(source, event_name, resource_name, webhook)
    if auto_config and auto_config.validate_event then
        return auto_config.validate_event(source, event_name, resource_name, webhook)
    end
    return false
end)

exports("module_punish", function(source, reason, webhook, time)
    if not source or not reason then
        logger.error("module_punish called with invalid parameters")
        return false
    end
    
    if not tonumber(source) or tonumber(source) <= 0 then
        logger.error("Invalid source in module_punish: " .. tostring(source))
        return false
    end
    
    local event_name, resource_name
    
    event_name, resource_name = reason:match("Tried triggering a restricted event: ([^%s]+)[%s]?in resource: ([^%s]+)")
    
    if not event_name then
        event_name = reason:match("Triggered an event without proper registration: ([^%s]+)")
    end
    
    if not event_name then
        event_name = reason:match("Unauthorized network event: ([^%s]+)")
    end
    
    local entity_resource = reason:match("Created Suspicious Entity %[.+%] at script: ([^%s]+)")
    if not entity_resource and not resource_name then
        entity_resource = reason:match("Illegal entity created by resource: ([^%s]+)")
    end
    if not entity_resource and not resource_name then
        entity_resource = reason:match("Entity spam detected from resource: ([^%s]+)")
    end
    
    logger.debug("Extracted from ban reason - Event: " .. (event_name or "none") .. 
                 ", Resource: " .. (resource_name or "none") .. 
                 ", Entity Resource: " .. (entity_resource or "none"))
    
    if event_name then
        if auto_config and auto_config.fx_events and auto_config.fx_events[event_name] then
            logger.debug("Event " .. event_name .. " is a native FiveM event, ignoring detection")
            return true
        end
        
        if config_manager.is_event_whitelisted(event_name) then
            logger.debug("Event " .. event_name .. " is whitelisted in config, ignoring detection")
            return true
        end
    end
    
    local resource_to_check = resource_name or entity_resource
    
    if resource_to_check then
        if resource_to_check == GetCurrentResourceName() then
            logger.debug("Detection from SecureServe itself, ignoring")
            return true
        end
        
        if anti_resource_injection and anti_resource_injection.is_resource_whitelisted then
            if anti_resource_injection.is_resource_whitelisted(resource_to_check) then
                logger.debug("Resource " .. resource_to_check .. " is whitelisted, ignoring detection")
                return true
            end
        end
        
        if entity_resource and auto_config and auto_config.is_entity_resource_whitelisted then
            if auto_config.is_entity_resource_whitelisted(entity_resource) then
                logger.debug("Resource " .. entity_resource .. " is whitelisted for entities, ignoring detection")
                return true
            end
        end
    end
    
    if config_manager.get("AutoConfig") and auto_config and auto_config.process_auto_whitelist then
        local handled = auto_config.process_auto_whitelist(source, reason, webhook, time)
        if handled then
            logger.info("Auto-config handled detection: " .. reason)
            return true
        end
    end
    
    if event_name and config_manager.get("SafeEvents") then
        local safe_events = config_manager.get("SafeEvents")
        if type(safe_events) == "table" then
            for _, safe_event in ipairs(safe_events) do
                if safe_event == event_name then
                    logger.debug("Event " .. event_name .. " is in SafeEvents list, ignoring detection")
                    return true
                end
            end
        end
    end
    
    if resource_to_check and config_manager.get("SafeResources") then
        local safe_resources = config_manager.get("SafeResources")
        if type(safe_resources) == "table" then
            for _, safe_resource in ipairs(safe_resources) do
                if safe_resource == resource_to_check then
                    logger.debug("Resource " .. resource_to_check .. " is in SafeResources list, ignoring detection")
                    return true
                end
            end
        end
    end
    
    logger.info("Ban reason not matching any whitelist, proceeding with ban: " .. reason)
    time = tonumber(time) or 0 
    return ban_manager.ban_player(source, reason, {
        detection = "Module Protection",
        time = time,
        webhook = webhook
    })
end)

SecureBan = function(source, reason, details)
    return ban_manager.ban_player(source, reason, details)
end

SecureLog = function(level, message, ...)
    if logger then
        if level == "debug" then
            return logger.debug(message, ...)
        elseif level == "info" then
            return logger.info(message, ...)
        elseif level == "warn" then
            return logger.warn(message, ...)
        elseif level == "error" then
            return logger.error(message, ...)
        elseif level == "fatal" then
            return logger.fatal(message, ...)
        end
    end
end

RegisterNetEvent("SecureServe:KickBannedPlayer", function(target)
    if not target or tonumber(target) <= 0 then
        return
    end
    
    local name = GetPlayerName(target)
    if not name then
        return
    end
    
    local identifiers = ban_manager.get_player_identifiers(target)
    local is_banned, ban_data = ban_manager.check_ban(identifiers)
    
    if is_banned and ban_data then
        DropPlayer(target, ban_manager.format_ban_message(ban_data))
    else
        DropPlayer(target, "You have been banned from this server.")
    end
end)

RegisterNetEvent("SecureServe:DisconnectMe", function()
    local source = source
    if not source or source <= 0 then
        return
    end
    
    local identifiers = ban_manager.get_player_identifiers(source)
    local is_banned, ban_data = ban_manager.check_ban(identifiers)
    
    if is_banned and ban_data then
        DropPlayer(source, ban_manager.format_ban_message(ban_data))
    else
        DropPlayer(source, "You have been disconnected from the server.")
    end
end)

RegisterNetEvent("SecureServe:Server:Methods:PunishPlayer", function(target_id, reason, webhook, time)
    local src = source
    
    target_id = target_id or src
    
    if not target_id or target_id <= 0 then
        logger.error("Invalid target ID in PunishPlayer event: " .. tostring(target_id))
        return
    end
    
    ban_manager.ban_player(target_id, reason, webhook, time)
end)

RegisterNetEvent("check_trigger_list", function(source, event_name, resource_name)
    if not source or not event_name or not resource_name then
        return
    end
    
    if auto_config and auto_config.validate_event then
        local is_valid = auto_config.validate_event(source, event_name, resource_name)
        
        if not is_valid then
            local reason = "Tried triggering a restricted event: " .. event_name .. " in resource: " .. resource_name
            exports[GetCurrentResourceName()].module_punish(source, reason)
        end
    end
end) 