local ConfigManager = {}

local logger = require("server/core/logger")

local function safe_get(tbl, key, default)
    if tbl and tbl[key] ~= nil then
        return tbl[key]
    end
    return default
end

local config = {
    Protections = {},
    Settings    = {},
    Admins      = {},
}

local sanitized_config_cache = nil

local function strip_webhook(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        if k ~= "webhook" and k ~= "Webhook" then
            if type(v) == "table" then
                copy[k] = strip_webhook(v)
            else
                copy[k] = v
            end
        end
    end
    return copy
end

local function build_sanitized_config()
    if not config then return {} end

    local payload = {
        ServerName  = config.ServerName,
        DiscordLink = config.DiscordLink,
        AppealURL   = config.AppealURL,
        BanTimes    = config.BanTimes,
        Debug       = config.Debug,
        AdminMenu   = config.AdminMenu and {
            AutoRefresh = config.AdminMenu.AutoRefresh,
        } or nil,
        Protection = config.Protection and {
            Simple                = strip_webhook(config.Protection.Simple),
            BlacklistedCommands   = strip_webhook(config.Protection.BlacklistedCommands),
            BlacklistedSprites    = strip_webhook(config.Protection.BlacklistedSprites),
            BlacklistedAnimDicts  = strip_webhook(config.Protection.BlacklistedAnimDicts),
            BlacklistedWeapons    = strip_webhook(config.Protection.BlacklistedWeapons),
            BlacklistedVehicles   = strip_webhook(config.Protection.BlacklistedVehicles),
            BlacklistedObjects    = strip_webhook(config.Protection.BlacklistedObjects),
            BlacklistedPeds       = strip_webhook(config.Protection.BlacklistedPeds),
            BlacklistedExplosions = strip_webhook(config.Protection.BlacklistedExplosions),
            CancelOtherExplosions = config.Protection.CancelOtherExplosions,
        } or nil,
        OCR = config.OCR,
    }

    return payload
end

local function get_event_whitelist()
    config.Module = config.Module or {}
    config.Module.Events = config.Module.Events or {}
    if type(config.Module.Events.Whitelist) ~= "table" then
        config.Module.Events.Whitelist = {}
    end

    local whitelist = config.Module.Events.Whitelist

    for key, value in pairs(whitelist) do
        if type(key) == "number" and type(value) == "string" then
            whitelist[value] = true
        end
    end

    if type(config.EventWhitelist) == "table" then
        for key, value in pairs(config.EventWhitelist) do
            if type(key) == "string" then
                whitelist[key] = true
            elseif type(value) == "string" then
                whitelist[value] = true
            end
        end
    end

    return whitelist
end

function ConfigManager.initialize()
    if not _G.SecureServe then
        _G.SecureServe = {}
        print("^1[WARNING] SecureServe config not found, using defaults^7")
    end

    config = _G.SecureServe
    get_event_whitelist()
    ConfigManager.initialize_blacklist_lookups()

    sanitized_config_cache = build_sanitized_config()

    RegisterNetEvent("requestConfig", function()
        local src = source
        TriggerClientEvent('receiveConfig', src, sanitized_config_cache)
    end)

    print("^5[SUCCESS] ^3Config Manager^7 initialized")
end

function ConfigManager.get_config()
    return config
end

function ConfigManager.has_permission(player_id, permission)
    local identifiers = GetPlayerIdentifiers(player_id)
    for _, id in pairs(identifiers) do
        for _, admin in pairs(config.Admins or {}) do
            if id == admin.identifier and permission == admin.permission then
                return true
            end
        end
    end
    return false
end

function ConfigManager.get(key, default)
    return safe_get(config, key, default)
end

function ConfigManager.is_event_whitelisted(event_name)
    local whitelist = get_event_whitelist()
    if whitelist[event_name] then return true end
    for _, w in pairs(whitelist) do
        if event_name == w then return true end
    end
    return false
end

function ConfigManager.whitelist_event(event_name)
    if not event_name then return false end
    local whitelist = get_event_whitelist()
    if not ConfigManager.is_event_whitelisted(event_name) then
        whitelist[event_name] = true
        if type(config.SafeEvents) == "table" then
            config.SafeEvents[#config.SafeEvents + 1] = event_name
        end
        if _G.SecureServe and type(_G.SecureServe.SafeEvents) == "table" then
            _G.SecureServe.SafeEvents[#_G.SecureServe.SafeEvents + 1] = event_name
        end
        sanitized_config_cache = build_sanitized_config()
        return true
    end
    return false
end

function ConfigManager.is_entity_resource_whitelisted(resource_name)
    if not resource_name then return false end

    local entity = config.Module and config.Module.Entity
    local whitelist = entity and entity.SecurityWhitelist
    if type(whitelist) == "table" then
        for _, entry in ipairs(whitelist) do
            if entry and entry.resource == resource_name and entry.whitelist ~= false then
                return true
            end
        end
    end

    local safe_resources = config.SafeResources
    if type(safe_resources) == "table" then
        for _, safe_resource in ipairs(safe_resources) do
            if safe_resource == resource_name then return true end
        end
    end

    return false
end

function ConfigManager.whitelist_entity_resource(resource_name)
    if not resource_name or resource_name == "" then return false end
    if ConfigManager.is_entity_resource_whitelisted(resource_name) then return false end

    config.Module = config.Module or {}
    config.Module.Entity = config.Module.Entity or {}
    config.Module.Entity.SecurityWhitelist = config.Module.Entity.SecurityWhitelist or {}
    config.Module.Entity.SecurityWhitelist[#config.Module.Entity.SecurityWhitelist + 1] = {
        resource = resource_name,
        whitelist = true,
    }

    config.SafeResources = config.SafeResources or {}
    config.SafeResources[#config.SafeResources + 1] = resource_name

    if _G.SecureServe then
        _G.SecureServe.Module = _G.SecureServe.Module or {}
        _G.SecureServe.Module.Entity = _G.SecureServe.Module.Entity or {}
        _G.SecureServe.Module.Entity.SecurityWhitelist = config.Module.Entity.SecurityWhitelist
        _G.SecureServe.SafeResources = config.SafeResources
    end

    sanitized_config_cache = build_sanitized_config()
    return true
end

function ConfigManager.is_menu_detection_enabled()         return true end
function ConfigManager.is_trigger_protection_enabled()     return true end
function ConfigManager.is_entity_spam_protection_enabled() return true end

function ConfigManager.get_max_entities_per_second()
    return safe_get(SecureServe.Module and SecureServe.Module.Entity and SecureServe.Module.Entity.Limits or {}, "Entities", 10)
end

function ConfigManager.is_blacklisted_model(modelHash)
    return ConfigManager.is_vehicle_blacklisted(modelHash) or
           ConfigManager.is_ped_blacklisted(modelHash) or
           ConfigManager.is_object_blacklisted(modelHash)
end

local vehicle_hash_lookup = {}
local ped_hash_lookup     = {}
local object_hash_lookup  = {}

function ConfigManager.initialize_blacklist_lookups()
    vehicle_hash_lookup, ped_hash_lookup, object_hash_lookup = {}, {}, {}

    if config.Protection and config.Protection.BlacklistedVehicles then
        for _, v in ipairs(config.Protection.BlacklistedVehicles) do
            if v.name then
                local hash = type(v.name) == "number" and v.name or GetHashKey(v.name)
                vehicle_hash_lookup[hash] = true
            end
        end
    end

    if config.Protection and config.Protection.BlacklistedPeds then
        for _, p in ipairs(config.Protection.BlacklistedPeds) do
            if p.hash then
                ped_hash_lookup[p.hash] = true
            elseif p.name then
                ped_hash_lookup[GetHashKey(p.name)] = true
            end
        end
    end

    if config.Protection and config.Protection.BlacklistedObjects then
        for _, o in ipairs(config.Protection.BlacklistedObjects) do
            if o.name then
                local hash = type(o.name) == "number" and o.name or GetHashKey(o.name)
                object_hash_lookup[hash] = true
            end
        end
    end

    logger.info("^5[SUCCESS] ^3Blacklist lookups^7 initialized")
end

function ConfigManager.is_vehicle_blacklisted(h) return h and vehicle_hash_lookup[h] == true or false end
function ConfigManager.is_ped_blacklisted(h)     return h and ped_hash_lookup[h]     == true or false end
function ConfigManager.is_object_blacklisted(h)  return h and object_hash_lookup[h]  == true or false end

function ConfigManager.is_blacklisted_vehicle_protection_enabled()
    if config.Protection and type(config.Protection.BlacklistedVehicles) == "table" then
        return #config.Protection.BlacklistedVehicles > 0
    end
    return false
end
function ConfigManager.is_blacklisted_ped_protection_enabled()
    if config.Protection and type(config.Protection.BlacklistedPeds) == "table" then
        return #config.Protection.BlacklistedPeds > 0
    end
    return false
end
function ConfigManager.is_blacklisted_object_protection_enabled()
    if config.Protection and type(config.Protection.BlacklistedObjects) == "table" then
        return #config.Protection.BlacklistedObjects > 0
    end
    return false
end

function ConfigManager.is_mass_vehicle_spawn_protection_enabled() return true end
function ConfigManager.is_mass_ped_spawn_protection_enabled()     return true end
function ConfigManager.is_mass_object_spawn_protection_enabled()  return true end

function ConfigManager.get_max_vehicles_per_player()
    return safe_get(SecureServe.Module and SecureServe.Module.Entity and SecureServe.Module.Entity.Limits or {}, "Vehicles", 5)
end
function ConfigManager.get_max_peds_per_player()
    return safe_get(SecureServe.Module and SecureServe.Module.Entity and SecureServe.Module.Entity.Limits or {}, "Peds", 5)
end
function ConfigManager.get_max_objects_per_player()
    return safe_get(SecureServe.Module and SecureServe.Module.Entity and SecureServe.Module.Entity.Limits or {}, "Objects", 5)
end

function ConfigManager.is_resource_injection_protection_enabled() return true end
function ConfigManager.is_weapon_modifier_protection_enabled()    return true end

function ConfigManager.get_weapon_max_damage(weapon_hash)
    local table_ref = config.WeaponDamages or (_G.SecureServe and _G.SecureServe.WeaponDamages)
    if not table_ref then return nil end
    return table_ref[weapon_hash]
end

function ConfigManager.is_particle_protection_enabled()
    return safe_get(config.Protections, "ParticleProtection", false)
end

function ConfigManager.get_max_particles_per_second()
    return safe_get(config.Settings, "MaxParticlesPerSecond", 20)
end

function ConfigManager.is_blacklisted_particle(effect_hash)
    if not config.BlacklistedParticles then return false end
    for _, p in pairs(config.BlacklistedParticles) do
        if effect_hash == p or effect_hash == GetHashKey(p) then
            return true
        end
    end
    return false
end

-- Fix: resolves the ban duration SERVER-side, read per protection via entry.protection (not entry.name), so the client cannot shorten its own ban.
function ConfigManager.resolve_ban_time(reason)
    local default_time = (config.BanTimes and config.BanTimes.Ban) or 2147483647
    if type(reason) ~= "string" then return default_time end

    local simple = config.Protection and config.Protection.Simple
    if type(simple) == "table" then
        for _, entry in ipairs(simple) do
            local name = entry and (entry.protection or entry.name)
            if type(name) == "string" and name ~= "" and reason:sub(1, #name) == name then
                local t = entry.time
                if type(t) == "string" then
                    t = (config.BanTimes and config.BanTimes[t]) or default_time
                end
                return tonumber(t) or default_time
            end
        end
    end

    return default_time
end

function ConfigManager.is_debug_mode_enabled()
    return safe_get(config, "Debug", false)
end

function ConfigManager.set_debug_mode(enabled)
    if config.Debug ~= enabled then
        config.Debug = enabled
        sanitized_config_cache = build_sanitized_config()
        TriggerClientEvent("SecureServe:UpdateDebugMode", -1, enabled)
        return true
    end
    return false
end

return ConfigManager
