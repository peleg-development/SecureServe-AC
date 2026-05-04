local Utils  = require("shared/lib/utils")
local logger = require("client/core/client_logger")

local ProtectionManager = {
    protections      = {},
    initialized      = {},
    memory_thread    = nil,
    last_gc_time     = 0,
    gc_interval      = 60000,
    is_initialized   = false,
    player_spawned   = false,
    heartbeat_thread = nil,
    proofs_thread    = nil,
    fallback_image   = "https://i.imgur.com/HNILNpA.png",
}

function ProtectionManager.register_protection(name, init_function)
    ProtectionManager.protections[name] = init_function
    logger.info("Registered protection module: " .. name)
end

function ProtectionManager.create_stub_module(module_name)
    local clean = module_name:gsub("anti_", "")
    ProtectionManager.register_protection(clean, function()
        logger.debug(clean .. " stub")
    end)
end

function ProtectionManager.start_memory_manager()
    if ProtectionManager.memory_thread then
        TerminateThread(ProtectionManager.memory_thread)
    end
    ProtectionManager.last_gc_time = GetGameTimer()

    ProtectionManager.memory_thread = Citizen.CreateThread(function()
        while true do
            Citizen.Wait(15000)
            local now = GetGameTimer()
            if (now - ProtectionManager.last_gc_time) >= ProtectionManager.gc_interval then
                collectgarbage("step", 200)
                ProtectionManager.last_gc_time = now
            end
        end
    end)
end

