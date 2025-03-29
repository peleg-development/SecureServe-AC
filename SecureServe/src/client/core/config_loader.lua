---@class ConfigLoaderModule
local ConfigLoader = {
    config = nil,
    loaded = false,
    protectionSettings = {},
    SecureServe = nil  
}

local Utils = require("shared/lib/utils")
local ClientLogger = require("client/core/client_logger")
local protection_count = {}

---@description Initialize the client-side config loader
function ConfigLoader.initialize()
    ClientLogger.info("^5[LOADING] ^3Client Config^7")
    
    TriggerServerEvent("requestConfig")
    
    RegisterNetEvent("receiveConfig", function(serverConfig)
        ConfigLoader.config = serverConfig
        ConfigLoader.loaded = true
        ConfigLoader.process_config(serverConfig)
        ClientLogger.info("^5[SUCCESS] ^3Client Config^7 received from server")
    end)
    
    local attempts = 0
    local maxAttempts = 10
    
    while not ConfigLoader.loaded do
        Wait(1000)
        attempts = attempts + 1
        if not ConfigLoader.loaded then
            TriggerServerEvent("requestConfig")
        end
    end
end

---@description Get config value with optional default
---@param key string The config key to get
---@param default any Optional default value if key doesn't exist
---@return any The config value or default
function ConfigLoader.get(key, default)
    if not ConfigLoader.loaded or not ConfigLoader.config then
        return default
    end
    
    local parts = {}
    for part in key:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    local value = ConfigLoader.config
    for _, part in ipairs(parts) do
        if type(value) ~= "table" then
            return default
        end
        value = value[part]
        if value == nil then
            return default
        end
    end
    
    return value
end

---@description Check if config has been loaded
---@return boolean is_loaded Whether config has been loaded
function ConfigLoader.is_loaded()
    return ConfigLoader.loaded
end

---@description Get the entire config table
---@return table config The config table
function ConfigLoader.get_config()
    return ConfigLoader.config
end

---@description Get the SecureServe configuration
---@return table secureserve The SecureServe configuration
function ConfigLoader.get_secureserve()
    return ConfigLoader.SecureServe
end

---@description Get a protection setting by name and property
---@param name string The name of the protection
---@param property string The property to get
---@return any value The protection setting value
function ConfigLoader.get_protection_setting(name, property)
    if not ConfigLoader.protectionSettings[name] then
        return nil
    end
    return ConfigLoader.protectionSettings[name][property]
end

---@param config table The received config from server
function ConfigLoader.process_config(config)
    
    if not config then return end
    ConfigLoader.SecureServe = config 
    local SecureServe = ConfigLoader.SecureServe
    
    for k, v in pairs(SecureServe.Protection.Simple) do
        if v.webhook == "" then
            SecureServe.Protection.Simple[k].webhook = SecureServe.Webhooks.Simple
        end
        if type(v.time) ~= "number" then
            SecureServe.Protection.Simple[k].time = SecureServe.BanTimes[v.time]
        end
        
        local name = SecureServe.Protection.Simple[k].protection
        local dispatch = SecureServe.Protection.Simple[k].dispatch
        local default = SecureServe.Protection.Simple[k].default
        local defaultr = SecureServe.Protection.Simple[k].defaultr
        local tolerance = SecureServe.Protection.Simple[k].tolerance
        local defaults = SecureServe.Protection.Simple[k].defaults
        local time = SecureServe.Protection.Simple[k].time
        if type(time) ~= "number" then
            time = SecureServe.BanTimes[v.time]
        end
        local limit = SecureServe.Protection.Simple[k].limit or 999
        local webhook = SecureServe.Protection.Simple[k].webhook
        if webhook == "" then
            webhook = SecureServe.Webhooks.Simple
        end
        local enabled = SecureServe.Protection.Simple[k].enabled
        ConfigLoader.assign_protection_settings(name, {
            time = time,
            limit = limit,
            webhook = webhook,
            enabled = enabled,
            default = default,
            defaultr = defaultr,
            tolerance = tolerance,
            defaults = defaults,
            dispatch = dispatch
        })
        
        if not protection_count["SecureServe.Protection.Simple"] then protection_count["SecureServe.Protection.Simple"] = 0 end
        protection_count["SecureServe.Protection.Simple"] = protection_count["SecureServe.Protection.Simple"] + 1
    end

    ConfigLoader.process_blacklist_category("BlacklistedCommands")
    
    ConfigLoader.process_blacklist_category("BlacklistedSprites")
    
    ConfigLoader.process_blacklist_category("BlacklistedAnimDicts")
    
    ConfigLoader.process_blacklist_category("BlacklistedExplosions")
    
    ConfigLoader.process_blacklist_category("BlacklistedWeapons")
    
    ConfigLoader.process_blacklist_category("BlacklistedVehicles")
    
    ConfigLoader.process_blacklist_category("BlacklistedObjects")
