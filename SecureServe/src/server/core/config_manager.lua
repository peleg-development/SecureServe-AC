---@class ConfigManagerModule
local ConfigManager = {}

local function safe_get(table, key, default)
    if table and table[key] ~= nil then
        return table[key]
    end
    return default
end

local config = {
    Protections = {},
    Settings = {},
    Admins = {}
}

---@description Loads and manages server-side configuration
function ConfigManager.initialize()
    if not _G.SecureServe then
        _G.SecureServe = {}
        print("^1[WARNING] SecureServe config not found, using defaults^7")
    end
    
    config = _G.SecureServe
    
    RegisterNetEvent("requestConfig", function()
        local src = source
        TriggerClientEvent('receiveConfig', src, config)
    end)
    
    print("^5[SUCCESS] ^3Config Manager^7 initialized")
end

---@description Get the entire config object
---@return table The configuration table
function ConfigManager.get_config()
    return config
end

---@param player_id number The player ID to check permissions for
---@param permission string The permission to check
---@return boolean has_permission Whether the player has the permission
function ConfigManager.has_permission(player_id, permission)
    local identifiers = GetPlayerIdentifiers(player_id)
    local found = false
    
    for _, id in pairs(identifiers) do
        for _, admin in pairs(config.Admins or {}) do
            if id == admin.identifier and permission == admin.permission then
                found = true
                break
            end
        end
        
        if found then break end
    end
    
    return found
end

---@description Get a specific config value by key
---@param key string The key to get from config
---@param default any Default value if key doesn't exist
---@return any The config value or default
function ConfigManager.get(key, default)
    return safe_get(config, key, default)
end

---@description Check if an event is whitelisted in the config
---@param event_name string The event name to check
---@return boolean is_whitelisted Whether the event is whitelisted
function ConfigManager.is_event_whitelisted(event_name)
    if not config.EventWhitelist then return false end
    
    if config.EventWhitelist[event_name] then
        return true
    end
    
    for _, whitelisted_event in pairs(config.EventWhitelist) do
        if event_name == whitelisted_event then
            return true
        end
    end
    
    return false
end

---@description Add an event to the whitelist
---@param event_name string The event name to whitelist
---@return boolean success Whether the operation was successful
function ConfigManager.whitelist_event(event_name)
    if not event_name then return false end
    
    if not config.EventWhitelist then
        config.EventWhitelist = {}
    end
    
    if not ConfigManager.is_event_whitelisted(event_name) then
        config.EventWhitelist[event_name] = true
        return true
    end
    
    return false
end

---@return boolean is_enabled Whether menu detection is enabled in config
function ConfigManager.is_menu_detection_enabled()
    return true
end

---@return boolean is_enabled Whether trigger protection is enabled in config
function ConfigManager.is_trigger_protection_enabled()
    return true
end

---@return boolean is_enabled Whether entity spam protection is enabled in config
function ConfigManager.is_entity_spam_protection_enabled()
    return true
end

---@return number max_entities The maximum number of entities allowed per second
function ConfigManager.get_max_entities_per_second()
    return safe_get(SecureServe.Module.Entity.Limits, "Entities", 10)
end

---@param model number The model hash to check
---@return boolean is_blacklisted Whether the model is blacklisted
function ConfigManager.is_blacklisted_model(model)
    if not config.BlacklistedModels then return false end
    
    for _, blacklisted_model in pairs(config.BlacklistedModels) do
        if model == blacklisted_model or model == GetHashKey(blacklisted_model) then
            return true
        end
    end
    
    return false
end

---@return boolean is_enabled Whether blacklisted vehicle protection is enabled
function ConfigManager.is_blacklisted_vehicle_protection_enabled()
    return safe_get(config.Protections, "BlacklistedVehicles", false)
end

---@return boolean is_enabled Whether mass vehicle spawn protection is enabled
function ConfigManager.is_mass_vehicle_spawn_protection_enabled()
    return true
end

---@return number max_vehicles The maximum number of vehicles allowed per player
function ConfigManager.get_max_vehicles_per_player()
    return safe_get(SecureServe.Module.Entity.Limits, "Vehicles", 5)
end

---@return boolean is_enabled Whether blacklisted ped protection is enabled
function ConfigManager.is_blacklisted_ped_protection_enabled()
    return true
end

---@return boolean is_enabled Whether mass ped spawn protection is enabled
function ConfigManager.is_mass_ped_spawn_protection_enabled()
    return true
end

---@return number max_peds The maximum number of peds allowed per player
function ConfigManager.get_max_peds_per_player()
    return safe_get(SecureServe.Module.Entity.Limits, "Peds", 5)
end

---@return boolean is_enabled Whether blacklisted object protection is enabled
function ConfigManager.is_blacklisted_object_protection_enabled()
    return true
end

---@return boolean is_enabled Whether mass object spawn protection is enabled
function ConfigManager.is_mass_object_spawn_protection_enabled()
    return true
end

---@return number max_objects The maximum number of objects allowed per player
function ConfigManager.get_max_objects_per_player()
    return safe_get(SecureServe.Module.Entity.Limits, "Objects", 5)
end

---@return boolean is_enabled Whether resource injection protection is enabled
function ConfigManager.is_resource_injection_protection_enabled()
    return true
end

---@return boolean is_enabled Whether weapon modifier protection is enabled
function ConfigManager.is_weapon_modifier_protection_enabled()
    return true
end

---@param weapon_hash number The weapon hash to get max damage for
---@return number|nil max_damage The maximum damage value for the weapon or nil if not defined
function ConfigManager.get_weapon_max_damage(weapon_hash)
    if not config.WeaponDamages then return nil end
    return config.WeaponDamages[weapon_hash]
end

---@return boolean is_enabled Whether explosion protection is enabled
function ConfigManager.is_explosion_protection_enabled()
    return safe_get(SecureServe.Module.Explosions, "ModuleEnabled", false)
end

---@todo fix this to acutally work
---@return boolean is_enabled Whether particle protection is enabled
function ConfigManager.is_particle_protection_enabled()
    return safe_get(config.Protections, "ParticleProtection", false)
end

---@todo fix this to acutally work
---@return number max_particles The maximum number of particles per second
function ConfigManager.get_max_particles_per_second()
    return safe_get(config.Settings, "MaxParticlesPerSecond", 20)
end

---@param effect_hash number The particle effect hash to check
---@return boolean is_blacklisted Whether the particle effect is blacklisted
function ConfigManager.is_blacklisted_particle(effect_hash)
    if not config.BlacklistedParticles then return false end
    
    for _, blacklisted_particle in pairs(config.BlacklistedParticles) do
        if effect_hash == blacklisted_particle or effect_hash == GetHashKey(blacklisted_particle) then
            return true
        end
    end
    
    return false
end

return ConfigManager 