local AutoConfig = {
    writing = false,
    fx_events = {
        ["onResourceStart"] = true,
        ["onResourceStarting"] = true,
        ["onResourceStop"] = true,
        ["onServerResourceStart"] = true,
        ["onServerResourceStop"] = true,
        ["gameEventTriggered"] = true,
        ["populationPedCreating"] = true,
        ["rconCommand"] = true,
        ["__cfx_internal:commandFallback"] = true,
        ["playerConnecting"] = true,
        ["playerDropped"] = true,
        ["onResourceListRefresh"] = true,
        ["weaponDamageEvent"] = true,
        ["vehicleComponentControlEvent"] = true,
        ["respawnPlayerPedEvent"] = true,
        ["explosionEvent"] = true,
        ["fireEvent"] = true,
        ["entityRemoved"] = true,
        ["playerJoining"] = true,
        ["startProjectileEvent"] = true,
        ["playerEnteredScope"] = true,
        ["playerLeftScope"] = true,
        ["ptFxEvent"] = true,
        ["removeAllWeaponsEvent"] = true,
        ["giveWeaponEvent"] = true,
        ["removeWeaponEvent"] = true,
        ["clearPedTasksEvent"] = true,
    }
}

local config_manager = require("server/core/config_manager")
local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")

local CONFIG_FILE = "config.lua"

local function get_settings()
    local settings = SecureServe and SecureServe.AutoConfig
    if type(settings) ~= "table" then return { Enabled = false } end
    return settings
end

local function is_enabled()
    return get_settings().Enabled == true
end

