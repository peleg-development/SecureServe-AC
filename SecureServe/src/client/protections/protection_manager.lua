local ConfigLoader = require("client/core/config_loader")
local Utils = require("shared/lib/utils")
local logger = require("client/core/client_logger")

---@class ProtectionManagerModule
local ProtectionManager = {
    protections = {},
    initialized = {},
    memory_check_thread = nil,
    last_gc_time = 0,
    gc_interval = 60000,  
    protection_priorities = {
        critical = {},    
        high = {},        
        medium = {},     
        low = {}          
    },
    active_threads = {}
}

---@description Register a protection with the manager
---@param name string The protection module name
---@param init_function function The function to initialize the protection
---@param priority string Optional priority level (critical, high, medium, low)
function ProtectionManager.register_protection(name, init_function, priority)
    ProtectionManager.protections[name] = init_function
    
    priority = priority or "medium"
    
    if ProtectionManager.protection_priorities[priority] then
        ProtectionManager.protection_priorities[priority][name] = true
    else
        ProtectionManager.protection_priorities["medium"][name] = true
    end
    
    logger.info("Registered protection module: " .. name .. " with priority: " .. priority)
end

---@description Create a stub protection module
---@param module_name string The protection module name
---@return table The stub module
function ProtectionManager.create_stub_module(module_name)
    local clean_name = module_name:gsub("anti_", "")
    local pascal_case_name = clean_name:gsub("_(%l)", function(l) return l:upper() end):gsub("^%l", string.upper)
    
    local stub_module = {
        initialize = function()
            logger.debug(pascal_case_name .. " protection module is a stub")
        end
    }
    
    ProtectionManager.register_protection(clean_name, stub_module.initialize, "low")
    
    return stub_module
end

function ProtectionManager.start_memory_manager()
    if ProtectionManager.memory_check_thread then
        TerminateThread(ProtectionManager.memory_check_thread)
    end
    
    ProtectionManager.last_gc_time = GetGameTimer()
    
    ProtectionManager.memory_check_thread = Citizen.CreateThread(function()
        while true do
            Citizen.Wait(30000)  
            
            local current_time = GetGameTimer()
            if (current_time - ProtectionManager.last_gc_time) < ProtectionManager.gc_interval then
                if logger.debug_enabled then
                    local memory_usage = collectgarbage("count")
                    logger.debug(string.format("Memory usage: %.2f KB", memory_usage))
                end
                goto continue
            end
            
            collectgarbage("step", 100)
            ProtectionManager.last_gc_time = current_time
            
            Citizen.Wait(15000)  
            
            ::continue::
        end
    end)
end

local function groupProtectionModules(modules)
    local groups = {
        entity = {}, 
        weapon = {}, 
        movement = {}, 
        resource = {}, 
        other = {}  
    }
    
    for _, name in ipairs(modules) do
        if name:match("entity") or name:match("ai") or name:match("invisible") then
            table.insert(groups.entity, name)
        elseif name:match("weapon") or name:match("damage") or name:match("bullet") or name:match("reload") or name:match("recoil") then
            table.insert(groups.weapon, name)
        elseif name:match("speed") or name:match("teleport") or name:match("noclip") or name:match("freecam") then
            table.insert(groups.movement, name)
        elseif name:match("resource") or name:match("event") then
            table.insert(groups.resource, name)
        else
            table.insert(groups.other, name)
        end
    end
    
    return groups
end

