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

    local source_table = config.Module.Events.Whitelist
    local normalized = {}

    for key, value in pairs(source_table) do
        if type(key) == "string" then
            normalized[key] = true
        elseif type(value) == "string" then
            normalized[value] = true
        end
    end

    if type(config.EventWhitelist) == "table" then
        for key, value in pairs(config.EventWhitelist) do
            if type(key) == "string" then
                normalized[key] = true
            elseif type(value) == "string" then
                normalized[value] = true
            end
        end
    end

    for key in pairs(normalized) do
        source_table[key] = true
    end

    return normalized
end

function ConfigManager.initialize()
    if not _G.SecureServe then
        _G.SecureServe = {}
        logger.warn("SecureServe config not found, using defaults")
    end

    config = _G.SecureServe
    get_event_whitelist()
    ConfigManager.initialize_blacklist_lookups()

    sanitized_config_cache = build_sanitized_config()

    RegisterNetEvent("SecureServe:Config:Request", function()
        local src = source
        TriggerClientEvent('SecureServe:Config:Receive', src, sanitized_config_cache)
    end)

    logger.info("^5[SUCCESS] ^3Config Manager^7 initialized")
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
    if type(event_name) ~= "string" then return false end
    local whitelist = get_event_whitelist()
    if whitelist[event_name] == true then return true end

    if _G.decrypt then
        local ok, decoded = pcall(_G.decrypt, event_name)
        if ok and type(decoded) == "string" and decoded ~= event_name and whitelist[decoded] == true then
            return true
        end
    end

    return false
end

function ConfigManager.whitelist_event(event_name)
    if not event_name then return false end
    local whitelist = get_event_whitelist()
    if not ConfigManager.is_event_whitelisted(event_name) then
        whitelist[event_name] = true
        sanitized_config_cache = build_sanitized_config()
        return true
    end
    return false
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

local vehicle_hash_lookup   = {}
local ped_hash_lookup       = {}
local object_hash_lookup    = {}
local particle_hash_lookup  = {}
local explosion_id_lookup   = {}

function ConfigManager.initialize_blacklist_lookups()
    vehicle_hash_lookup, ped_hash_lookup, object_hash_lookup = {}, {}, {}
    particle_hash_lookup, explosion_id_lookup = {}, {}

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

    -- O(1) lookup for particles: BlacklistedParticles is a list of strings or
    -- pre-computed hashes. Hash both forms so the caller can pass either.
    if config.BlacklistedParticles then
        for _, p in ipairs(config.BlacklistedParticles) do
            if type(p) == "number" then
                particle_hash_lookup[p] = true
            elseif type(p) == "string" then
                particle_hash_lookup[p] = true
                particle_hash_lookup[GetHashKey(p)] = true
            end
        end
    end

    -- O(1) lookup for explosions: keep the FULL entry as value so callers can
    -- still inspect limit/audio/invisible/scale/time without scanning.
    if config.Protection and config.Protection.BlacklistedExplosions then
        for _, e in ipairs(config.Protection.BlacklistedExplosions) do
            if e and e.id ~= nil then
                explosion_id_lookup[e.id] = e
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

---@param entityTypeName string "Object" | "Ped" | "Vehicle"
---@param modelHash number
---@return boolean whitelisted Si el modelo esta exento del anti-spam
function ConfigManager.is_spam_whitelisted(entityTypeName, modelHash)
    if not modelHash then return false end
    local sw = SecureServe.Module and SecureServe.Module.Entity and SecureServe.Module.Entity.SpamWhitelist
    if not sw then return false end
    local key = (entityTypeName == "Object" and "Objects")
        or (entityTypeName == "Ped" and "Peds")
        or (entityTypeName == "Vehicle" and "Vehicles")
        or nil
    if not key or not sw[key] then return false end
    if sw[key][modelHash] then return true end
    -- comprobar variante con/sin signo
    local alt = modelHash
    if alt < 0 then alt = alt + 4294967296 else alt = alt - 4294967296 end
    return sw[key][alt] == true
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
    if effect_hash == nil then return false end
    return particle_hash_lookup[effect_hash] == true
end

---@return table|nil entry The matching blacklist entry, or nil.
function ConfigManager.get_blacklisted_explosion(explosion_type)
    if explosion_type == nil then return nil end
    return explosion_id_lookup[explosion_type]
end

function ConfigManager.is_blacklisted_explosion(explosion_type)
    return ConfigManager.get_blacklisted_explosion(explosion_type) ~= nil
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