local function trim(value)
    if type(value) ~= "string" then return nil end
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    value = value:gsub("%.$", "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return nil end
    return value
end

local function is_safe_name(value)
    value = trim(value)
    if not value or #value > 160 then return false end
    return not value:find("[%z\r\n\"'{}]")
end

local function lua_pattern_escape(value)
    return (value:gsub("([^%w])", "%%%1"))
end

local function lua_quote(value)
    return ("%q"):format(value)
end

local function find_table_close(content, open_pos)
    local depth = 0
    local quote = nil
    local escaped = false

    for i = open_pos, #content do
        local char = content:sub(i, i)

        if quote then
            if escaped then
                escaped = false
            elseif char == "\\" then
                escaped = true
            elseif char == quote then
                quote = nil
            end
        elseif char == "\"" or char == "'" then
            quote = char
        elseif char == "{" then
            depth = depth + 1
        elseif char == "}" then
            depth = depth - 1
            if depth == 0 then return i end
        end
    end

    return nil
end

local function find_named_table(content, name_pattern)
    local start_pos, open_pos = content:find(name_pattern .. "%s*=%s*{")
    if not start_pos then return nil end

    local close_pos = find_table_close(content, open_pos)
    if not close_pos then return nil end

    return start_pos, open_pos, close_pos, content:sub(open_pos + 1, close_pos - 1)
end

local function insert_entry(content, close_pos, line)
    local before = content:sub(1, close_pos - 1)
    local after = content:sub(close_pos)
    local trailing = before:match("([ \t\r\n]*)$") or ""
    local insert_at = close_pos - #trailing
    local prefix = content:sub(1, insert_at - 1)
    local suffix = content:sub(insert_at, close_pos - 1)

    if prefix:sub(-1) ~= "\n" then
        line = "\n" .. line
    end

    return prefix .. line .. suffix .. after
end

local function append_string_value(content, table_pattern, value)
    local _, _, close_pos, table_content = find_named_table(content, table_pattern)
    if not close_pos then
        return content, false, "table_not_found"
    end

    if table_content:find("\"" .. value .. "\"", 1, true) or table_content:find("'" .. value .. "'", 1, true) then
        return content, false, "already_exists"
    end

    return insert_entry(content, close_pos, "    " .. lua_quote(value) .. ",\n"), true
end

local function append_entity_resource(content, resource_name)
    local _, _, close_pos, table_content = find_named_table(content, "SecurityWhitelist")
    if not close_pos then
        return content, false, "table_not_found"
    end

    local escaped = lua_pattern_escape(resource_name)
    if table_content:find("resource%s*=%s*['\"]" .. escaped .. "['\"]") then
        return content, false, "already_exists"
    end

    local entry = ("        { resource = %s, whitelist = true },\n"):format(lua_quote(resource_name))
    return insert_entry(content, close_pos, entry), true
end

local function save_config(content)
    local saved = SaveResourceFile(GetCurrentResourceName(), CONFIG_FILE, content, -1)
    if saved then return true end
    logger.error("Auto-config failed to save " .. CONFIG_FILE)
    return false
end

local function parse_reason(reason)
    reason = trim(reason)
    if not reason then return nil end

    local event_name, resource_name = reason:match("Tried triggering a restricted event:%s*(.-)%s+in resource:%s*(.+)$")
    if event_name then
        return "event", trim(event_name), trim(resource_name)
    end

    event_name = reason:match("Triggered an event without proper registration:%s*(.+)$")
    if event_name then
        return "event", trim(event_name)
    end

    event_name = reason:match("Unauthorized network event:%s*(.+)$")
    if event_name then
        return "event", trim(event_name)
    end

    resource_name = reason:match("Created Suspicious Entity %[.+%] at script:%s*(.+)$")
    if not resource_name then
        resource_name = reason:match("Illegal entity created by resource:%s*(.+)$")
    end
    if not resource_name then
        resource_name = reason:match("Entity spam detected from resource:%s*(.+)$")
    end

    if resource_name then
        return "entity", trim(resource_name)
    end

    return nil
end

local function update_runtime(kind, value)
    if kind == "event" then
        return config_manager.whitelist_event(value)
    end

    if kind == "entity" and config_manager.whitelist_entity_resource then
        return config_manager.whitelist_entity_resource(value)
    end

    return false
end

local function patch_config(kind, value)
    while AutoConfig.writing do
        Wait(100)
    end

    AutoConfig.writing = true

    local content = LoadResourceFile(GetCurrentResourceName(), CONFIG_FILE)
    if not content or content == "" then
        AutoConfig.writing = false
        logger.error("Auto-config could not load " .. CONFIG_FILE)
        return false
    end

    local updated, changed, status
    if kind == "event" then
        updated, changed, status = append_string_value(content, "Config%.WhitelistEvents", value)
    else
        updated, changed, status = append_entity_resource(content, value)
    end

    if not changed then
        AutoConfig.writing = false
        return status == "already_exists"
    end

    local saved = save_config(updated)
    AutoConfig.writing = false

    if saved then
        update_runtime(kind, value)
        logger.info(("Auto-config added %s whitelist entry: %s"):format(kind, value))
        return true
    end

    return false
end

function AutoConfig.initialize()
    logger.info("Auto-config module initialized")
end

function AutoConfig.is_fx_event(event_name)
    return AutoConfig.fx_events[event_name] == true
end

function AutoConfig.is_event_whitelisted(event_name)
    if AutoConfig.is_fx_event(event_name) then return true end
    return config_manager.is_event_whitelisted(event_name)
end

function AutoConfig.is_entity_resource_whitelisted(resource_name)
    if resource_name == GetCurrentResourceName() then return true end
    if config_manager.is_entity_resource_whitelisted then
        return config_manager.is_entity_resource_whitelisted(resource_name)
    end
    return false
end

function AutoConfig.process_auto_whitelist(src, reason)
    if not is_enabled() then return false end

    local kind, value, resource_name = parse_reason(reason)
    if not kind or not value or not is_safe_name(value) then return false end

    if kind == "event" and AutoConfig.is_event_whitelisted(value) then return true end
    if kind == "entity" and AutoConfig.is_entity_resource_whitelisted(value) then return true end
    if resource_name and trim(resource_name) == GetCurrentResourceName() then return true end

    return patch_config(kind, value)
end

function AutoConfig.validate_event(src, event_name, resource_name, webhook)
    if AutoConfig.is_event_whitelisted(event_name) then return true end
    local reason = ("Tried triggering a restricted event: %s in resource: %s")
        :format(tostring(event_name), tostring(resource_name or "unknown"))
    return AutoConfig.process_auto_whitelist(src, reason, webhook)
end

function AutoConfig.ban_with_auto_config(src, reason, details)
    if AutoConfig.process_auto_whitelist(src, reason) then return false end
    return ban_manager.ban_player(src, reason, details)
end

return AutoConfig