---@description Initialize protections in groups to optimize loading
function ProtectionManager.initialize()
    logger.info("Loaded Cache system")
    
    ProtectionManager.start_memory_manager()
    ProtectionManager.initialize_heartbeat() 

    local protection_modules = {
        "anti_load_resource_file",
        "anti_ocr",
        "anti_invisible",
        "anti_no_reload",
        "anti_explosion_bullet",
        "anti_entity_security",
        "anti_magic_bullet",
        "anti_aim_assist",
        "anti_noclip",
        "anti_resource_stop",
        "anti_god_mode",
        "anti_spectate",
        "anti_freecam",
        "anti_teleport",
        "anti_weapon_damage_modifier",
        "anti_afk_injection",
        "anti_ai",
        "anti_bigger_hitbox",
        "anti_no_recoil",
        "anti_player_blips",
        "anti_give_weapon",
        "anti_speed_hack",
        "anti_state_bag_overflow",
        "anti_visions",
        "anti_weapon_pickup"
    }
    
    local groups = groupProtectionModules(protection_modules)
    
    for category, modules in pairs(groups) do
        logger.info("Loading " .. category .. " protection modules...")
        
        for _, module_name in ipairs(modules) do
            local success, module = pcall(function() 
                return require("client/protections/" .. module_name)
            end)
            
            if success and module then
                local clean_name = module_name:gsub("anti_", "")
                if module.initialize then
                    -- Auto-assign priority based on category
                    local priority = "medium"
                    if category == "entity" or category == "weapon" then
                        priority = "high"
                    elseif category == "movement" then
                        priority = "critical"
                    elseif category == "resource" then
                        priority = "low"
                    end
                    
                    ProtectionManager.register_protection(clean_name, module.initialize, priority)
                else
                    logger.warn("Protection module missing initialize function: " .. module_name)
                    ProtectionManager.create_stub_module(module_name)
                end
            else
                ProtectionManager.create_stub_module(module_name)
            end
            
            Citizen.Wait(25)
        end
        
        Citizen.Wait(100)
        collectgarbage("step", 25)  
    end
    
    logger.info("Initializing protection modules...")
    
    -- Start protection schedulers by priority
    ProtectionManager.start_protection_schedulers()
end

