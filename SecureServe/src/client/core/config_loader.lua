---@class ConfigLoaderModule
ConfigLoader = {}

local ClientLogger = require("client/core/client_logger")
local menu_admin_requests = {}
local menu_admin_request_id = 0
local blacklist_model_hashes = {
    objects = {},
    vehicles = {},
    peds = {}
}

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

---@return number request_id The next menu admin request ID
local function next_menu_admin_request_id()
    menu_admin_request_id = menu_admin_request_id + 1
    return menu_admin_request_id
end

---@param list table|nil The blacklist entries
---@param target table The target lookup table
local function add_blacklist_hashes(list, target)
    if type(list) ~= "table" then
        return
    end
    
    for _, entry in pairs(list) do
        if type(entry) == "table" then
            local hash = entry.hash
            if not hash and entry.name then
                if type(entry.name) == "number" then
                    hash = entry.name
                else
                    hash = GetHashKey(entry.name)
                end
            end
            if hash then
                target[hash] = true
            end
        end
    end
end

---@description Build model blacklist hash lookups for fast checks
local function build_blacklist_hashes()
    blacklist_model_hashes.objects = {}
    blacklist_model_hashes.vehicles = {}
    blacklist_model_hashes.peds = {}
    
    if not SecureServe or not SecureServe.Protection then
        return
    end
    
    add_blacklist_hashes(SecureServe.Protection.BlacklistedObjects, blacklist_model_hashes.objects)
    add_blacklist_hashes(SecureServe.Protection.BlacklistedVehicles, blacklist_model_hashes.vehicles)
    add_blacklist_hashes(SecureServe.Protection.BlacklistedPeds, blacklist_model_hashes.peds)
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
    
    SecureServeProtectionSettings = {}
    
    if SecureServe and SecureServe.Protection and type(SecureServe.Protection.Simple) == "table" then
        for k, v in pairs(SecureServe.Protection.Simple) do
            if SecureServe.Webhooks and v.webhook == "" then
                SecureServe.Protection.Simple[k].webhook = SecureServe.Webhooks.Simple
            end
            if SecureServe.BanTimes and type(v.time) ~= "number" then
                SecureServe.Protection.Simple[k].time = SecureServe.BanTimes[v.time]
            end
            
            local name = SecureServe.Protection.Simple[k].protection
            local dispatch = SecureServe.Protection.Simple[k].dispatch
            local default = SecureServe.Protection.Simple[k].default
            local defaultr = SecureServe.Protection.Simple[k].defaultr
            local tolerance = SecureServe.Protection.Simple[k].tolerance
            local defaults = SecureServe.Protection.Simple[k].defaults
            local time = SecureServe.Protection.Simple[k].time
            if SecureServe.BanTimes and type(time) ~= "number" then
                time = SecureServe.BanTimes[v.time]
            end
            local limit = SecureServe.Protection.Simple[k].limit or 999
            local webhook = SecureServe.Protection.Simple[k].webhook
            if SecureServe.Webhooks and webhook == "" then
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
            
        end
    end

    ConfigLoader.process_blacklist_category("BlacklistedCommands")
    ConfigLoader.process_blacklist_category("BlacklistedSprites")
    ConfigLoader.process_blacklist_category("BlacklistedAnimDicts")
    ConfigLoader.process_blacklist_category("BlacklistedExplosions")
    ConfigLoader.process_blacklist_category("BlacklistedWeapons")
    ConfigLoader.process_blacklist_category("BlacklistedVehicles")
    ConfigLoader.process_blacklist_category("BlacklistedObjects")
    build_blacklist_hashes()
end

---@param category string The blacklist category to process
function ConfigLoader.process_blacklist_category(category)
    local SecureServe = SecureServe
    if not SecureServe or not SecureServe.Protection or type(SecureServe.Protection[category]) ~= "table" then
        return
    end
    
    for k, v in pairs(SecureServe.Protection[category]) do
        if SecureServe.Webhooks and v.webhook == "" then
            SecureServe.Protection[category][k].webhook = SecureServe.Webhooks[category]
        end
        if SecureServe.BanTimes and type(v.time) ~= "number" then
            SecureServe.Protection[category][k].time = SecureServe.BanTimes[v.time]
        end
                
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

RegisterNetEvent('SecureServe:ReturnMenuAdminStatus', function(request_id, result)
    if request_id == nil or menu_admin_requests[request_id] == nil then
        if type(request_id) == "boolean" then
            for pending_id, pending in pairs(menu_admin_requests) do
                menu_admin_requests[pending_id] = nil
                pending:resolve(request_id)
            end
        end
        return
    end
    
    local pending = menu_admin_requests[request_id]
    menu_admin_requests[request_id] = nil
    pending:resolve(result == true)
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
    local request_id = next_menu_admin_request_id()
    menu_admin_requests[request_id] = promise
    
    TriggerServerEvent('SecureServe:RequestMenuAdminStatus', player, request_id)
    
    SetTimeout(5000, function()
        if menu_admin_requests[request_id] == promise then
            menu_admin_requests[request_id] = nil
            promise:resolve(false)
        end
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
    
    if model_hash == nil then
        return false
    end
    
    local hash = tonumber(model_hash)
    if not hash then
        hash = GetHashKey(tostring(model_hash))
    end
    
    if blacklist_model_hashes.objects[hash] or blacklist_model_hashes.vehicles[hash] or blacklist_model_hashes.peds[hash] then
        return true
    end
    
    return false
end



RegisterClientCallback({
    eventName = 'SecureServe:RequestScreenshotUpload',
    eventCallback = function(quality, webhookUrl)
        local p = promise.new()
        local screenshot_export = (_G.exports and _G.exports['screencapture']) or (exports and exports['screencapture'])

        if not screenshot_export or type(screenshot_export.requestScreenshotUpload) ~= "function" then
            p:resolve(nil)
            return Citizen.Await(p)
        end
       
        screenshot_export:requestScreenshotUpload(webhookUrl, 'files[]', {
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
