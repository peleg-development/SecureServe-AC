local config_manager = require("server/core/config_manager")
local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")
local debug_module = require("server/core/debug_module")
local admin_whitelist = require("server/core/admin_whitelist")

local resource_manager = require("server/protections/resource_manager")
local anti_execution = require("server/protections/anti_execution")
local anti_entity_spam = require("server/protections/anti_entity_spam")
local anti_create_entity = require("server/protections/anti_create_entity")
local anti_resource_injection = require("server/protections/anti_resource_injection")
local anti_weapon_damage_modifier = require("server/protections/anti_weapon_damage_modifier")
local anti_explosions = require("server/protections/anti_explosions")
local anti_particle_effects = require("server/protections/anti_particle_effects")
local heartbeat = require("server/protections/heartbeat")

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
            print("Usage: secureban <player_id/name> <reason> [duration_in_minutes]")
            print("Example: secureban 5 \"Cheating\" 1440 (bans player ID 5 for 24 hours)")
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
            print("Player not found: " .. target_id_or_name)
            return
        end

        local player_name = GetPlayerName(target_id)
        if not player_name then
            print("Player ID " .. target_id .. " not connected")
            return
        end

        local success = ban_manager.ban_player(target_id, reason, {
            admin = "Console",
            time = duration,
            detection = "Manual Ban"
        })

        if success then
            logger.info("Banned player " .. player_name .. " (ID: " .. target_id .. ")")
            logger.info("Reason: " .. reason)
            logger.info("Duration: " .. (duration > 0 and duration .. " minutes" or "Permanent"))

            DiscordLogger.log_admin(0, "Ban", player_name, {
                ["Player ID"] = target_id,
                ["Reason"] = reason,
                ["Duration"] = (duration > 0 and duration .. " minutes" or "Permanent")
            })
        else
            print("Failed to ban player " .. target_id)
        end
    end, true)

    RegisterCommand("secureunban", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end

        if #args < 1 then
            print("Usage: secureunban <identifier>")
            return
        end

        local identifier = args[1]
        local success = ban_manager.unban_player(identifier)

        if success then
            print("Unbanned player with identifier: " .. identifier)
            DiscordLogger.log_admin(0, "Unban", identifier)
        else
            print("Failed to unban player or player not found: " .. identifier)
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

        print("===== SecureServe Ban List (" .. #bans .. " most recent) =====")
        for i, ban in ipairs(bans) do
            print(string.format("%d. %s - Reason: %s - Date: %s",
                i,
                ban.identifier or "Unknown",
                ban.reason or "No reason provided",
                ban.timestamp and os.date("%Y-%m-%d %H:%M:%S", ban.timestamp) or "Unknown"
            ))
        end
        print("===================================================")
    end, true)

    RegisterCommand("securehelp", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end

        print("===== SecureServe Anti-Cheat Commands =====")
        print("secureban <player_id/name> <reason> [duration] - Ban a player")
        print("secureunban <identifier> - Unban a player by identifier")
        print("securebanlist [count] - Show recent bans (default: 10)")
        print("securewhitelist event <event_name> - Add event to whitelist")
        print("securewhitelist resource <resource_name> - Add resource to whitelist")
        print("securedebug <on/off> - Enable/disable debug mode")
        print("securedevmode <on/off> - Enable/disable developer mode")
        print("securestats - Show system statistics")
        print("securereload - Reload configuration")
        print("===========================================")
    end, true)

    RegisterCommand("securewhitelist", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end

        if #args < 2 then
            print("Usage: securewhitelist <type> <n>")
            print("Types: event, resource")
            return
        end

        local type = args[1]
        local name = args[2]

        if type == "event" then
            local success = config_manager.whitelist_event(name)
            if success then
                print("Added event to whitelist: " .. name)
                DiscordLogger.log_admin(0, "Whitelist Event", name)
            else
                print("Failed to add event to whitelist or already whitelisted: " .. name)
            end
        elseif type == "resource" then
            local success = anti_resource_injection.whitelist_resource(name)
            if success then
                print("Added resource to whitelist: " .. name)
                DiscordLogger.log_admin(0, "Whitelist Resource", name)
            else
                print("Failed to add resource to whitelist or already whitelisted: " .. name)
            end
        else
            print("Invalid type. Use 'event' or 'resource'")
        end
    end, true)

    RegisterCommand("securedebug", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end

        if #args < 1 then
            print("Usage: securedebug <on/off>")
            return
        end

        local mode = args[1]:lower()
        if mode == "on" then
            config_manager.set_debug_mode(true)
            logger.set_debug_mode(true)
            print("Debug mode enabled")
            DiscordLogger.log_admin(0, "Set Debug Mode", "Enabled")
        elseif mode == "off" then
            config_manager.set_debug_mode(false)
            logger.set_debug_mode(false)
            print("Debug mode disabled")
            DiscordLogger.log_admin(0, "Set Debug Mode", "Disabled")
        else
            print("Invalid option. Use 'on' or 'off'")
        end
    end, true)

    RegisterCommand("securedevmode", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end

        if #args < 1 then
            print("Usage: securedevmode <on/off>")
            return
        end

        local mode = args[1]:lower()
        if mode == "on" then
            debug_module.set_dev_mode(true)
            print("Developer mode enabled")
            DiscordLogger.log_admin(0, "Set Developer Mode", "Enabled")
        elseif mode == "off" then
            debug_module.set_dev_mode(false)
            print("Developer mode disabled")
            DiscordLogger.log_admin(0, "Set Developer Mode", "Disabled")
        else
            print("Invalid option. Use 'on' or 'off'")
        end
    end, true)

    RegisterCommand("securestats", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end

        print("===== SecureServe System Statistics =====")

        local debug_stats = debug_module.get_error_stats()
        print("Debug:")
        print("  Total Errors: " .. debug_stats.total_errors)
        print("  Recent Errors: " .. debug_stats.recent_errors)
        print("  Debug Mode: " .. (config_manager.is_debug_mode_enabled() and "Enabled" or "Disabled"))
        print("  Developer Mode: " .. (debug_stats.dev_mode and "Enabled" or "Disabled"))

        local ban_count = #ban_manager.get_all_bans()
        print("Bans:")
        print("  Total Bans: " .. ban_count)

        print("Players:")

        local player_count = #GetPlayers()

        print("  Active Players: " .. player_count)

        print("=======================================")

        DiscordLogger.log_admin(0, "System Stats", "Viewed system statistics", {
            ["Total Errors"] = debug_stats.total_errors,
            ["Total Bans"] = ban_count,
            ["Active Players"] = player_count,
            ["Debug Mode"] = config_manager.is_debug_mode_enabled() and "Enabled" or "Disabled"
        })
    end, true)

    RegisterCommand("securereload", function(source, args, rawCommand)
        if source ~= 0 then
            return
        end

        config_manager.initialize()
        print("Configuration reloaded via console command")
        DiscordLogger.log_admin(0, "Reload Config", "Configuration reloaded")
    end, true)

    print("Server console commands registered")
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
    print("^8║                  ^2SecureServe AntiCheat V1.5.0 Initializing^8               ║^7")
    print("^8╚══════════════════════════════════════════════════════════════════════════╝^7")

    print("\n^2╭─── Core Modules ^7")

    print("^2│ ^5⏳^7 Config Manager^7")
    config_manager.initialize()
    print("^2│ ^2✓^7 Config Manager^7 initialized")

    print("^2│ ^5⏳^7 Logger^7")
    logger.initialize(SecureServe)
    print("^2│ ^2✓^7 Logger^7 initialized")

    print("^2│ ^5⏳^7 Discord Logger^7")
    DiscordLogger.initialize()
    print("^2│ ^2✓^7 Discord Logger^7 initialized")
    print("^2│ ^5⏳^7 Debug Module^7")
    debug_module.initialize()
    print("^2│ ^2✓^7 Debug Module^7 initialized")

    print("^2│ ^5⏳^7 Ban Manager^7")
    ban_manager.initialize()
    print("^2│ ^2✓^7 Ban Manager^7 initialized")

    print("^2│ ^5⏳^7 Admin Whitelist^7")
    admin_whitelist.initialize()
    print("^2│ ^2✓^7 Admin Whitelist^7 initialized")

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

    print("^3│ ^5⏳^7 Anti Create Entity^7")
    anti_create_entity.initialize()
    print("^3│ ^2✓^7 Anti Create Entity^7 initialized")

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

    print("^3│ ^5⏳^7 Heartbeat^7")
    heartbeat.initialize()
    print("^3│ ^2✓^7 Heartbeat^7 initialized")

    print("^3╰───────────────^7")


    registerServerCommands()

    AddEventHandler("onResourceStop", function(resource_name)
        if resource_name == GetCurrentResourceName() then
            logger.info("SecureServe AntiCheat is stopping...")
            logger.warn("SecureServe AntiCheat is stopping...")
        end
    end)

    AddEventHandler("playerJoining", function(source, oldID)
        local player_name = GetPlayerName(source) or "Unknown"
        logger.info("Player " .. player_name .. " (" .. source .. ") is joining the server")
    end)

    RegisterNetEvent("SecureServe:ClientLog", function(level, message)
        local source = source
        local player_name = GetPlayerName(source) or "Unknown"

        message = "Client Log [" .. player_name .. " (" .. source .. ")]: " .. message

        if level == "ERROR" then
            logger.error(message)
            DiscordLogger.log_system("Client Error", message, {
                { name = "Player", value = player_name .. " (ID: " .. source .. ")", inline = true },
                { name = "Level",  value = level,                                    inline = true }
            })
        elseif level == "FATAL" then
            logger.fatal(message)
            DiscordLogger.log_system("Client Fatal Error", message, {
                { name = "Player", value = player_name .. " (ID: " .. source .. ")", inline = true },
                { name = "Level",  value = level,                                    inline = true }
            })
        else
            logger.info(message)
        end
    end)

    initialized = true
    print("\n^8╔══════════════════════════════════════════════════════════════════════════╗^7")
    print("^8║              ^2SecureServe AntiCheat V1.5.0 Loaded Successfully^8            ║^7")
    print("^8║                 ^3All Modules Initialized and Protection Active^8            ║^7")
    print("^8╚══════════════════════════════════════════════════════════════════════════╝^7")
    print("^6⚡ Support: ^3https://discord.gg/z6qGGtbcr4^7")
    print("^6⚡ Type ^3securehelp ^6in server console for commands^7")


    DiscordLogger.log_system(
        "AntiCheat Started",
        "SecureServe AntiCheat V1.5.0 has been successfully initialized.",
        {
            { name = "Server Name",       value = GetConvar("sv_hostname", "Unknown"), inline = true },
            { name = "Resource Name",     value = GetCurrentResourceName(),            inline = true },
            { name = "Number of Players", value = #GetPlayers(),                       inline = true }
        }
    )

    logger.info("SecureServe AntiCheat V1.5.0 initialized successfully")
end

CreateThread(function()
    Wait(4000)
    main()
end)

exports("module_punish", function(source, reason, webhook, time)
    if SecureServe and SecureServe.Module and SecureServe.Module.ModuleEnabled == false then
        return true
    end
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
    time = tonumber(time) or 2147483647
    return ban_manager.ban_player(source, reason, {
        detection = "Module Protection",
        time = time,
        webhook = webhook
    })
end)

RegisterNetEvent("SecureServe:Server:Methods:PunishPlayer", function(id, reason, webhook, time)
    local source = source
    if admin_whitelist.isWhitelisted(source) then
        return
    end

    local screenshot_url = nil
    if type(id) == "string" and id:find("^https?://") then
        screenshot_url = id
    end

    logger.warn("Player " .. source .. " triggered anti-cheat: " .. reason)
    DiscordLogger.log_detection(source, reason, {
        time = time or 2147483647,
        webhook = webhook
    })

    ban_manager.ban_player(source, reason, {
        admin = "Anti-Cheat System",
        time = time or 2147483647,
        detection = reason,
        screenshot = screenshot_url
    })
end)
