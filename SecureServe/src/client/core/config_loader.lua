---@class ConfigLoaderModule
local ConfigLoader = {}

local Utils = require("shared/lib/utils")
local ClientLogger = require("client/core/client_logger")
local protection_count = {}

-- Initialize global variables
_G.SecureServeConfig = nil
_G.SecureServeLoaded = false
_G.SecureServeProtectionSettings = {}
_G.SecureServeInitCalled = false
_G.SecureServeAdminList = {}
_G.SecureServeLastAdminUpdate = 0

---@description Initialize the client-side config loader
function ConfigLoader.initialize()
    if _G.SecureServeInitCalled then return end
    _G.SecureServeInitCalled = true
    
    ClientLogger.info("^5[LOADING] ^3Client Config^7")
    
    TriggerServerEvent("requestConfig")
    
    RegisterNetEvent("receiveConfig", function(serverConfig)
        _G.SecureServeConfig = serverConfig
        _G.SecureServe = serverConfig
        ConfigLoader.process_config(serverConfig)
        _G.SecureServeLoaded = true
        ClientLogger.info("^5[SUCCESS] ^3Client Config^7 received from server")
    end)
    
    local attempts = 0
    local maxAttempts = 10
    
    while not _G.SecureServeLoaded and attempts < maxAttempts do
        Wait(1000)
        attempts = attempts + 1
        if not _G.SecureServeLoaded then
            TriggerServerEvent("requestConfig")
        end
    end
end

---@description Get config value with optional default
---@param key string The config key to get
---@param default any Optional default value if key doesn't exist
---@return any The config value or default
function ConfigLoader.get(key, default)
    if not _G.SecureServeLoaded or not _G.SecureServeConfig then
        return default
    end
    
    local parts = {}
    for part in key:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    local value = _G.SecureServeConfig
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
    return _G.SecureServeLoaded
end

---@description Get the entire config table
---@return table config The config table
function ConfigLoader.get_config()
    return _G.SecureServeConfig
end

---@description Get the SecureServe configuration
---@return table secureserve The SecureServe configuration
function ConfigLoader.get_secureserve()
    return _G.SecureServe
end

---@description Ensure settings are initialized
local function ensure_initialized()
    if not _G.SecureServeInitCalled then
        ConfigLoader.initialize()
        Wait(1000) 
    end
end

---@description Get protection setting directly from SecureServe.Protection.Simple
---@param name string The name of the protection
---@param property string The property to get
---@return any value The protection setting value
local function get_from_simple_protection(name, property)
    if not _G.SecureServe or not _G.SecureServe.Protection or not _G.SecureServe.Protection.Simple then
        return nil
    end
    
    for _, v in pairs(_G.SecureServe.Protection.Simple) do
        if v.protection == name then
            if property == "time" and type(v.time) ~= "number" and _G.SecureServe.BanTimes then
                return _G.SecureServe.BanTimes[v.time]
            elseif property == "webhook" and v.webhook == "" and _G.SecureServe.Webhooks then
                return _G.SecureServe.Webhooks.Simple
            else
                return v[property]
            end
        end
    end
    
    return nil
end

---@description Get a protection setting by name and property
---@param name string The name of the protection
---@param property string The property to get
---@return any value The protection setting value
function ConfigLoader.get_protection_setting(name, property)

    
    if not name or not property then
        return nil
    end
    
    if _G.SecureServeProtectionSettings[name] and _G.SecureServeProtectionSettings[name][property] ~= nil then
        return _G.SecureServeProtectionSettings[name][property]
    end
    
    if _G.SecureServeLoaded and _G.SecureServe and _G.SecureServe.Protection and _G.SecureServe.Protection.Simple then
        for _, v in pairs(_G.SecureServe.Protection.Simple) do
            if v.protection == name then
                local time = v.time
                if type(time) ~= "number" and _G.SecureServe.BanTimes then
                    time = _G.SecureServe.BanTimes[v.time]
                end
                
                local webhook = v.webhook
                if webhook == "" and _G.SecureServe.Webhooks then
                    webhook = _G.SecureServe.Webhooks.Simple
                end
                
                local settings = {
                    time = time,
                    limit = v.limit or 999,
                    webhook = webhook,
                    enabled = v.enabled,
                    default = v.default,
                    defaultr = v.defaultr,
                    tolerance = v.tolerance,
                    defaults = v.defaults,
                    dispatch = v.dispatch
                }
                
                _G.SecureServeProtectionSettings[name] = settings
                
                return settings[property]
            end
        end
    end
    
    return get_from_simple_protection(name, property)
end

---@param config table The received config from server
function ConfigLoader.process_config(config)
    if not config then return end
    
    _G.SecureServe = config 
    local SecureServe = _G.SecureServe
    
    _G.SecureServeProtectionSettings = _G.SecureServeProtectionSettings or {}
    
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
            ["time"] = time,
            ["limit"] = limit,
            ["webhook"] = webhook,
            ["enabled"] = enabled,
            ["default"] = default,
            ["defaultr"] = defaultr,
            ["tolerance"] = tolerance,
            ["defaults"] = defaults,
            ["dispatch"] = dispatch
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
    local SecureServe = _G.SecureServe  
    
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
    _G.SecureServeProtectionSettings[name] = settings
end

---@param player number The player ID to check
---@return boolean is_whitelisted Whether the player is whitelisted
function ConfigLoader.is_whitelisted(player_id)
    local player_id = player_id or GetPlayerServerId(PlayerId())
    
    local currentTime = GetGameTimer()
    if currentTime - _G.SecureServeLastAdminUpdate > 60000 then
        TriggerServerEvent("SecureServe:RequestAdminList")
        _G.SecureServeLastAdminUpdate = currentTime
    end
    
    if _G.SecureServeAdminList[tostring(player_id)] then
        return true
    end
    
    return false
end

RegisterNetEvent("SecureServe:ReceiveAdminList", function(adminList)
    _G.SecureServeAdminList = adminList
    _G.SecureServeLastAdminUpdate = GetGameTimer()
end)

Citizen.CreateThread(function()
    Citizen.Wait(2000) 
    TriggerServerEvent("SecureServe:RequestAdminList")
    _G.SecureServeLastAdminUpdate = GetGameTimer()
end)

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

    if not _G.SecureServeLoaded or not _G.SecureServeConfig then
        return false
    end
    
    model_hash = tostring(model_hash)
    
    if _G.SecureServeConfig.Protection and _G.SecureServeConfig.Protection.BlacklistedObjects then
        for _, blacklisted in pairs(_G.SecureServeConfig.Protection.BlacklistedObjects) do
            if tostring(blacklisted.hash) == model_hash then
                return true
            end
        end
    end
    
    if _G.SecureServeConfig.Protection and _G.SecureServeConfig.Protection.BlacklistedVehicles then
        for _, blacklisted in pairs(_G.SecureServeConfig.Protection.BlacklistedVehicles) do
            if tostring(blacklisted.hash) == model_hash then
                return true
            end
        end
    end
    
    if _G.SecureServeConfig.Protection and _G.SecureServeConfig.Protection.BlacklistedPeds then
        for _, blacklisted in pairs(_G.SecureServeConfig.Protection.BlacklistedPeds) do
            if tostring(blacklisted.hash) == model_hash then
                return true
            end
        end
    end
    
    return false
end

return ConfigLoader
