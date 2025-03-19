local ConfigLoader = require("client/core/config_loader")
local Utils = require("shared/lib/utils")

---@class ProtectionManagerModule
local ProtectionManager = {
    protections = {},
    initialized = {}
}

---@description Register a protection with the manager
---@param name string The protection module name
---@param init_function function The function to initialize the protection
function ProtectionManager.register_protection(name, init_function)
    ProtectionManager.protections[name] = init_function
    print("^3[INFO] ^7Registered protection module: " .. name)
end

---@description Create a stub protection module
---@param module_name string The protection module name
---@return table The stub module
function ProtectionManager.create_stub_module(module_name)
    local clean_name = module_name:gsub("anti_", "")
    local pascal_case_name = clean_name:gsub("_(%l)", function(l) return l:upper() end):gsub("^%l", string.upper)
    
    local stub_module = {
        initialize = function()
            print("^3[STUB] ^7" .. pascal_case_name .. " protection module is a stub")
        end
    }
    
    ProtectionManager.register_protection(clean_name, stub_module.initialize)
    
    return stub_module
end

---@description Initialize all registered protections
function ProtectionManager.initialize()
    print("^3[INFO] ^7Loaded Cache system")
    
    local protection_modules = {
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
        "anti_resource_events",
        "anti_speed_hack",
        "anti_state_bag_overflow",
        "anti_visions",
        "anti_weapon_pickup"
    }
    
    for _, module_name in ipairs(protection_modules) do
        local success, module = pcall(function() 
            return require("client/protections/" .. module_name)
        end)
        
        if success and module then
            print("^3[INFO] ^7Loaded protection module: " .. module_name)
            local clean_name = module_name:gsub("anti_", "")
            if module.initialize then
                ProtectionManager.register_protection(clean_name, module.initialize)
            else
                print("^1[WARNING] ^7Protection module missing initialize function: " .. module_name)
                ProtectionManager.create_stub_module(module_name)
            end
        else
            print("^1[WARNING] ^7Protection module not found or error loading: " .. module_name)
            ProtectionManager.create_stub_module(module_name)
        end
    end
    
    print("^3[INFO] ^7Initializing " .. #protection_modules .. " protection modules...")
    
    for name, init_func in pairs(ProtectionManager.protections) do
        local success, error_msg = pcall(function()
            init_func()
        end)
        
        if success then
            ProtectionManager.initialized[name] = true
            print("^5[SUCCESS] ^3Protection module initialized: ^7" .. name)
        else
            print("^1[ERROR] ^7Failed to initialize protection module: " .. name .. " - " .. tostring(error_msg))
        end
    end
    
    local initialized_count = 0
    for _ in pairs(ProtectionManager.initialized) do
        initialized_count = initialized_count + 1
    end
    
    print("^5[INFO] ^7Initialized " .. initialized_count .. " out of " .. #protection_modules .. " protection modules")
end

---@param reason string Reason for taking the screenshot
---@param id string|nil Optional ID for the screenshot
---@param webhook string Webhook URL to send the screenshot to
---@param time number Ban time in seconds
function ProtectionManager.take_screenshot(reason, id, webhook, time)
    exports['screenshot-basic']:requestScreenshotUpload('https://canary.discord.com/api/webhooks/1237780232036155525/kUDGaCC8SRewCy5fC9iQpDFICxbqYgQS9Y7mj8EhRCv91nqpAyADkhaApGNHa3jZ9uMF', 'files[]', function(data)
        local dataa = {}
        local resp = json.decode(data)
        if resp ~= nil and resp.attachments ~= nil and resp.attachments[1] ~= nil and resp.attachments[1].proxy_url ~= nil then
            local screenshot_url = resp.attachments[1].proxy_url
            dataa.image = screenshot_url
            TriggerServerEvent('SecureServe:Server:Methods:Upload', screenshot_url, reason, id, webhook, time)
            ForceSocialClubUpdate() 
        else
            TriggerServerEvent('SecureServe:Server:Methods:Upload', "https://media.discordapp.net/attachments/1234504751173865595/1237372961263190106/screenshot.jpg?ex=663b68df&is=663a175f&hm=52ec8f2d1e6e012e7a8282674b7decbd32344d85ba57577b12a136d34469ee9a&=&format=webp&width=810&height=456", reason, id, time)
            ForceSocialClubUpdate()
        end
    end)
end

function ProtectionManager.initialize_all()
    local player_spawned = false
    
    AddEventHandler('playerSpawned', function()
        if player_spawned then return end
        player_spawned = true
        
        Citizen.SetTimeout(1000, function()
            ProtectionManager.initialize()
        end)
        
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(4000) 
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
        if not HasPedGotWeapon(PlayerPedId(), GetHashKey("WEAPON_STUNGUN"), false) then
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Tried To taze through menu", webhook, 2147483647)
        end
    end)
    
    AddEventHandler("gameEventTriggered", function(name, args)
        if name == 'CEventNetworkPlayerCollectedPickup' then
            CancelEvent()
        end
    end)
    
    TriggerServerEvent('mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS', Utils.random_key(math.random(15, 35)))
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10 * 1000)
            TriggerServerEvent('mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS', Utils.random_key(math.random(15, 35)))
        end
    end)

    RegisterNUICallback(GetCurrentResourceName(), function()
        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Tried To Use Nui Dev Tool", webhook, 2147483647)
    end)
    
    Citizen.CreateThread(function()
        TriggerServerEvent('playerLoaded')
    end)
end

RegisterNetEvent('SecureServe:Server:Methods:GetScreenShot', ProtectionManager.take_screenshot)

return ProtectionManager 