end

---@param category string The blacklist category to process
function ConfigLoader.process_blacklist_category(category)
    local SecureServe = ConfigLoader.SecureServe  
    
    for k, v in pairs(SecureServe.Protection[category]) do
        if v.webhook == "" then
            SecureServe.Protection[category][k].webhook = SecureServe.Webhooks[category]
        end
        if type(v.time) ~= "number" then
            SecureServe.Protection[category][k].time = SecureServe.BanTimes[v.time]
        end
                
        if not protection_count["SecureServe.Protection." .. category] then 
            protection_count["SecureServe.Protection." .. category] = 0 
        end
        protection_count["SecureServe.Protection." .. category] = protection_count["SecureServe.Protection." .. category] + 1
    end
end

---@param name string The name of the protection
---@param settings table The settings to assign
function ConfigLoader.assign_protection_settings(name, settings)
    -- Store protection settings in the module instead of _G
    ConfigLoader.protectionSettings[name] = settings
end

---@param player number The player ID to check
---@return boolean is_whitelisted Whether the player is whitelisted
function ConfigLoader.is_whitelisted(player_id)
    local SecureServe = ConfigLoader.SecureServe  
    
    if not SecureServe then
        return false
    end
    
    -- Check if player_id exists in the SecureServe.Whitelist table
    for _, whitelisted_player in ipairs(SecureServe.Whitelist) do
        if tonumber(whitelisted_player) == tonumber(player_id) then
            return true
        end
    end
    
    return false
end

---@param player number The player ID to check
---@return boolean is_menu_admin Whether the player is a menu admin
function ConfigLoader.is_menu_admin(player)
    local promise = promise.new()

    TriggerServerEvent('SecureServe:RequestMenuAdminStatus', player)

    RegisterNetEvent('SecureServe:ReturnMenuAdminStatus', function(result)
        promise:resolve(result)
    end)

    return Citizen.Await(promise)
end

---@description Check if a model is blacklisted
---@param model_hash string|number The model hash to check
---@return boolean is_blacklisted Whether the model is blacklisted
function ConfigLoader.is_model_blacklisted(model_hash)

    if not ConfigLoader.loaded or not ConfigLoader.config then
        return false
    end
    
    model_hash = tostring(model_hash)
    
    if ConfigLoader.config.Protection and ConfigLoader.config.Protection.BlacklistedObjects then
        for _, blacklisted in pairs(ConfigLoader.config.Protection.BlacklistedObjects) do
            if tostring(blacklisted.hash) == model_hash then
                return true
            end
        end
    end
    
    if ConfigLoader.config.Protection and ConfigLoader.config.Protection.BlacklistedVehicles then
        for _, blacklisted in pairs(ConfigLoader.config.Protection.BlacklistedVehicles) do
            if tostring(blacklisted.hash) == model_hash then
                return true
            end
        end
    end
    
    if ConfigLoader.config.Protection and ConfigLoader.config.Protection.BlacklistedPeds then
        for _, blacklisted in pairs(ConfigLoader.config.Protection.BlacklistedPeds) do
            if tostring(blacklisted.hash) == model_hash then
                return true
            end
        end
    end
    
    return false
end

return ConfigLoader