function ProtectionManager.initialize()
    if ProtectionManager.is_initialized then
        return
    end
    ProtectionManager.is_initialized = true

    logger.info("Initializing Protection Manager")
    ProtectionManager.start_memory_manager()
    ProtectionManager.initialize_heartbeat()

    local protection_modules = {
        "anti_load_resource_file", "anti_ocr", "anti_invisible", "anti_no_reload",
        "anti_explosion_bullet", "anti_entity_security", "anti_magic_bullet",
        "anti_aim_assist", "anti_noclip", "anti_resource_stop", "anti_god_mode",
        "anti_spectate", "anti_freecam", "anti_teleport", "anti_weapon_damage_modifier",
        "anti_afk_injection", "anti_ai", "anti_bigger_hitbox", "anti_no_recoil",
        "anti_player_blips", "anti_give_weapon", "anti_speed_hack",
        "anti_state_bag_overflow", "anti_visions", "anti_weapon_pickup",
        "anti_super_jump", "anti_no_ragdoll", "anti_infinite_stamina",
    }

    for _, module_name in ipairs(protection_modules) do
        local ok, mod = pcall(require, "client/protections/" .. module_name)
        if ok and type(mod) == "table" and type(mod.initialize) == "function" then
            ProtectionManager.register_protection(module_name:gsub("anti_", ""), mod.initialize)
        else
            logger.warn("Protection module " .. module_name .. " missing or invalid")
            ProtectionManager.create_stub_module(module_name)
        end
        Citizen.Wait(15)
    end

    for name, init_func in pairs(ProtectionManager.protections) do
        ProtectionManager.initialize_protection(name, init_func)
        Citizen.Wait(35)
    end

    local count = 0
    for _ in pairs(ProtectionManager.initialized) do count = count + 1 end
    logger.info(("Initialized %d/%d protection modules"):format(count, #protection_modules))
end

function ProtectionManager.initialize_protection(name, init_func)
    if ProtectionManager.initialized[name] then return end

    local ok, err = pcall(init_func)
    if ok then
        ProtectionManager.initialized[name] = true
        logger.info("Protection initialized: " .. name)
    else
        logger.error(("Failed to initialize %s: %s"):format(name, tostring(err)))
    end
end

function ProtectionManager.take_screenshot(reason, id, webhook, time)
    logger.info("Taking screenshot for: " .. tostring(reason))

    if not exports['screenshot-basic'] or type(exports['screenshot-basic'].requestScreenshotUpload) ~= "function"
        or not webhook or webhook == "" then
        logger.warn("Screenshot export/webhook not available")
        TriggerServerEvent('SecureServe:Server:Methods:Upload',
            ProtectionManager.fallback_image, reason, id, webhook or "", time)
        return
    end

    local ok, err = pcall(function()
        exports['screenshot-basic']:requestScreenshotUpload(webhook, 'files[]', {
            encoding = 'jpg',
            quality = 0.85,
        }, function(data)
            local resp = data and data ~= "" and json.decode(data) or nil
            local url
            if resp and resp.attachments and resp.attachments[1] and resp.attachments[1].proxy_url then
                url = resp.attachments[1].proxy_url
            end
            if url then
                logger.info("Screenshot uploaded successfully")
                TriggerServerEvent('SecureServe:Server:Methods:Upload', url, reason, id, webhook, time)
            else
                logger.error("Failed to parse screenshot response")
                TriggerServerEvent('SecureServe:Server:Methods:Upload',
                    ProtectionManager.fallback_image, reason, id, webhook, time)
            end
        end)
    end)
    if not ok then
        logger.error("requestScreenshotUpload threw: " .. tostring(err))
        TriggerServerEvent('SecureServe:Server:Methods:Upload',
            ProtectionManager.fallback_image, reason, id, webhook, time)
    end
end

function ProtectionManager.initialize_heartbeat()
    AddEventHandler('playerSpawned', function()
        if ProtectionManager.player_spawned then return end
        ProtectionManager.player_spawned = true

        ProtectionManager.proofs_thread = Citizen.CreateThread(function()
            while true do
                Citizen.Wait(5000)
                local ped = PlayerPedId()
                if DoesEntityExist(ped) then
                    SetEntityProofs(ped, false, false, true, false, false, false, false, false)
                end
            end
        end)

        TriggerServerEvent("playerSpawneda")
        TriggerEvent('allowed')
    end)

    RegisterNetEvent('SecureServe:checkTaze', function()
        if not HasPedGotWeapon(PlayerPedId(), GetHashKey("WEAPON_STUNGUN"), false) then
            logger.warn("Detected taze through menu attempt")
            local webhook = ConfigLoader.get_protection_setting("Anti Taze", "webhook") or ""
            local time = ConfigLoader.get_protection_setting("Anti Taze", "time") or 2147483647
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil,
                "Tried To taze through menu", webhook, time)
        end
    end)

    AddEventHandler("gameEventTriggered", function(name)
        if name == 'CEventNetworkPlayerCollectedPickup' then
            CancelEvent()
        end
    end)

    ProtectionManager.heartbeat_thread = Citizen.CreateThread(function()
        TriggerServerEvent('mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS',
            Utils.random_key(math.random(15, 35)))
        while true do
            Citizen.Wait(2000)
            TriggerServerEvent('mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS',
                Utils.random_key(math.random(15, 35)))
        end
    end)

    RegisterNUICallback(GetCurrentResourceName(), function(_, cb)
        logger.warn("NUI Dev Tool usage detected")
        local webhook = ConfigLoader.get_protection_setting("Anti Extended NUI Devtools", "webhook") or ""
        local time = ConfigLoader.get_protection_setting("Anti Extended NUI Devtools", "time") or 2147483647
        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil,
            "Tried To Use Nui Dev Tool", webhook, time)
        cb('ok')
    end)

    Citizen.CreateThread(function()
        TriggerServerEvent('playerLoaded')
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if ProtectionManager.memory_thread    then TerminateThread(ProtectionManager.memory_thread) end
    if ProtectionManager.heartbeat_thread then TerminateThread(ProtectionManager.heartbeat_thread) end
    if ProtectionManager.proofs_thread    then TerminateThread(ProtectionManager.proofs_thread) end

    ProtectionManager.protections = {}
    ProtectionManager.initialized = {}
    collectgarbage("step", 100)
end)

RegisterNetEvent('SecureServe:Server:Methods:GetScreenShot', ProtectionManager.take_screenshot)

return ProtectionManager
