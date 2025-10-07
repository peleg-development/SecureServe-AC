---@class ConfigLoaderModule
ConfigLoader = {}

local Utils = require("shared/lib/utils")
local ClientLogger = require("client/core/client_logger")
local protection_count = {}

-- Initialize global variables
SecureServeConfig = nil
SecureServeLoaded = false
SecureServeProtectionSettings = {}
SecureServeInitCalled = false
SecureServeAdminList = {}
SecureServeLastAdminUpdate = 0

---@description Initialize the client-side config loader
function ConfigLoader.initialize()
    if SecureServeInitCalled then return end
    SecureServeInitCalled = true
    
    ClientLogger.info("^5[LOADING] ^3Client Config^7")
    
    TriggerServerEvent("requestConfig")
    
    RegisterNetEvent("receiveConfig", function(serverConfig)
        SecureServeConfig = serverConfig
        SecureServe = serverConfig
        ConfigLoader.process_config(serverConfig)
        SecureServeLoaded = true
        ClientLogger.info("^5[SUCCESS] ^3Client Config^7 received from server")
    end)
    
    local attempts = 0
    local maxAttempts = 10
    
    while not SecureServeLoaded and attempts < maxAttempts do
        Wait(1000)
        attempts = attempts + 1
        if not SecureServeLoaded then
            TriggerServerEvent("requestConfig")
        end
    end
end

---@description Get config value with optional default
---@param key string The config key to get
---@param default any Optional default value if key doesn't exist
---@return any The config value or default
function ConfigLoader.get(key, default)
    if not SecureServeLoaded or not SecureServeConfig then
        return default
    end
    
    local parts = {}
    for part in key:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    local value = SecureServeConfig
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
    return SecureServeLoaded
end

---@description Get the entire config table
---@return table config The config table
function ConfigLoader.get_config()
    return SecureServeConfig
end

---@description Get the SecureServe configuration
---@return table secureserve The SecureServe configuration
function ConfigLoader.get_secureserve()
    return SecureServe
end

---@description Ensure settings are initialized
local function ensure_initialized()
    if not SecureServeInitCalled then
        ConfigLoader.initialize()
        Wait(1000) 
    end
end

---@description Get protection setting directly from SecureServe.Protection.Simple
---@param name string The name of the protection
---@param property string The property to get
---@return any value The protection setting value
local function get_from_simple_protection(name, property)
    if not SecureServe or not SecureServe.Protection or not SecureServe.Protection.Simple then
        return nil
    end
    
    for _, v in pairs(SecureServe.Protection.Simple) do
        if v.protection == name then
            if property == "time" and type(v.time) ~= "number" and SecureServe.BanTimes then
                return SecureServe.BanTimes[v.time]
            elseif property == "webhook" and v.webhook == "" and SecureServe.Webhooks then
                return SecureServe.Webhooks.Simple
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
    
    if SecureServeProtectionSettings[name] and SecureServeProtectionSettings[name][property] ~= nil then
        return SecureServeProtectionSettings[name][property]
    end
    
    if SecureServeLoaded and SecureServe and SecureServe.Protection and SecureServe.Protection.Simple then
        for _, v in pairs(SecureServe.Protection.Simple) do
            if v.protection == name then
                local time = v.time
                if type(time) ~= "number" and SecureServe.BanTimes then
                    time = SecureServe.BanTimes[v.time]
                end
                
                local webhook = v.webhook
                if webhook == "" and SecureServe.Webhooks then
                    webhook = SecureServe.Webhooks.Simple
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
                
                SecureServeProtectionSettings[name] = settings
                
                return settings[property]
            end
        end
    end
    
    return get_from_simple_protection(name, property)
end

---@param config table The received config from server
function ConfigLoader.process_config(config)
    if not config then return end
    
    SecureServe = config 
    local SecureServe = SecureServe
    
    SecureServeProtectionSettings = SecureServeProtectionSettings or {}
    
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
    local SecureServe = SecureServe  
    
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
    SecureServeProtectionSettings[name] = settings
end

---@param player number The player ID to check
---@return boolean is_whitelisted Whether the player is whitelisted
function ConfigLoader.is_whitelisted(player_id)
    local player_id = player_id or GetPlayerServerId(PlayerId())
    
    local currentTime = GetGameTimer()
    if currentTime - SecureServeLastAdminUpdate > 60000 then
        TriggerServerEvent("SecureServe:RequestAdminList")
        SecureServeLastAdminUpdate = currentTime
    end
    
    if SecureServeAdminList[tostring(player_id)] then
        return true
    end
    
    return false
end

RegisterNetEvent("SecureServe:ReceiveAdminList", function(adminList)
    SecureServeAdminList = adminList
    SecureServeLastAdminUpdate = GetGameTimer()
end)

Citizen.CreateThread(function()
    Citizen.Wait(2000) 
    TriggerServerEvent("SecureServe:RequestAdminList")
    SecureServeLastAdminUpdate = GetGameTimer()
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

    if not SecureServeLoaded or not SecureServeConfig then
        return false
    end
    
    model_hash = tostring(model_hash)
    
    if SecureServeConfig.Protection and SecureServeConfig.Protection.BlacklistedObjects then
        for _, blacklisted in pairs(SecureServeConfig.Protection.BlacklistedObjects) do
            if tostring(blacklisted.hash) == model_hash then
                return true
            end
        end
    end
    
    if SecureServeConfig.Protection and SecureServeConfig.Protection.BlacklistedVehicles then
        for _, blacklisted in pairs(SecureServeConfig.Protection.BlacklistedVehicles) do
            if tostring(blacklisted.hash) == model_hash then
                return true
            end
        end
    end
    
    if SecureServeConfig.Protection and SecureServeConfig.Protection.BlacklistedPeds then
        for _, blacklisted in pairs(SecureServeConfig.Protection.BlacklistedPeds) do
            if tostring(blacklisted.hash) == model_hash then
                return true
            end
        end
    end
    
    return false
end



RegisterClientCallback({
    eventName = 'SecureServe:RequestScreenshotUpload',
    eventCallback = function(quality, webhookUrl)
        local p = promise.new()
       
        _G.exports['screenshot-basic']:requestScreenshotUpload(webhookUrl, 'files[]', {
            encoding = 'jpg',
            quality = quality or 0.95
        }, function(data)
            if data and data ~= "" then
                local success, resp = pcall(json.decode, data)
                
                if success and resp and resp.attachments and resp.attachments[1] and resp.attachments[1].proxy_url then
                    local screenshot_url = resp.attachments[1].proxy_url
                    p:resolve(screenshot_url)
                else
                    p:resolve(nil)
                end
            else
                p:resolve(nil)
            end
        end)
        
        return Citizen.Await(p)
    end
})