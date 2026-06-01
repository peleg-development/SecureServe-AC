local config_manager = require("server/core/config_manager")
local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")
local debug_module = require("server/core/debug_module")
local admin_whitelist = require("server/core/admin_whitelist")

local resource_manager = require("server/protections/resource_manager")
local anti_execution = require("server/protections/anti_execution")
local anti_entity_spam = require("server/protections/anti_entity_spam")
local anti_create_entity = require("server/protections/anti_create_entity")
local anti_unknown_event = require("server/protections/anti_unknown_event")
local anti_resource_injection = require("server/protections/anti_resource_injection")
local anti_weapon_damage_modifier = require("server/protections/anti_weapon_damage_modifier")
local anti_explosions = require("server/protections/anti_explosions")
local anti_particle_effects = require("server/protections/anti_particle_effects")
local heartbeat = require("server/protections/heartbeat")
local canary = require("server/protections/canary")
local anti_server_cfg_options = require("server/protections/anti_server_cfg_options")
local rate_limiter = require("server/protections/rate_limiter")
local alt_detection = require("server/protections/alt_detection")
local forensic_log = require("server/protections/forensic_log")

local punish_buckets = {}
local PUNISH_RATE_LIMIT = 3

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
            local matches = {}
            local needle = target_id_or_name:lower()
            for _, player_id in ipairs(GetPlayers()) do
                local pid = tonumber(player_id)
                local name = pid and GetPlayerName(pid)
                if name and name:lower():find(needle, 1, true) then
                    matches[#matches + 1] = pid
                end
            end
            if #matches == 1 then
                target_id = matches[1]
            elseif #matches > 1 then
                print("Multiple players match '" .. target_id_or_name .. "': " .. table.concat(matches, ", "))
                print("Use a player ID instead.")
                return
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
    print("^8║                  ^2SecureServe AntiCheat V" .. ((_G.SecureServeVersion and _G.SecureServeVersion.STRING) or "?.?.?") .. " Initializing^8               ║^7")
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

    print("^3│ ^5⏳^7 Anti Unknown Event^7")
    anti_unknown_event.initialize()
    print("^3│ ^2✓^7 Anti Unknown Event^7 initialized")

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

    print("^3│ ^5⏳^7 Canary^7")
    canary.initialize()
    print("^3│ ^2✓^7 Canary^7 initialized")

    print("^3│ ^5⏳^7 Anti Server Cfg Options^7")
    anti_server_cfg_options.initialize()
    print("^3│ ^2✓^7 Anti Server Cfg Options^7 initialized")

    print("^3│ ^5⏳^7 Rate Limiter^7")
    rate_limiter.initialize()
    print("^3│ ^2✓^7 Rate Limiter^7 initialized")

    print("^3│ ^5⏳^7 Alt Detection^7")
    alt_detection.initialize()
    print("^3│ ^2✓^7 Alt Detection^7 initialized")

    print("^3│ ^5⏳^7 Forensic Log^7")
    forensic_log.initialize()
    print("^3│ ^2✓^7 Forensic Log^7 initialized")

    print("^3╰───────────────^7")


    registerServerCommands()

    AddEventHandler("onResourceStop", function(resource_name)
        if resource_name == GetCurrentResourceName() then
            logger.warn("SecureServe AntiCheat is stopping...")
        end
    end)

    local player_joined_at = {}
    _G.SecureServe_PlayerJoinedAt = player_joined_at

    AddEventHandler("playerJoining", function(source, oldID)
        local player_name = GetPlayerName(source) or "Unknown"
        player_joined_at[source] = os.time()
        logger.info("Player " .. player_name .. " (" .. source .. ") is joining the server")
    end)

    local client_log_buckets = {}
    local CLIENT_LOG_PER_MIN = 10
    local CLIENT_LOG_MAX_LEN = 500
    local ALLOWED_LEVELS = { INFO = true, WARN = true, ERROR = true, FATAL = true, DEBUG = true }

    local function sanitize_client_log(msg)
        if type(msg) ~= "string" then return "<invalid>" end
        msg = msg:gsub("@everyone", "@\226\128\139everyone")
        msg = msg:gsub("@here", "@\226\128\139here")
        msg = msg:gsub("```", "ʼʼʼ")
        if #msg > CLIENT_LOG_MAX_LEN then
            msg = msg:sub(1, CLIENT_LOG_MAX_LEN) .. "...[truncated]"
        end
        return msg
    end

    RegisterNetEvent("SecureServe:ClientLog", function(level, message)
        local src = source
        if not src or src <= 0 then return end

        -- Rate limit: descartar (no banear) si se excede.
        if not rate_limiter.check(src, "SecureServe:ClientLog") then return end

        local bucket = client_log_buckets[src]
        local now = os.time()
        if not bucket or now - bucket.window_start >= 60 then
            client_log_buckets[src] = { window_start = now, count = 1 }
        else
            bucket.count = bucket.count + 1
            if bucket.count > CLIENT_LOG_PER_MIN then return end
        end

        if type(level) ~= "string" or not ALLOWED_LEVELS[level] then
            level = "INFO"
        end

        local player_name = GetPlayerName(src) or "Unknown"
        local clean_message = sanitize_client_log(message)

        -- Registrar en el buffer forense (evidencia, no decide nada).
        forensic_log.record(src, "client_log:" .. level, clean_message)

        clean_message = "Client Log [" .. player_name .. " (" .. tostring(src) .. ")]: " .. clean_message

        if level == "ERROR" then
            logger.error(clean_message)
            DiscordLogger.log_system("Client Error", clean_message, {
                { name = "Player", value = player_name .. " (ID: " .. tostring(src) .. ")", inline = true },
                { name = "Level",  value = level,                                            inline = true }
            })
        elseif level == "FATAL" then
            logger.fatal(clean_message)
            DiscordLogger.log_system("Client Fatal Error", clean_message, {
                { name = "Player", value = player_name .. " (ID: " .. tostring(src) .. ")", inline = true },
                { name = "Level",  value = level,                                            inline = true }
            })
        else
            logger.info(clean_message)
        end
    end)

    AddEventHandler("playerDropped", function()
        local src = source
        if src then
            client_log_buckets[src] = nil
            punish_buckets[src] = nil
            player_joined_at[src] = nil
        end
    end)

    initialized = true
    local version = (_G.SecureServeVersion and _G.SecureServeVersion.STRING) or "?.?.?"
    print("\n^8╔══════════════════════════════════════════════════════════════════════════╗^7")
    print("^8║              ^2SecureServe AntiCheat V" .. version .. " Loaded Successfully^8            ║^7")
    print("^8║                 ^3All Modules Initialized and Protection Active^8            ║^7")
    print("^8╚══════════════════════════════════════════════════════════════════════════╝^7")
    print("^6⚡ Support: ^3https://discord.gg/z6qGGtbcr4^7")
    print("^6⚡ Type ^3securehelp ^6in server console for commands^7")


    DiscordLogger.log_system(
        "AntiCheat Started",
        "SecureServe AntiCheat V" .. version .. " has been successfully initialized.",
        {
            { name = "Server Name",       value = GetConvar("sv_hostname", "Unknown"), inline = true },
            { name = "Resource Name",     value = GetCurrentResourceName(),            inline = true },
            { name = "Number of Players", value = #GetPlayers(),                       inline = true }
        }
    )

    logger.info("SecureServe AntiCheat V" .. version .. " initialized successfully")
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

    local event_name, resource_name, entity_resource, reason_text

    if type(reason) == "table" then
        event_name      = reason.event
        resource_name   = reason.resource
        entity_resource = reason.entity_resource
        reason_text     = reason.message or "Module Protection"
    else
        reason_text = tostring(reason)
        event_name, resource_name = reason_text:match("Tried triggering a restricted event: ([^%s]+)[%s]?in resource: ([^%s]+)")
        if not event_name then
            event_name = reason_text:match("Triggered an event without proper registration: ([^%s]+)")
        end
        if not event_name then
            event_name = reason_text:match("Unauthorized network event: ([^%s]+)")
        end
        entity_resource = reason_text:match("Created Suspicious Entity %[.+%] at script: ([^%s]+)")
        if not entity_resource and not resource_name then
            entity_resource = reason_text:match("Illegal entity created by resource: ([^%s]+)")
        end
        if not entity_resource and not resource_name then
            entity_resource = reason_text:match("Entity spam detected from resource: ([^%s]+)")
        end
    end

    if event_name or resource_name or entity_resource then
        local parts = {}
        if event_name then parts[#parts + 1] = "event=" .. event_name end
        if resource_name then parts[#parts + 1] = "resource=" .. resource_name end
        if entity_resource then parts[#parts + 1] = "entity_resource=" .. entity_resource end
        logger.debug("module_punish parsed: " .. table.concat(parts, ", "))
    end

    if event_name and config_manager.is_event_whitelisted(event_name) then
        return true
    end

    local resource_to_check = resource_name or entity_resource

    if resource_to_check then
        if resource_to_check == GetCurrentResourceName() then
            return true
        end

        if anti_resource_injection and anti_resource_injection.is_resource_whitelisted then
            if anti_resource_injection.is_resource_whitelisted(resource_to_check) then
                return true
            end
        end
    end

    if event_name and config_manager.get("SafeEvents") then
        local safe_events = config_manager.get("SafeEvents")
        if type(safe_events) == "table" then
            for _, safe_event in ipairs(safe_events) do
                if safe_event == event_name then
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
                    return true
                end
            end
        end
    end

    logger.info("Ban reason not matching any whitelist, proceeding with ban: " .. reason_text)

    local resolved_time = tonumber(time)
    if not resolved_time and Config and Config.EnforcementActions then
        for protection_name, action in pairs(Config.EnforcementActions) do
            if reason_text:find(protection_name, 1, true) then
                if type(action) == "number" then
                    resolved_time = action
                elseif Config.BanTimes and Config.BanTimes[action] then
                    resolved_time = Config.BanTimes[action]
                end
                break
            end
        end
    end
    resolved_time = resolved_time or 2147483647

    return ban_manager.ban_player(source, reason_text, {
        detection = "Module Protection",
        time = resolved_time,
        webhook = webhook
    })
end)


-- //[Public Exports]\\ --
--
-- Estos exports permiten que otros recursos consulten / interactuen con el AC
-- sin tener que llamar al BanManager directamente.
--
-- Ejemplos de uso desde otro resource:
--   local is_banned, ban = exports.SecureServe:is_player_banned("license:abc...")
--   local info           = exports.SecureServe:get_ban_info(player_source)
--   local last_10        = exports.SecureServe:get_recent_bans(10)
--   local ok             = exports.SecureServe:unban_player("license:abc...")

---@param identifier string license/discord/steam/ip/endpoint/token/hwid o ID numerico de un player conectado
---@return boolean banned
---@return table|nil ban
exports("is_player_banned", function(identifier)
    if not identifier then return false, nil end

    -- Si pasaron un player_id numerico, recogemos sus identificadores.
    if type(identifier) == "number" or (type(identifier) == "string" and identifier:match("^%d+$")) then
        local pid = tonumber(identifier)
        if pid and GetPlayerName(pid) then
            local idents = {}
            local n = GetNumPlayerIdentifiers(pid) or 0
            for i = 0, n - 1 do
                local val = GetPlayerIdentifier(pid, i)
                if val then
                    local key = val:match("^([^:]+):") or "id" .. tostring(i)
                    idents[key] = val
                end
            end
            if GetPlayerEndpoint then idents.endpoint = GetPlayerEndpoint(pid) end
            if GetPlayerTokens then
                local tokens = {}
                local tn = GetNumPlayerTokens(pid) or 0
                for i = 0, tn - 1 do
                    tokens[#tokens + 1] = GetPlayerToken(pid, i)
                end
                idents.tokens = tokens
            end
            return ban_manager.check_ban(idents)
        end
        return false, nil
    end

    return ban_manager.check_ban({ [identifier:match("^([^:]+):") or "id"] = identifier })
end)

---@param target number|string source o identificador
---@return table|nil ban
exports("get_ban_info", function(target)
    local banned, ban = exports.SecureServe:is_player_banned(target)
    if banned then return ban end
    return nil
end)

---@param count number|nil cuantos bans devolver (default 10)
---@return table bans lista en orden cronologico inverso (mas recientes primero)
exports("get_recent_bans", function(count)
    return ban_manager.get_recent_bans(count)
end)

---@param identifier string license/discord/steam/ip/endpoint/token/hwid o ban.id
---@return boolean ok
exports("unban_player", function(identifier)
    if not identifier then return false end
    return ban_manager.unban_player(identifier)
end)

---@return table stats { totalBans, recentBans, shadowMode, ... }
exports("get_stats", function()
    local total = 0
    if ban_manager.get_all_bans then
        total = #ban_manager.get_all_bans()
    end
    return {
        totalBans  = total,
        shadowMode = SecureServe and SecureServe.ShadowMode == true,
        version    = (SecureServe_Version and SecureServe_Version.current) or "unknown",
    }
end)

---@param identifier string license u otro identificador
---@return table accounts cuentas vinculadas por HWID/IP (vacio si ninguna)
exports("get_linked_accounts", function(identifier)
    if not identifier then return {} end
    return alt_detection.get_linked_accounts(identifier)
end)


RegisterNetEvent("SecureServe:Server:Methods:PunishPlayer", function(id, reason, webhook, time)
    local source = source
    if admin_whitelist.isWhitelisted(source) then
        return
    end

    -- Rate limit: descartar llamadas excesivas (no banear por ello).
    if not rate_limiter.check(source, "SecureServe:Server:Methods:PunishPlayer") then return end

    -- Registrar la deteccion en el buffer forense (evidencia).
    forensic_log.record(source, "detection", tostring(reason))

    local now = os.time()
    local bucket = punish_buckets[source]
    if not bucket or now - bucket.window_start >= 60 then
        punish_buckets[source] = { window_start = now, count = 1 }
    else
        bucket.count = bucket.count + 1
        if bucket.count > PUNISH_RATE_LIMIT then return end
    end

    local min_seconds = tonumber(SecureServe.MinimumOnlineSecondsBeforeBan) or 0
    if min_seconds > 0 and _G.SecureServe_PlayerJoinedAt then
        local joined_at = _G.SecureServe_PlayerJoinedAt[source]
        if joined_at then
            local online_seconds = os.time() - joined_at
            if online_seconds < min_seconds then
                logger.warn(("Punish for %s ignored (player only online %ds, threshold %ds): %s")
                    :format(source, online_seconds, min_seconds, reason))
                return
            end
        end
    end

    local screenshot_url = nil
    if type(id) == "string" and id:find("^https?://") then
        screenshot_url = id
    end

    local resolved_time = nil
    local resolved_webhook = nil
    if type(reason) == "string" and Config then
        if Config.EnforcementActions then
            for protection_name, action in pairs(Config.EnforcementActions) do
                if reason:find(protection_name, 1, true) then
                    if type(action) == "number" then
                        resolved_time = action
                    elseif Config.BanTimes and Config.BanTimes[action] then
                        resolved_time = Config.BanTimes[action]
                    end
                    break
                end
            end
        end
        if SecureServe and SecureServe.Webhooks then
            resolved_webhook = SecureServe.Webhooks.Simple
        end
    end
    resolved_time = resolved_time or 2147483647

    logger.warn("Player " .. source .. " triggered anti-cheat: " .. reason)
    DiscordLogger.log_detection(source, reason, {
        time = resolved_time,
        webhook = resolved_webhook
    })

    -- Modo shadow / report-only.
    --
    -- Si Config.ShadowMode = true, NINGUNA proteccion banea: solo loguea y
    -- manda el embed a Discord. Util para tunear el AC en un server real sin
    -- arriesgar a echar a jugadores legitimos por falso positivo.
    --
    -- Tambien se admite shadow por proteccion individual:
    --   Config.ShadowModeOverrides = { ["Anti X"] = true, ["Anti Y"] = false }
    -- El nombre de la proteccion se busca como substring dentro del `reason`.
    local shadow_global = SecureServe and SecureServe.ShadowMode == true
    local shadow_specific = false
    if SecureServe and type(SecureServe.ShadowModeOverrides) == "table" and type(reason) == "string" then
        for protection_name, on in pairs(SecureServe.ShadowModeOverrides) do
            if on == true and reason:find(protection_name, 1, true) then
                shadow_specific = true
                break
            end
        end
    end

    if shadow_global or shadow_specific then
        logger.warn(("[SHADOW] Skipping ban for player %s. Reason: %s"):format(source, reason))
        return
    end

    -- Adjuntar el historial forense (ultimas acciones del jugador) como
    -- contexto del ban, para poder revisarlo despues.
    local history = forensic_log.get_history(source)
    local detection_with_context = reason
    if history ~= "" then
        detection_with_context = reason .. "\n\n--- Recent activity ---\n" .. history
    end

    ban_manager.ban_player(source, reason, {
        admin = "Anti-Cheat System",
        time = resolved_time,
        detection = detection_with_context,
        screenshot = screenshot_url
    })
end)

-- //[Admin Commands]\\ --
--
-- Comandos de consola/admin disponibles para usar via rcon o desde un panel
-- externo. Requieren permiso ACE `secure.admin` (o ser admin via
-- admin_whitelist). Para usarlos como jugador necesitas tener el grupo ACE.

local function require_admin_console(src)
    if src == 0 then return true end  -- consola del servidor
    if admin_whitelist and admin_whitelist.isAdmin and admin_whitelist.isAdmin(src) then
        return true
    end
    if IsPlayerAceAllowed(src, "secure.admin") then
        return true
    end
    return false
end

local muted_players = {}    -- pid -> { until = os.time + duration, reason = ... }
local frozen_players = {}   -- pid -> bool

---@description Print info detallado de un player a quien lance el comando.
RegisterCommand("secureinfo", function(src, args)
    if not require_admin_console(src) then
        if src > 0 then TriggerClientEvent('chat:addMessage', src, { args = { "^1[SecureServe]", "No tienes permiso" } }) end
        return
    end

    local target = tonumber(args and args[1])
    if not target or not GetPlayerName(target) then
        local msg = "Uso: secureinfo <player_id>"
        if src == 0 then print(msg) else TriggerClientEvent('chat:addMessage', src, { args = { "^3[SecureServe]", msg } }) end
        return
    end

    local lines = {}
    table.insert(lines, ("Player %s (id %d):"):format(GetPlayerName(target), target))
    local n = GetNumPlayerIdentifiers(target) or 0
    for i = 0, n - 1 do
        local v = GetPlayerIdentifier(target, i)
        if v then table.insert(lines, "  " .. v) end
    end
    if GetPlayerEndpoint then
        table.insert(lines, "  endpoint: " .. tostring(GetPlayerEndpoint(target)))
    end
    if GetNumPlayerTokens then
        local tn = GetNumPlayerTokens(target) or 0
        for i = 0, tn - 1 do
            table.insert(lines, "  token: " .. tostring(GetPlayerToken(target, i)))
        end
    end
    if _G.SecureServe_PlayerJoinedAt and _G.SecureServe_PlayerJoinedAt[target] then
        table.insert(lines, ("  online_seconds: %d"):format(os.time() - _G.SecureServe_PlayerJoinedAt[target]))
    end
    table.insert(lines, ("  ping: %s"):format(tostring(GetPlayerPing(target))))
    table.insert(lines, ("  muted: %s, frozen: %s"):format(
        muted_players[target] and "yes" or "no",
        frozen_players[target] and "yes" or "no"))

    local out = table.concat(lines, "\n")
    if src == 0 then
        print(out)
    else
        for _, l in ipairs(lines) do
            TriggerClientEvent('chat:addMessage', src, { args = { "^5[SecureServe]", l } })
        end
    end
end, true)

---@description Mute "soft": registra el estado y manda evento. Tu chat
--- deberia escuchar `SecureServe:OnMute(target, muted, reason)` para aplicar.
RegisterCommand("securemute", function(src, args)
    if not require_admin_console(src) then return end

    local target = tonumber(args and args[1])
    local minutes = tonumber(args and args[2]) or 60
    local reason  = (args and args[3]) or "Muted by admin"

    if not target or not GetPlayerName(target) then
        local msg = "Uso: securemute <player_id> [minutos=60] [razon]"
        if src == 0 then print(msg) else TriggerClientEvent('chat:addMessage', src, { args = { "^3[SecureServe]", msg } }) end
        return
    end

    muted_players[target] = { ["until"] = os.time() + (minutes * 60), reason = reason }
    TriggerEvent("SecureServe:OnMute", target, true, reason)
    TriggerClientEvent('chat:addMessage', target, { args = { "^1[SecureServe]", ("Has sido silenciado %d minutos: %s"):format(minutes, reason) } })
    logger.info(("Muted player %s (id %d) for %d minutes. Reason: %s"):format(GetPlayerName(target), target, minutes, reason))
end, true)

RegisterCommand("secureunmute", function(src, args)
    if not require_admin_console(src) then return end
    local target = tonumber(args and args[1])
    if not target then return end

    if muted_players[target] then
        muted_players[target] = nil
        TriggerEvent("SecureServe:OnMute", target, false, "unmute")
        logger.info(("Unmuted player %s (id %d)"):format(GetPlayerName(target) or "unknown", target))
    end
end, true)

---@description Freeze: manda evento al cliente para congelar al player.
RegisterCommand("securefreeze", function(src, args)
    if not require_admin_console(src) then return end

    local target = tonumber(args and args[1])
    if not target or not GetPlayerName(target) then
        local msg = "Uso: securefreeze <player_id>"
        if src == 0 then print(msg) else TriggerClientEvent('chat:addMessage', src, { args = { "^3[SecureServe]", msg } }) end
        return
    end

    frozen_players[target] = not frozen_players[target]
    TriggerClientEvent("SecureServe:Freeze", target, frozen_players[target] == true)
    logger.info(("Toggle freeze on %s (id %d) -> %s"):format(
        GetPlayerName(target), target, frozen_players[target] and "FROZEN" or "UNFROZEN"))
end, true)

-- Limpieza automatica de mutes caducados.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000)
        local now = os.time()
        for pid, data in pairs(muted_players) do
            if data["until"] and data["until"] < now then
                muted_players[pid] = nil
                TriggerEvent("SecureServe:OnMute", pid, false, "expired")
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    if src then
        muted_players[src]  = nil
        frozen_players[src] = nil
    end
end)

---@return boolean is_muted, string|nil reason
exports("is_player_muted", function(pid)
    pid = tonumber(pid)
    if not pid then return false end
    local m = muted_players[pid]
    if not m then return false end
    if m["until"] and m["until"] < os.time() then
        muted_players[pid] = nil
        return false
    end
    return true, m.reason
end)


-- //[HTTP /health endpoint]\\ --
--
-- Expone un endpoint HTTP GET con el estado del AC. Util para monitorizacion
-- externa (UptimeKuma, Grafana, scripts cron, etc).
--
-- Acceso:
--   GET http://<server-ip>:<server-port>/SecureServe/health
--
-- Responde JSON con info no sensible.
SetHttpHandler(function(req, res)
    if req.path == "/health" then
        local total_bans = 0
        if ban_manager and ban_manager.get_all_bans then
            local all = ban_manager.get_all_bans()
            total_bans = (all and #all) or 0
        end

        local payload = {
            ok            = true,
            version       = (SecureServe_Version and SecureServe_Version.current) or "unknown",
            uptime        = os.time() - (_G.SecureServe_StartedAt or os.time()),
            shadow_mode   = SecureServe and SecureServe.ShadowMode == true,
            online        = math.max(0, (GetNumPlayerIndices() or 0)),
            total_bans    = total_bans,
            discord_queue = (DiscordLogger and DiscordLogger.message_queue and #DiscordLogger.message_queue) or 0,
        }

        res.writeHead(200, { ["Content-Type"] = "application/json" })
        res.send(json.encode(payload))
        return
    end

    res.writeHead(404, { ["Content-Type"] = "text/plain" })
    res.send("Not found")
end)

_G.SecureServe_StartedAt = os.time()
