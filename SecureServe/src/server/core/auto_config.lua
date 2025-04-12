---@class AutoConfigModule
local AutoConfig = {
    is_modifying_config = false,
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
local debug_module = require("server/core/debug_module")

---@description Initialize the auto-config module
function AutoConfig.initialize()
    logger.info("Auto-config module initialized")
end

---@description Append a value to a table in the config file
---@param config_content string The content of the config file
---@param table_name string The name of the table to append to
---@param value_to_add string The value to add to the table
---@return string, boolean The updated config content and success status
function AutoConfig.append_to_table(config_content, table_name, value_to_add)
    if not config_content or not table_name or not value_to_add then
        logger.error("Invalid parameters for append_to_table")
        return config_content, false
    end

    local pattern = table_name .. "%s*=%s*{([^}]*)}"
    local table_start, table_end, table_content = config_content:find(pattern)
    
    if not table_start then
        logger.error("Could not find table " .. table_name .. " in config")
        return config_content, false
    end
    
    local value_pattern = string.format('["\']*%s["\']*', value_to_add:gsub('%-', '%%-'):gsub('%.', '%%%.'))
    if table_content:find(value_pattern) then
        logger.debug("Value " .. value_to_add .. " already exists in table " .. table_name)
        return config_content, false
    end
    
    local updated_content
    if table_content:match("[^%s,]$") then
        updated_content = config_content:sub(1, table_end - 1) .. ', "' .. value_to_add .. '"' .. config_content:sub(table_end)
    else
        updated_content = config_content:sub(1, table_end - 1) .. '"' .. value_to_add .. '"' .. config_content:sub(table_end)
    end
    
    logger.debug("Updated config: Added " .. value_to_add .. " to " .. table_name)
    return updated_content, true
end

---@description Add entity data to the config
---@param config_content string The content of the config file
---@param table_name string The name of the table to append to
---@param resource_name string The resource name to whitelist
---@return string, boolean The updated config content and success status
function AutoConfig.add_entity_resource(config_content, table_name, resource_name)
    if not config_content or not table_name or not resource_name then
        logger.error("Invalid parameters for add_entity_resource")
        return config_content, false
    end

    local pattern = table_name .. "%s*=%s*{([^}]*)}"
    local table_start, table_end, table_content = config_content:find(pattern)
    
    if not table_start then
        logger.error("Could not find table " .. table_name .. " in config")
        return config_content, false
    end
    
    local resource_pattern = string.format('resource%s*=%s*["\']*%s["\']*', resource_name:gsub('%-', '%%-'):gsub('%.', '%%%.'))
    if table_content:find(resource_pattern) then
        logger.debug("Resource " .. resource_name .. " already exists in table " .. table_name)
        return config_content, false
    end
    
    local entity_entry = '{ resource = "' .. resource_name .. '" }'
    local updated_content
    
    if table_content:match("[^%s,]$") then
        updated_content = config_content:sub(1, table_end - 1) .. ', ' .. entity_entry .. config_content:sub(table_end)
    else
        updated_content = config_content:sub(1, table_end - 1) .. entity_entry .. config_content:sub(table_end)
    end
    
    logger.debug("Updated config: Added " .. resource_name .. " to " .. table_name)
    return updated_content, true
end

---@description Process a potential auto-whitelist for an event or entity
---@param src number The source of the detection
---@param reason string The detection reason
---@param webhook string The webhook to send notifications to
---@param time number The ban duration
---@return boolean handled Whether the detection was handled by auto-config
function AutoConfig.process_auto_whitelist(src, reason, webhook, time)
    if not SecureServe.AutoConfig then
        logger.debug("Auto-config is disabled. Skipping auto-whitelist.")
        return false
    end
    
    local isEvent, detectedResource = reason:match("Tried triggering a restricted event: (.+) in resource: (.+)")
    local isUnregisteredEvent = reason:match("Triggered an event without proper registration: (.+)")
    local isSuspiciousEntity, entityResource = reason:match("Created Suspicious Entity %[.+%] at script: (.+)")
    
    if detectedResource and detectedResource == "SecureServe" then
        logger.debug("Detection from SecureServe itself. Ignoring.")
        return true
    end
    
    while AutoConfig.is_modifying_config do
        Citizen.Wait(100)
    end
    
    AutoConfig.is_modifying_config = true
    
    local configFile = LoadResourceFile(GetCurrentResourceName(), "config.lua")
    if not configFile then
        logger.error("Could not load config.lua")
        AutoConfig.is_modifying_config = false
        return false
    end
    
    local updated = false
    
    if isEvent and detectedResource then
        logger.debug("Processing event whitelist for event: " .. isEvent)
        
        if AutoConfig.is_event_whitelisted(isEvent) then
            logger.debug("Event " .. isEvent .. " is already whitelisted")
            AutoConfig.is_modifying_config = false
            return true
        end
        
        local newConfig, success = AutoConfig.append_to_table(configFile, "SecureServe.Module.Events.Whitelist", isEvent)
        if success then
            SaveResourceFile(GetCurrentResourceName(), "config.lua", newConfig, -1)
            logger.info("Added event " .. isEvent .. " to the whitelist")
            updated = true
        end
    
    elseif isUnregisteredEvent then
        logger.debug("Processing unregistered event: " .. isUnregisteredEvent)
        
        if AutoConfig.is_event_whitelisted(isUnregisteredEvent) then
            logger.debug("Event " .. isUnregisteredEvent .. " is already whitelisted")
            AutoConfig.is_modifying_config = false
            return true
        end
        
        local newConfig, success = AutoConfig.append_to_table(configFile, "SecureServe.Module.Events.Whitelist", isUnregisteredEvent)
        if success then
            SaveResourceFile(GetCurrentResourceName(), "config.lua", newConfig, -1)
            logger.info("Added unregistered event " .. isUnregisteredEvent .. " to the whitelist")
            updated = true
        end
    
    elseif isSuspiciousEntity then
        logger.debug("Processing suspicious entity from resource: " .. isSuspiciousEntity)
        
        if AutoConfig.is_entity_resource_whitelisted(isSuspiciousEntity) then
            logger.debug("Resource " .. isSuspiciousEntity .. " is already whitelisted for entities")
            AutoConfig.is_modifying_config = false
            return true
        end
        
        local newConfig, success = AutoConfig.add_entity_resource(configFile, "SecureServe.EntitySecurity", isSuspiciousEntity)
        if success then
            SaveResourceFile(GetCurrentResourceName(), "config.lua", newConfig, -1)
            logger.info("Added resource " .. isSuspiciousEntity .. " to entity whitelist")
            updated = true
        end
    
    elseif detectedResource then
        logger.debug("Processing detected resource: " .. detectedResource)
        
        if AutoConfig.is_entity_resource_whitelisted(detectedResource) then
            logger.debug("Resource " .. detectedResource .. " is already whitelisted")
            AutoConfig.is_modifying_config = false
            return true
        end
        
        local newConfig, success = AutoConfig.add_entity_resource(configFile, "SecureServe.EntitySecurity", detectedResource)
        if success then
            SaveResourceFile(GetCurrentResourceName(), "config.lua", newConfig, -1)
            logger.info("Added resource " .. detectedResource .. " to whitelist")
            updated = true
        end
    end
    
    AutoConfig.is_modifying_config = false
    
    if updated then
        logger.info("Config updated successfully")
        return true
    else
        logger.debug("No changes made to config.lua")
        return false
    end
end

---@description Check if an event is whitelisted
---@param event_name string The event name to check
---@return boolean is_whitelisted Whether the event is whitelisted
function AutoConfig.is_event_whitelisted(event_name)
    if AutoConfig.fx_events[event_name] then
        return true
    end
    
    local config = SecureServe
    if config and config.Module and config.Module.Events and config.Module.Events.Whitelist and config.Module.Events.Whitelist[event_name] then
        return true
    end
    
    return false
end

---@description Check if an entity resource is whitelisted
---@param resource_name string The resource name to check
---@return boolean is_whitelisted Whether the resource is whitelisted
function AutoConfig.is_entity_resource_whitelisted(resource_name)
    local config = SecureServe
    
    if not config or not config.Module or not config.Module.Entity or not config.Module.Entity.SecurityWhitelist then
        return false
    end
    
    for _, entry in ipairs(config.Module.Entity.SecurityWhitelist) do
        if entry.resource == resource_name then
            return true
        end
    end
    
    return false
end

---@description Check if event needs validation, and validate if auto-config is disabled
---@param src number The source player
---@param event_name string The event name
---@param resource_name string The resource that triggered the event
---@param webhook string Optional webhook for notifications
---@return boolean is_valid Whether the event is valid
function AutoConfig.validate_event(src, event_name, resource_name, webhook)
    if AutoConfig.fx_events[event_name] then
        return true
    end
    
    if config_manager.is_event_whitelisted(event_name) then
        return true
    end
    
    logger.debug("Event validation failed for: " .. event_name .. " from resource: " .. (resource_name or "unknown"))
    
    if SecureServe.AutoConfig then
        local auto_handled = AutoConfig.process_auto_whitelist(
            src, 
            "Tried triggering a restricted event: " .. event_name .. " in resource: " .. (resource_name or "unknown"), 
            webhook
        )
        
        if auto_handled then
            return true
        end
    end
    
    return false
end

---@description Get the current whitelist for a specific protection
---@param protection_type string The type of protection to get whitelist for
---@return table The whitelist for the protection
function AutoConfig.get_whitelist(protection_type)
    local config = SecureServe
    local whitelist = {}
    
    if protection_type == "events" then
        whitelist = config.Module and config.Module.Events and config.Module.Events.Whitelist or {}
    elseif protection_type == "entity" then
        whitelist = config.Module and config.Module.Entity and config.Module.Entity.SecurityWhitelist or {}
    elseif protection_type == "explosions" then
        whitelist = config.Module and config.Module.Explosions and config.Module.Explosions.Whitelist or {}
    end
    
    return whitelist
end

---@description Check if a resource is whitelisted for a specific protection
---@param resource_name string The resource name to check
---@param protection_type string The protection type to check whitelist for
---@return boolean is_whitelisted Whether the resource is whitelisted
function AutoConfig.is_resource_whitelisted(resource_name, protection_type)
    local config = SecureServe
    local whitelist = AutoConfig.get_whitelist(protection_type)
    
    if protection_type == "events" or protection_type == "explosions" then
        return whitelist[resource_name] == true
    elseif protection_type == "entity" then
        for _, entry in pairs(whitelist) do
            if entry.resource == resource_name and entry.whitelist then
                return true
            end
        end
    end
    
    return false
end

---@description Ban with auto-config handling
---@param src number The player source
---@param reason string The reason for the ban
---@param webhook string The webhook to send the ban notification to
---@param time number The ban duration
---@return boolean banned Whether the player was banned
function AutoConfig.ban_with_auto_config(src, reason, webhook, time)
    if SecureServe.AutoConfig then
        logger.info(string.format("Auto-config protected player %s from ban for reason: %s", GetPlayerName(src) or src, reason))
        return false
    end
    
    return ban_manager.ban_player(src, reason, webhook, time)
end

return AutoConfig 