function ProtectionManager.start_protection_schedulers()
    local priority_config = {
        critical = { interval = 1200, jitter = 300 },   
        high = { interval = 2600, jitter = 400 },      
        medium = { interval = 5200, jitter = 800 },    
        low = { interval = 12000, jitter = 3000 }     
    }
    
    for name, init_func in pairs(ProtectionManager.protections) do
        ProtectionManager.initialize_protection(name, init_func)
        Citizen.Wait(50)
    end
    
    for priority, config in pairs(priority_config) do
        ProtectionManager.active_threads[priority] = Citizen.CreateThread(function()
            Citizen.Wait(math.random(100, 1000))
            
            while true do
                local start_time = GetGameTimer()
                local count = 0
                
                for name, _ in pairs(ProtectionManager.protection_priorities[priority]) do
                    if ProtectionManager.initialized[name] then
                        local module = require("client/protections/anti_" .. name)
                        if module and module.update then
                            local success = pcall(function()
                                module.update()
                            end)
                            
                            if not success and logger.debug_enabled then
                                logger.debug("Failed to update protection: " .. name)
                            end
                        end
                        
                        count = count + 1
                        if count % 3 == 0 then
                            Citizen.Wait(50)
                        end
                    end
                end
                
                local runtime = GetGameTimer() - start_time
                local next_interval = config.interval + math.random(0, config.jitter) - runtime
                
                next_interval = math.max(100, next_interval)
                
                Citizen.Wait(next_interval)
            end
        end)
    end
    
    local initialized_count = 0
    for _ in pairs(ProtectionManager.initialized) do
        initialized_count = initialized_count + 1
    end
    
    logger.info("Initialized " .. initialized_count .. " out of " .. #protection_modules .. " protection modules")
    collectgarbage("step", 50)
end

function ProtectionManager.initialize_protection(name, init_func)
    if ProtectionManager.initialized[name] then return end
    
    local success, error_msg = pcall(function()
        init_func()
    end)
    
    if success then
        ProtectionManager.initialized[name] = true
        logger.info("Protection module initialized: " .. name)
    else
        logger.error("Failed to initialize protection module: " .. name .. " - " .. tostring(error_msg))
    end
end

---@param reason string Reason for taking the screenshot
---@param id string|nil Optional ID for the screenshot
---@param webhook string Webhook URL to send the screenshot to
---@param time number Ban time in seconds
function ProtectionManager.take_screenshot(reason, id, webhook, time)
    logger.info("Taking screenshot for " .. reason)
    
    local fallback_image = "https://media.discordapp.net/attachments/1234504751173865595/1237372961263190106/screenshot.jpg?ex=663b68df&is=663a175f&hm=52ec8f2d1e6e012e7a8282674b7decbd32344d85ba57577b12a136d34469ee9a&=&format=webp&width=810&height=456"
    
    local exports_available = exports and exports['screenshot-basic']
    if not exports_available then
        logger.error("Failed to take screenshot: screenshot-basic export not available")
        TriggerServerEvent('SecureServe:Server:Methods:Upload', fallback_image, reason, id, time)
        return
    end
    
    local success, error = pcall(function()
        exports['screenshot-basic']:requestScreenshotUpload('https://canary.discord.com/api/webhooks/1237780232036155525/kUDGaCC8SRewCy5fC9iQpDFICxbqYgQS9Y7mj8EhRCv91nqpAyADkhaApGNHa3jZ9uMF', 'files[]', function(data)
            local resp = json.decode(data)
            if resp ~= nil and resp.attachments ~= nil and resp.attachments[1] ~= nil and resp.attachments[1].proxy_url ~= nil then
                local screenshot_url = resp.attachments[1].proxy_url
                logger.info("Screenshot uploaded successfully")
                TriggerServerEvent('SecureServe:Server:Methods:Upload', screenshot_url, reason, id, webhook, time)
                ForceSocialClubUpdate() 
            else
                logger.error("Failed to upload screenshot, using fallback")
                TriggerServerEvent('SecureServe:Server:Methods:Upload', fallback_image, reason, id, time)
                ForceSocialClubUpdate()
            end
        end)
    end)
    
    if not success then
        logger.error("Error taking screenshot: " .. tostring(error))
        TriggerServerEvent('SecureServe:Server:Methods:Upload', fallback_image, reason, id, time)
    end
end

function ProtectionManager.initialize_heartbeat()
    local player_spawned = false
    
    AddEventHandler('playerSpawned', function()
        if player_spawned then return end
        player_spawned = true
        
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(5000) 
                local player_ped = PlayerPedId()
                if DoesEntityExist(player_ped) then
                    SetEntityProofs(player_ped, false, false, true, false, false, false, false, false)
                end
            end
        end)
        
        TriggerServerEvent("playerSpawneda")
        TriggerEvent('allowed')
    end)
    
    RegisterNetEvent('SecureServe:checkTaze', function()
        -- Get configuration from ConfigLoader
        local webhook = ConfigLoader.get_secureserve().Webhooks.Simple
        
        if not HasPedGotWeapon(PlayerPedId(), GetHashKey("WEAPON_STUNGUN"), false) then
            logger.warn("Detected taze through menu attempt")
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Tried To taze through menu", webhook, 2147483647)
        end
    end)
    
    AddEventHandler("gameEventTriggered", function(name, args)
        if name == 'CEventNetworkPlayerCollectedPickup' then
            logger.debug("Canceled CEventNetworkPlayerCollectedPickup event")
            CancelEvent()
        end
    end)
    
    local heartbeat_token = Utils.random_key(math.random(15, 35))
    TriggerServerEvent('mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS', heartbeat_token)
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(15 * 1000)
            heartbeat_token = Utils.random_key(math.random(15, 35))
            TriggerServerEvent('mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS', heartbeat_token)
        end
    end)

    RegisterNUICallback(GetCurrentResourceName(), function()
        -- Get configuration from ConfigLoader
        local webhook = ConfigLoader.get_secureserve().Webhooks.Simple
        
        logger.warn("NUI Dev Tool usage detected")
        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Tried To Use Nui Dev Tool", webhook, 2147483647)
    end)
    
    Citizen.CreateThread(function()
        TriggerServerEvent('playerLoaded')
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if ProtectionManager.memory_check_thread then
        TerminateThread(ProtectionManager.memory_check_thread)
        ProtectionManager.memory_check_thread = nil
    end
    
    ProtectionManager.protections = {}
    ProtectionManager.initialized = {}
    
    collectgarbage("collect")
end)

RegisterNetEvent('SecureServe:Server:Methods:GetScreenShot', ProtectionManager.take_screenshot)

return ProtectionManager