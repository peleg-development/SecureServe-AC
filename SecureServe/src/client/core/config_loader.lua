---@class ConfigLoaderModule
local ConfigLoader = {
    config = nil,
    loaded = false
}

local Utils = require("shared/lib/utils")
local protection_count = {}

---@description Initialize the client-side config loader
function ConfigLoader.initialize()
    print("^5[LOADING] ^3Client Config^7")
    
    TriggerServerEvent("requestConfig")
    
    RegisterNetEvent("receiveConfig", function(serverConfig)
        ConfigLoader.config = serverConfig
        ConfigLoader.loaded = true
        ConfigLoader.process_config(serverConfig)
        print("^5[SUCCESS] ^3Client Config^7 received from server")
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

---@param config table The received config from server
function ConfigLoader.process_config(config)
    if not config then return end
    _G.SecureServe = config
    
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
    if name == "Anti Give Weapon" then
        _G.Anti_Give_Weapon_time = settings.time
        _G.Anti_Give_Weapon_limit = settings.limit
        _G.Anti_Give_Weapon_webhook = settings.webhook
        _G.Anti_Give_Weapon_enabled = settings.enabled
    elseif name == "Anti Remove Weapon" then
        _G.Anti_Remove_Weapon_time = settings.time
        _G.Anti_Remove_Weapon_limit = settings.limit
        _G.Anti_Remove_Weapon_webhook = settings.webhook
        _G.Anti_Remove_Weapon_enabled = settings.enabled
    elseif name == "Anti Player Blips" then
        _G.Anti_Player_Blips_time = settings.time
        _G.Anti_Player_Blips_limit = settings.limit
        _G.Anti_Player_Blips_webhook = settings.webhook
        _G.Anti_Player_Blips_enabled = settings.enabled
    elseif name == "Anti Car Fly" then
        _G.Anti_Car_Fly_time = settings.time
        _G.Anti_Car_Fly_limit = settings.limit
        _G.Anti_Car_Fly_webhook = settings.webhook
        _G.Anti_Car_Fly_enabled = settings.enabled
    elseif name == "Anti Car Ram" then
        _G.Anti_Car_Ram_time = settings.time
        _G.Anti_Car_Ram_limit = settings.limit
        _G.Anti_Car_Ram_webhook = settings.webhook
        _G.Anti_Car_Ram_enabled = settings.enabled
    elseif name == "Anti Particles" then
        _G.Anti_Particles_time = settings.time
        _G.Anti_Particles_limit = settings.limit
        _G.Anti_Particles_webhook = settings.webhook
        _G.Anti_Particles_enabled = settings.enabled
    elseif name == "Anti Internal" then
        _G.Anti_Internal_time = settings.time
        _G.Anti_Internal_limit = settings.limit
        _G.Anti_Internal_webhook = settings.webhook
        _G.Anti_Internal_enabled = settings.enabled
    elseif name == "Anti Damage Modifier" then
        _G.Anti_Damage_Modifier_default = settings.default
        _G.Anti_Damage_Modifier_time = settings.time
        _G.Anti_Damage_Modifier_limit = settings.limit
        _G.Anti_Damage_Modifier_webhook = settings.webhook
        _G.Anti_Damage_Modifier_enabled = settings.enabled
    elseif name == "Anti Weapon Pickup" then
        _G.Anti_Weapon_Pickup_time = settings.time
        _G.Anti_Weapon_Pickup_limit = settings.limit
        _G.Anti_Weapon_Pickup_webhook = settings.webhook
        _G.Anti_Weapon_Pickup_enabled = settings.enabled
    elseif name == "Anti Remove From Car" then
        _G.Anti_Remove_From_Car_time = settings.time
        _G.Anti_Remove_From_Car_limit = settings.limit
        _G.Anti_Remove_From_Car_webhook = settings.webhook
        _G.Anti_Remove_From_Car_enabled = settings.enabled
    elseif name == "Anti Spectate" then
        _G.Anti_Spectate_time = settings.time
        _G.Anti_Spectate_limit = settings.limit
        _G.Anti_Spectate_webhook = settings.webhook
        _G.Anti_Spectate_enabled = settings.enabled
    elseif name == "Anti Freecam" then
        _G.Anti_Freecam_time = settings.time
        _G.Anti_Freecam_limit = settings.limit
        _G.Anti_Freecam_webhook = settings.webhook
        _G.Anti_Freecam_enabled = settings.enabled
    elseif name == "Anti Explosion Bullet" then
        _G.Anti_Explosion_Bullet_time = settings.time
        _G.Anti_Explosion_Bullet_limit = settings.limit
        _G.Anti_Explosion_Bullet_webhook = settings.webhook
        _G.Anti_Explosion_Bullet_enabled = settings.enabled
    elseif name == "Anti Magic Bullet" then
        _G.Anti_Magic_Bullet_time = settings.time
        _G.Anti_Magic_Bullet_limit = settings.limit
        _G.Anti_Magic_Bullet_webhook = settings.webhook
        _G.Anti_Magic_Bullet_enabled = settings.enabled
        _G.Anti_Magic_Bullet_tolerance = settings.tolerance
    elseif name == "Anti Night Vision" then
        _G.Anti_Night_Vision_time = settings.time
        _G.Anti_Night_Vision_limit = settings.limit
        _G.Anti_Night_Vision_webhook = settings.webhook
        _G.Anti_Night_Vision_enabled = settings.enabled
    elseif name == "Anti Thermal Vision" then
        _G.Anti_Thermal_Vision_time = settings.time
        _G.Anti_Thermal_Vision_limit = settings.limit
        _G.Anti_Thermal_Vision_webhook = settings.webhook
        _G.Anti_Thermal_Vision_enabled = settings.enabled
    elseif name == "Anti God Mode" then
        _G.Anti_God_Mode_time = settings.time
        _G.Anti_God_Mode_limit = settings.limit
        _G.Anti_God_Mode_webhook = settings.webhook
        _G.Anti_God_Mode_enabled = settings.enabled
    elseif name == "Anti Infinite Ammo" then
        _G.Anti_Infinite_Ammo_time = settings.time
        _G.Anti_Infinite_Ammo_limit = settings.limit
        _G.Anti_Infinite_Ammo_webhook = settings.webhook
        _G.Anti_Infinite_Ammo_enabled = settings.enabled
    elseif name == "Anti Teleport" then
        _G.Anti_Teleport_time = settings.time
        _G.Anti_Teleport_limit = settings.limit
        _G.Anti_Teleport_webhook = settings.webhook
        _G.Anti_Teleport_enabled = settings.enabled
    elseif name == "Anti Invisible" then
        _G.Anti_Invisible_time = settings.time
        _G.Anti_Invisible_limit = settings.limit
        _G.Anti_Invisible_webhook = settings.webhook
        _G.Anti_Invisible_enabled = settings.enabled
    elseif name == "Anti Resource Stopper" then
        _G.Anti_Resource_Stopper_dispatch = settings.dispatch
        _G.Anti_Resource_Stopper_time = settings.time
        _G.Anti_Resource_Stopper_limit = settings.limit
        _G.Anti_Resource_Stopper_webhook = settings.webhook
        _G.Anti_Resource_Stopper_enabled = settings.enabled
    elseif name == "Anti Resource Starter" then
        _G.Anti_Resource_Starter_dispatch = settings.dispatch
        _G.Anti_Resource_Starter_time = settings.time
        _G.Anti_Resource_Starter_limit = settings.limit
        _G.Anti_Resource_Starter_webhook = settings.webhook
        _G.Anti_Resource_Starter_enabled = settings.enabled
    elseif name == "Anti Vehicle God Mode" then
        _G.Anti_Vehicle_God_Mode_time = settings.time
        _G.Anti_Vehicle_God_Mode_limit = settings.limit
        _G.Anti_Vehicle_God_Mode_webhook = settings.webhook
        _G.Anti_Vehicle_God_Mode_enabled = settings.enabled
    elseif name == "Anti Vehicle Power Increase" then
        _G.Anti_Vehicle_Power_Increase_time = settings.time
        _G.Anti_Vehicle_Power_Increase_limit = settings.limit
        _G.Anti_Vehicle_Power_Increase_webhook = settings.webhook
        _G.Anti_Vehicle_Power_Increase_enabled = settings.enabled
    elseif name == "Anti Speed Hack" then
        _G.Anti_Speed_Hack_time = settings.time
        _G.Anti_Speed_Hack_limit = settings.limit
        _G.Anti_Speed_Hack_webhook = settings.webhook
        _G.Anti_Speed_Hack_defaultr = settings.defaultr
        _G.Anti_Speed_Hack_defaults = settings.defaults
        _G.Anti_Speed_Hack_enabled = settings.enabled
    elseif name == "Anti Vehicle Spawn" then
        _G.Anti_Vehicle_Spawn_time = settings.time
        _G.Anti_Vehicle_Spawn_limit = settings.limit
        _G.Anti_Vehicle_Spawn_webhook = settings.webhook
        _G.Anti_Vehicle_Spawn_enabled = settings.enabled
    elseif name == "Anti Ped Spawn" then
        _G.Anti_Ped_Spawn_time = settings.time
        _G.Anti_Ped_Spawn_limit = settings.limit
        _G.Anti_Ped_Spawn_webhook = settings.webhook
        _G.Anti_Ped_Spawn_enabled = settings.enabled
    elseif name == "Anti Plate Changer" then
        _G.Anti_Plate_Changer_time = settings.time
        _G.Anti_Plate_Changer_limit = settings.limit
        _G.Anti_Plate_Changer_webhook = settings.webhook
        _G.Anti_Plate_Changer_enabled = settings.enabled
    elseif name == "Anti Cheat Engine" then
        _G.Anti_Cheat_Engine_time = settings.time
        _G.Anti_Cheat_Engine_limit = settings.limit
        _G.Anti_Cheat_Engine_webhook = settings.webhook
        _G.Anti_Cheat_Engine_enabled = settings.enabled
    elseif name == "Anti Rage" then
        _G.Anti_Rage_time = settings.time
        _G.Anti_Rage_limit = settings.limit
        _G.Anti_Rage_webhook = settings.webhook
        _G.Anti_Rage_enabled = settings.enabled
    elseif name == "Anti Aim Assist" then
        _G.Anti_Aim_Assist_time = settings.time
        _G.Anti_Aim_Assist_limit = settings.limit
        _G.Anti_Aim_Assist_webhook = settings.webhook
        _G.Anti_Aim_Assist_enabled = settings.enabled
    elseif name == "Anti Kill All" then
        _G.Anti_Kill_All_time = settings.time
        _G.Anti_Kill_All_limit = settings.limit
        _G.Anti_Kill_All_webhook = settings.webhook
        _G.Anti_Kill_All_enabled = settings.enabled
    elseif name == "Anti Solo Session" then
        _G.Anti_Solo_Session_time = settings.time
        _G.Anti_Solo_Session_limit = settings.limit
        _G.Anti_Solo_Session_webhook = settings.webhook
        _G.Anti_Solo_Session_enabled = settings.enabled
    elseif name == "Anti AI" then
        _G.Anti_AI_default = settings.default
        _G.Anti_AI_time = settings.time
        _G.Anti_AI_limit = settings.limit
        _G.Anti_AI_webhook = settings.webhook
        _G.Anti_AI_enabled = settings.enabled
    elseif name == "Anti No Reload" then
        _G.Anti_No_Reload_time = settings.time
        _G.Anti_No_Reload_limit = settings.limit
        _G.Anti_No_Reload_webhook = settings.webhook
        _G.Anti_No_Reload_enabled = settings.enabled
    elseif name == "Anti Rapid Fire" then
        _G.Anti_Rapid_Fire_time = settings.time
        _G.Anti_Rapid_Fire_limit = settings.limit
        _G.Anti_Rapid_Fire_webhook = settings.webhook
        _G.Anti_Rapid_Fire_enabled = settings.enabled
    elseif name == "Anti Bigger Hitbox" then
        _G.Anti_Bigger_Hitbox_default = settings.default
        _G.Anti_Bigger_Hitbox_time = settings.time
        _G.Anti_Bigger_Hitbox_limit = settings.limit
        _G.Anti_Bigger_Hitbox_webhook = settings.webhook
        _G.Anti_Bigger_Hitbox_enabled = settings.enabled
    elseif name == "Anti No Recoil" then
        _G.Anti_No_Recoil_default = settings.default
        _G.Anti_No_Recoil_time = settings.time
        _G.Anti_No_Recoil_limit = settings.limit
        _G.Anti_No_Recoil_webhook = settings.webhook
        _G.Anti_No_Recoil_enabled = settings.enabled
    elseif name == "Anti State Bag Overflow" then
        _G.Anti_State_Bag_Overflow_time = settings.time
        _G.Anti_State_Bag_Overflow_limit = settings.limit
        _G.Anti_State_Bag_Overflow_webhook = settings.webhook
        _G.Anti_State_Bag_Overflow_enabled = settings.enabled
    elseif name == "Anti Extended NUI Devtools" then
        _G.Anti_Extended_NUI_Devtools_time = settings.time
        _G.Anti_Extended_NUI_Devtools_limit = settings.limit
        _G.Anti_Extended_NUI_Devtools_webhook = settings.webhook
        _G.Anti_Extended_NUI_Devtools_enabled = settings.enabled
    elseif name == "Anti No Ragdoll" then
        _G.Anti_No_Ragdoll_time = settings.time
        _G.Anti_No_Ragdoll_limit = settings.limit
        _G.Anti_No_Ragdoll_webhook = settings.webhook
        _G.Anti_No_Ragdoll_enabled = settings.enabled
    elseif name == "Anti Super Jump" then
        _G.Anti_Super_Jump_time = settings.time
        _G.Anti_Super_Jump_limit = settings.limit
        _G.Anti_Super_Jump_webhook = settings.webhook
        _G.Anti_Super_Jump_enabled = settings.enabled
    elseif name == "Anti Noclip" then
        _G.Anti_Noclip_time = settings.time
        _G.Anti_Noclip_limit = settings.limit
        _G.Anti_Noclip_webhook = settings.webhook
        _G.Anti_Noclip_enabled = settings.enabled
    elseif name == "Anti Infinite Stamina" then
        _G.Anti_Infinite_Stamina_time = settings.time
        _G.Anti_Infinite_Stamina_limit = settings.limit
        _G.Anti_Infinite_Stamina_webhook = settings.webhook
        _G.Anti_Infinite_Stamina_enabled = settings.enabled
    elseif name == "Anti AFK Injection" then
        _G.Anti_AFK_time = settings.time
        _G.Anti_AFK_limit = settings.limit
        _G.Anti_AFK_webhook = settings.webhook
        _G.Anti_AFK_enabled = settings.enabled
    elseif name == "Anti Play Sound" then
        _G.Anti_Play_Sound_time = settings.time
        _G.Anti_Play_Sound_webhook = settings.webhook
        _G.Anti_Play_Sound_enabled = settings.enabled
    end
end

---@param player number The player ID to check
---@return boolean is_whitelisted Whether the player is whitelisted
function ConfigLoader.is_whitelisted(player)
    local promise = promise.new()
    
    TriggerServerEvent('SecureServe:RequestAdminStatus', player)
    RegisterNetEvent('SecureServe:ReturnAdminStatus', function(result)
        promise:resolve(result)
    end)

    return Citizen.Await(promise)
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

---@description Check if a player is whitelisted
---@param player_id number The player server ID to check
---@return boolean is_whitelisted Whether the player is whitelisted
function ConfigLoader.is_whitelisted(player_id)
    if not ConfigLoader.loaded or not ConfigLoader.config then
        return false
    end
    
    if not ConfigLoader.config.Whitelisted then
        return false
    end
    
    for _, id in ipairs(ConfigLoader.config.Whitelisted) do
        if tonumber(id) == tonumber(player_id) then
            return true
        end
    end
    
    return false
end

return ConfigLoader 