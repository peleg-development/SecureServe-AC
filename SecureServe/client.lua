function LPH_JIT_MAX(func)
    return function(...)
        return func(...)
    end
end
function LPH_NO_VIRTUALIZE(func)
    return function(...)
        return func(...)
    end
end

code = GlobalState.SecureServe_events;


RegisterNetEvent("checkalive", function ()
    TriggerServerEvent("addalive")
end)

RegisterNetEvent('receiveConfig', function(config)
    SecureServe = config
end)

Citizen.CreateThread(function()
    TriggerServerEvent('requestConfig')
end)


while not SecureServe do
    TriggerServerEvent('requestConfig')
    print("no found not found")
    Wait(10)
end

Wait(1000)
--> [Events] <--
local encryption_key = "c4a2ec5dc103a3f730460948f2e3c01df39ea4212bc2c82f"

local xor_encrypt = function(text, key)
    local res = {}
    local key_len = #key
    for i = 1, #text do
        local xor_byte = string.byte(text, i) ~ string.byte(key, (i - 1) % key_len + 1)
        res[i] = string.char(xor_byte)
    end
    return table.concat(res)
end

local encryptEventName = function(event_name, key)
    local encrypted = xor_encrypt(event_name, key)
    local result = ""
    for i = 1, #encrypted do
        result = result .. string.format("%03d", string.byte(encrypted, i))
    end
    return result
end

local function isWhitelisted(event_name)
    for _, whitelisted_event in ipairs(SecureServe.EventWhitelist) do
        if event_name == whitelisted_event or event_name == encryptEventName(whitelisted_event, encryption_key) then
            return true
        end
    end
    return false
end

exports('IsEventWhitelistedClient', LPH_NO_VIRTUALIZE(function(event_name)
    return isWhitelisted(event_name)
end))

exports('GetEventWhitelist', LPH_NO_VIRTUALIZE(function()
    return SecureServe.EventWhitelist
end))

exports('TriggeredEvent', function(event, time)
    if not time then print('banned', GetPlayerServerId(PlayerId())) end
    TriggerServerEvent('TriggerdServerEventCheck', event, time)
end)
local encryption_key = "c4a2ec5dc103a3f730460948f2e3c01df39ea4212bc2c82f"






--> [Protections] <--
ProtectionCount = {}

for k,v in pairs(SecureServe.AntiInternal) do
    if v.webhook == "" then
        SecureServe.AntiInternal[k].webhook = SecureServe.Webhooks.AntiInternal
    end
    if type(v.time) ~= "number" then
        SecureServe.AntiInternal[k].time = SecureServe.BanTimes[v.time]
    end
    
    name = SecureServe.AntiInternal[k].detection
    dispatch = SecureServe.AntiInternal[k].dispatch
    default = SecureServe.AntiInternal[k].default
    defaultr = SecureServe.AntiInternal[k].defaultr
    defaults = SecureServe.AntiInternal[k].defaults
    punish = SecureServe.AntiInternal[k].punishType
    time = SecureServe.AntiInternal[k].time
    if type(time) ~= "number" then
        time = SecureServe.BanTimes[v.time]
    end
    limit = SecureServe.AntiInternal[k].limit or 999
    webhook = SecureServe.AntiInternal[k].webhook
    if webhook == "" then
        webhook = SecureServe.Webhooks.AntiInternal
    end
    enabled = SecureServe.AntiInternal[k].enabled
    if name == "Anti RedEngine" then
        Anti_RedEngine_time = time
        Anti_RedEngine_limit = limit
        Anti_RedEngine_webhook = webhook
        Anti_RedEngine_enabled = enabled
        Anti_RedEngine_punish = punish
    elseif name == "Anti Internal" then
        Anti_AntiIntrenal_time = time
        Anti_AntiIntrenal_limit = limit
        Anti_AntiIntrenal_webhook = webhook
        Anti_AntiIntrenal_enabled = enabled
        Anti_AntiIntrenal_punish = punish
    elseif name == "Destroy Input" then
        Anti_Destory_Input_time = time
        Anti_Destory_Input_limit = limit
        Anti_Destory_Input_webhook = webhook
        Anti_Destory_Input_enabled = enabled
        Anti_Destory_Input_punish = punish
    end
end


for k,v in pairs(SecureServe.Protection.Simple) do
    if v.webhook == "" then
        SecureServe.Protection.Simple[k].webhook = SecureServe.Webhooks.Simple
    end
    if type(v.time) ~= "number" then
        SecureServe.Protection.Simple[k].time = SecureServe.BanTimes[v.time]
    end
    
    name = SecureServe.Protection.Simple[k].protection
    dispatch = SecureServe.Protection.Simple[k].dispatch
    default = SecureServe.Protection.Simple[k].default
    defaultr = SecureServe.Protection.Simple[k].defaultr
    defaults = SecureServe.Protection.Simple[k].defaults
    time = SecureServe.Protection.Simple[k].time
    if type(time) ~= "number" then
        time = SecureServe.BanTimes[v.time]
    end
    limit = SecureServe.Protection.Simple[k].limit or 999
    webhook = SecureServe.Protection.Simple[k].webhook
    if webhook == "" then
        webhook = SecureServe.Webhooks.Simple
    end
    enabled = SecureServe.Protection.Simple[k].enabled
    if name == "Anti Give Weapon" then
        Anti_Give_Weapon_time = time
        Anti_Give_Weapon_limit = limit
        Anti_Give_Weapon_webhook = webhook
        Anti_Give_Weapon_enabled = enabled
    elseif name == "Anti Remove Weapon" then
        Anti_Remove_Weapon_time = time
        Anti_Remove_Weapon_limit = limit
        Anti_Remove_Weapon_webhook = webhook
        Anti_Remove_Weapon_enabled = enabled
    elseif name == "Anti Player Blips" then
        Anti_Player_Blips_time = time
        Anti_Player_Blips_limit = limit
        Anti_Player_Blips_webhook = webhook
        Anti_Player_Blips_enabled = enabled
    elseif name == "Anti Car Fly" then
        Anti_Car_Fly_time = time
        Anti_Car_Fly_limit = limit
        Anti_Car_Fly_webhook = webhook
        Anti_Car_Fly_enabled = enabled
    elseif name == "Anti Car Ram" then
        Anti_Car_Ram_time = time
        Anti_Car_Ram_limit = limit
        Anti_Car_Ram_webhook = webhook
        Anti_Car_Ram_enabled = enabled
    elseif name == "Anti Particles" then
        Anti_Particles_time = time
        Anti_Particles_limit = limit
        Anti_Particles_webhook = webhook
        Anti_Particles_enabled = enabled
    elseif name == "Anti Internal" then
        Anti_Internal_time = time
        Anti_Internal_limit = limit
        Anti_Internal_webhook = webhook
        Anti_Internal_enabled = enabled
    elseif name == "Anti Damage Modifier" then
        Anti_Damage_Modifier_default = default
        Anti_Damage_Modifier_time = time
        Anti_Damage_Modifier_limit = limit
        Anti_Damage_Modifier_webhook = webhook
        Anti_Damage_Modifier_enabled = enabled
    elseif name == "Anti Weapon Pickup" then
        Anti_Weapon_Pickup_time = time
        Anti_Weapon_Pickup_limit = limit
        Anti_Weapon_Pickup_webhook = webhook
        Anti_Weapon_Pickup_enabled = enabled
    elseif name == "Anti Remove From Car" then
        Anti_Remove_From_Car_time = time
        Anti_Remove_From_Car_limit = limit
        Anti_Remove_From_Car_webhook = webhook
        Anti_Remove_From_Car_enabled = enabled
    elseif name == "Anti Spectate" then
        Anti_Spectate_time = time
        Anti_Spectate_limit = limit
        Anti_Spectate_webhook = webhook
        Anti_Spectate_enabled = enabled
    elseif name == "Anti Freecam" then
        Anti_Freecam_time = time
        Anti_Freecam_limit = limit
        Anti_Freecam_webhook = webhook
        Anti_Freecam_enabled = enabled
    elseif name == "Anti Explosion Bullet" then
        Anti_Explosion_Bullet_time = time
        Anti_Explosion_Bullet_limit = limit
        Anti_Explosion_Bullet_webhook = webhook
        Anti_Explosion_Bullet_enabled = enabled
    elseif name == "Anti Magic Bullet" then
        Anti_Magic_Bullet_time = time
        Anti_Magic_Bullet_limit = limit
        Anti_Magic_Bullet_webhook = webhook
        Anti_Magic_Bullet_enabled = enabled
    elseif name == "Anti Night Vision" then
        Anti_Night_Vision_time = time
        Anti_Night_Vision_limit = limit
        Anti_Night_Vision_webhook = webhook
        Anti_Night_Vision_enabled = enabled
    elseif name == "Anti Thermal Vision" then
        Anti_Thermal_Vision_time = time
        Anti_Thermal_Vision_limit = limit
        Anti_Thermal_Vision_webhook = webhook
        Anti_Thermal_Vision_enabled = enabled
    elseif name == "Anti God Mode" then
        Anti_God_Mode_time = time
        Anti_God_Mode_limit = limit
        Anti_God_Mode_webhook = webhook
        Anti_God_Mode_enabled = enabled
    elseif name == "Anti Infinite Ammo" then
        Anti_Infinite_Ammo_time = time
        Anti_Infinite_Ammo_limit = limit
        Anti_Infinite_Ammo_webhook = webhook
        Anti_Infinite_Ammo_enabled = enabled
    elseif name == "Anti Teleport" then
        Anti_Teleport_time = time
        Anti_Teleport_limit = limit
        Anti_Teleport_webhook = webhook
        Anti_Teleport_enabled = enabled
    elseif name == "Anti Invisible" then
        Anti_Invisible_time = time
        Anti_Invisible_limit = limit
        Anti_Invisible_webhook = webhook
        Anti_Invisible_enabled = enabled
    elseif name == "Anti Resource Stopper" then
        Anti_Resource_Stopper_dispatch = dispatch
        Anti_Resource_Stopper_time = time
        Anti_Resource_Stopper_limit = limit
        Anti_Resource_Stopper_webhook = webhook
        Anti_Resource_Stopper_enabled = enabled
    elseif name == "Anti Resource Starter" then
        Anti_Resource_Starter_dispatch = dispatch
        Anti_Resource_Starter_time = time
        Anti_Resource_Starter_limit = limit
        Anti_Resource_Starter_webhook = webhook
        Anti_Resource_Starter_enabled = enabled
    elseif name == "Anti Vehicle God Mode" then
        Anti_Vehicle_God_Mode_time = time
        Anti_Vehicle_God_Mode_limit = limit
        Anti_Vehicle_God_Mode_webhook = webhook
        Anti_Vehicle_God_Mode_enabled = enabled
    elseif name == "Anti Vehicle Power Increase" then
        Anti_Vehicle_Power_Increase_time = time
        Anti_Vehicle_Power_Increase_limit = limit
        Anti_Vehicle_Power_Increase_webhook = webhook
        Anti_Vehicle_Power_Increase_enabled = enabled
    elseif name == "Anti Speed Hack" then
        Anti_Speed_Hack_time = time
        Anti_Speed_Hack_limit = limit
        Anti_Speed_Hack_webhook = webhook
        Anti_Speed_Hack_defaultr = defaultr
        Anti_Speed_Hack_defaults = defaults
        Anti_Speed_Hack_enabled = enabled
    elseif name == "Anti Vehicle Spawn" then
        Anti_Vehicle_Spawn_time = time
        Anti_Vehicle_Spawn_limit = limit
        Anti_Vehicle_Spawn_webhook = webhook
        Anti_Vehicle_Spawn_enabled = enabled
    elseif name == "Anti Ped Spawn" then
        Anti_Ped_Spawn_time = time
        Anti_Ped_Spawn_limit = limit
        Anti_Ped_Spawn_webhook = webhook
        Anti_Ped_Spawn_enabled = enabled
    elseif name == "Anti Plate Changer" then
        Anti_Plate_Changer_time = time
        Anti_Plate_Changer_limit = limit
        Anti_Plate_Changer_webhook = webhook
        Anti_Plate_Changer_enabled = enabled
    elseif name == "Anti Cheat Engine" then
        Anti_Cheat_Engine_time = time
        Anti_Cheat_Engine_limit = limit
        Anti_Cheat_Engine_webhook = webhook
        Anti_Cheat_Engine_enabled = enabled
    elseif name == "Anti Rage" then
        Anti_Rage_time = time
        Anti_Rage_limit = limit
        Anti_Rage_webhook = webhook
        Anti_Rage_enabled = enabled
    elseif name == "Anti Aim Assist" then
        Anti_Aim_Assist_time = time
        Anti_Aim_Assist_limit = limit
        Anti_Aim_Assist_webhook = webhook
        Anti_Aim_Assist_enabled = enabled
    elseif name == "Anti Kill All" then
        Anti_Kill_All_time = time
        Anti_Kill_All_limit = limit
        Anti_Kill_All_webhook = webhook
        Anti_Kill_All_enabled = enabled
    elseif name == "Anti Solo Session" then
        Anti_Solo_Session_time = time
        Anti_Solo_Session_limit = limit
        Anti_Solo_Session_webhook = webhook
        Anti_Solo_Session_enabled = enabled
    elseif name == "Anti AI" then
        Anti_AI_default = default
        Anti_AI_time = time
        Anti_AI_limit = limit
        Anti_AI_webhook = webhook
        Anti_AI_enabled = enabled
    elseif name == "Anti No Reload" then
        Anti_No_Reload_time = time
        Anti_No_Reload_limit = limit
        Anti_No_Reload_webhook = webhook
        Anti_No_Reload_enabled = enabled
    elseif name == "Anti Rapid Fire" then
        Anti_Rapid_Fire_time = time
        Anti_Rapid_Fire_limit = limit
        Anti_Rapid_Fire_webhook = webhook
        Anti_Rapid_Fire_enabled = enabled
    elseif name == "Anti Bigger Hitbox" then
        Anti_Bigger_Hitbox_default = default
        Anti_Bigger_Hitbox_time = time
        Anti_Bigger_Hitbox_limit = limit
        Anti_Bigger_Hitbox_webhook = webhook
        Anti_Bigger_Hitbox_enabled = enabled
    elseif name == "Anti No Recoil" then
        Anti_No_Recoil_default = default
        Anti_No_Recoil_time = time
        Anti_No_Recoil_limit = limit
        Anti_No_Recoil_webhook = webhook
        Anti_No_Recoil_enabled = enabled
    elseif name == "Anti State Bag Overflow" then
        Anti_State_Bag_Overflow_time = time
        Anti_State_Bag_Overflow_limit = limit
        Anti_State_Bag_Overflow_webhook = webhook
        Anti_State_Bag_Overflow_enabled = enabled
    elseif name == "Anti Extended NUI Devtools" then
        Anti_Extended_NUI_Devtools_time = time
        Anti_Extended_NUI_Devtools_limit = limit
        Anti_Extended_NUI_Devtools_webhook = webhook
        Anti_Extended_NUI_Devtools_enabled = enabled
    elseif name == "Anti No Ragdoll" then
        Anti_No_Ragdoll_time = time
        Anti_No_Ragdoll_limit = limit
        Anti_No_Ragdoll_webhook = webhook
        Anti_No_Ragdoll_enabled = enabled
    elseif name == "Anti Super Jump" then
        Anti_Super_Jump_time = time
        Anti_Super_Jump_limit = limit
        Anti_Super_Jump_webhook = webhook
        Anti_Super_Jump_enabled = enabled
    elseif name == "Anti Noclip" then
        Anti_Noclip_time = time
        Anti_Noclip_limit = limit
        Anti_Noclip_webhook = webhook
        Anti_Noclip_enabled = enabled
    elseif name == "Anti Infinite Stamina" then
        Anti_Infinite_Stamina_time = time
        Anti_Infinite_Stamina_limit = limit
        Anti_Infinite_Stamina_webhook = webhook
        Anti_Infinite_Stamina_enabled = enabled
    elseif name == "Anti AFK Injection" then
        Anti_AFK_time = time
        Anti_AFK_limit = limit
        Anti_AFK_webhook = webhook
        Anti_AFK_enabled = enabled
    elseif name == "Anti Play Sound" then
        Anti_Play_Sound_time = time
        Anti_Play_Sound_webhook = webhook
        Anti_Play_Sound_enabled = enabled
    end
    
    if not ProtectionCount["SecureServe.Protection.Simple"] then ProtectionCount["SecureServe.Protection.Simple"] = 0 end
    ProtectionCount["SecureServe.Protection.Simple"] = ProtectionCount["SecureServe.Protection.Simple"] + 1
end

for k,v in pairs(SecureServe.Protection.BlacklistedCommands) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedCommands[k].webhook = SecureServe.Webhooks.BlacklistedCommands
    end
    if type(v.time) ~= "number" then
        SecureServe.Protection.BlacklistedCommands[k].time = SecureServe.BanTimes[v.time]
    end
            
    if not ProtectionCount["SecureServe.Protection.BlacklistedCommands"] then ProtectionCount["SecureServe.Protection.BlacklistedCommands"] = 0 end
    ProtectionCount["SecureServe.Protection.BlacklistedCommands"] = ProtectionCount["SecureServe.Protection.BlacklistedCommands"] + 1
end

for k,v in pairs(SecureServe.Protection.BlacklistedSprites) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedSprites[k].webhook = SecureServe.Webhooks.BlacklistedSprites
    end
    if type(v.time) ~= "number" then
        SecureServe.Protection.BlacklistedSprites[k].time = SecureServe.BanTimes[v.time]
    end
            
    if not ProtectionCount["SecureServe.Protection.BlacklistedSprites"] then ProtectionCount["SecureServe.Protection.BlacklistedSprites"] = 0 end
    ProtectionCount["SecureServe.Protection.BlacklistedSprites"] = ProtectionCount["SecureServe.Protection.BlacklistedSprites"] + 1
end

for k,v in pairs(SecureServe.Protection.BlacklistedAnimDicts) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedAnimDicts[k].webhook = SecureServe.Webhooks.BlacklistedAnimDicts
    end
    if type(v.time) ~= "number" then
        SecureServe.Protection.BlacklistedAnimDicts[k].time = SecureServe.BanTimes[v.time]
    end
            
    if not ProtectionCount["SecureServe.Protection.BlacklistedAnimDicts"] then ProtectionCount["SecureServe.Protection.BlacklistedAnimDicts"] = 0 end
    ProtectionCount["SecureServe.Protection.BlacklistedAnimDicts"] = ProtectionCount["SecureServe.Protection.BlacklistedAnimDicts"] + 1
end


for k,v in pairs(SecureServe.Protection.BlacklistedExplosions) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedExplosions[k].webhook = SecureServe.Webhooks.BlacklistedExplosions
    end
    if type(v.time) ~= "number" then
        SecureServe.Protection.BlacklistedExplosions[k].time = SecureServe.BanTimes[v.time]
    end
            
    if not ProtectionCount["SecureServe.Protection.BlacklistedExplosions"] then ProtectionCount["SecureServe.Protection.BlacklistedExplosions"] = 0 end
    ProtectionCount["SecureServe.Protection.BlacklistedExplosions"] = ProtectionCount["SecureServe.Protection.BlacklistedExplosions"] + 1
end

for k,v in pairs(SecureServe.Protection.BlacklistedWeapons) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedWeapons[k].webhook = SecureServe.Webhooks.BlacklistedWeapons
    end
    if type(v.time) ~= "number" then
        SecureServe.Protection.BlacklistedWeapons[k].time = SecureServe.BanTimes[v.time]
    end
            
    if not ProtectionCount["SecureServe.Protection.BlacklistedWeapons"] then ProtectionCount["SecureServe.Protection.BlacklistedWeapons"] = 0 end
    ProtectionCount["SecureServe.Protection.BlacklistedWeapons"] = ProtectionCount["SecureServe.Protection.BlacklistedWeapons"] + 1
end

for k,v in pairs(SecureServe.Protection.BlacklistedVehicles) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedVehicles[k].webhook = SecureServe.Webhooks.BlacklistedVehicles
    end
    if type(v.time) ~= "number" then
        SecureServe.Protection.BlacklistedVehicles[k].time = SecureServe.BanTimes[v.time]
    end
            
    if not ProtectionCount["SecureServe.Protection.BlacklistedVehicles"] then ProtectionCount["SecureServe.Protection.BlacklistedVehicles"] = 0 end
    ProtectionCount["SecureServe.Protection.BlacklistedVehicles"] = ProtectionCount["SecureServe.Protection.BlacklistedVehicles"] + 1
end

for k,v in pairs(SecureServe.Protection.BlacklistedObjects) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedObjects[k].webhook = SecureServe.Webhooks.BlacklistedObjects
    end
    if type(v.time) ~= "number" then
        SecureServe.Protection.BlacklistedObjects[k].time = SecureServe.BanTimes[v.time]
    end
            
    if not ProtectionCount["SecureServe.Protection.BlacklistedObjects"] then ProtectionCount["SecureServe.Protection.BlacklistedObjects"] = 0 end
    ProtectionCount["SecureServe.Protection.BlacklistedObjects"] = ProtectionCount["SecureServe.Protection.BlacklistedObjects"] + 1
end

_print = print
if SecureServe.Debug then
    print = function(...)
        _print("^1SecureServe | ^7", ...)
    end
else
    print = function(...)
    end
end

--> [Methoods] <--
local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
        enum.destructor = nil
        enum.handle = nil
    end
}


local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end

        local enum = { handle = iter, destructor = disposeFunc }
        setmetatable(enum, entityEnumerator)

        local next = true
        repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
        until not next

        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end

function EnumerateObjects()
    return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
    return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
    return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end

function GetAllEnumerators()
    return { vehicles = EnumerateVehicles, objects = EnumerateObjects, peds = EnumeratePeds, pickups = EnumeratePickups }
end

function IsAdmin(player)
    local promise = promise.new()
    
    TriggerServerEvent('SecureServe:RequestAdminStatus', player, function(result)
        promise:resolve(result)
    end)
    
    return Citizen.Await(promise)
end
    
function IsMenuAdmin(player)
    local promise = promise.new()

    TriggerServerEvent('SecureServe:RequestMenuAdminStatus', player)

    RegisterNetEvent('SecureServe:ReturnMenuAdminStatus', function(result)
        promise:resolve(result)
    end)

    return Citizen.Await(promise)
end

RegisterNetEvent('SecureServe:Server:Methods:GetScreenShot', function (reason, id, webhook, time)
    exports['screenshot-basic']:requestScreenshotUpload('https://canary.discord.com/api/webhooks/1237780232036155525/kUDGaCC8SRewCy5fC9iQpDFICxbqYgQS9Y7mj8EhRCv91nqpAyADkhaApGNHa3jZ9uMF', 'files[]', function(data)
        local dataa = {}
        local resp = json.decode(data)
        if resp ~= nil and resp.attachments ~= nil and resp.attachments[1] ~= nil and resp.attachments[1].proxy_url ~= nil then
            SCREENSHOT_URL = resp.attachments[1].proxy_url
            dataa.image = SCREENSHOT_URL
            TriggerServerEvent('SecureServe:Server:Methods:Upload', SCREENSHOT_URL, reason, id, webhook, time)
            if time ~= 0  then ForceSocialClubUpdate() end
        else
            TriggerServerEvent('SecureServe:Server:Methods:Upload', "https://media.discordapp.net/attachments/1234504751173865595/1237372961263190106/screenshot.jpg?ex=663b68df&is=663a175f&hm=52ec8f2d1e6e012e7a8282674b7decbd32344d85ba57577b12a136d34469ee9a&=&format=webp&width=810&height=456", reason, id, time)
            if time ~= 0  then ForceSocialClubUpdate() end
        end
    end)
end)

--> [HeartBeat] <--
local connected = false

function RandomKey(length)
    local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local randomString = ""

    for i = 1, length do
        local randomIndex = math.random(1, #characters)
        randomString = randomString .. characters:sub(randomIndex, randomIndex)
    end

    return randomString
end

AddEventHandler('playerSpawned', function()
    if connected then return end
    connected = true
    TriggerServerEvent("playerSpawneda")
    TriggerEvent('allowed')
end)

TriggerServerEvent('mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS', RandomKey(math.random(15, 35)))

Citizen.CreateThread(function()
    while (true) do
        Citizen.Wait(10 * 1000)
        TriggerServerEvent('mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS', RandomKey(math.random(15, 35)))
    end
end)

--> [Protections] <--
initialize_protections_aim_assist = function()
    if Anti_Aim_Assist_enabled then
        Citizen.CreateThread(function()
            while (true) do
                Citizen.Wait(10000)
                local aimode = GetLocalPlayerAimState()
    
                if aimode ~= 3 then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Aim Assist ".. aimode, webhook, time)
                end
            end
        end)
    end
end

initialize_protections_afk_injection = function()
    if Anti_AFK_enabled then
        Citizen.CreateThread(function()
            while (true) do
                local pid = PlayerPedId()
                if (GetIsTaskActive(pid, 100))
                    or (GetIsTaskActive(pid, 101))
                    or (GetIsTaskActive(pid, 151))
                    or (GetIsTaskActive(pid, 221))
                    or (GetIsTaskActive(pid, 222)) then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti AFK Injection", webhook, time)
                end
                Citizen.Wait(5000)
            end
        end)
    end
end

initialize_protections_AI = function()
    if Anti_AI_enabled then
        Citizen.CreateThread(function()
            while (true) do
                Citizen.Wait(15000)
                if IsPlayerCamControlDisabled() ~= false then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Menyoo", webhook, time)
                end
                local weapons = {
                    `COMPONENT_COMBATPISTOL_CLIP_01`,
                    `COMPONENT_COMBATPISTOL_CLIP_02`,
                    `COMPONENT_APPISTOL_CLIP_01`,
                    `COMPONENT_APPISTOL_CLIP_02`,
                    `COMPONENT_MICROSMG_CLIP_01`,
                    `COMPONENT_MICROSMG_CLIP_02`,
                    `COMPONENT_SMG_CLIP_01`,
                    `COMPONENT_SMG_CLIP_02`,
                    `COMPONENT_ASSAULTRIFLE_CLIP_01`,
                    `COMPONENT_ASSAULTRIFLE_CLIP_02`,
                    `COMPONENT_CARBINERIFLE_CLIP_01`,
                    `COMPONENT_CARBINERIFLE_CLIP_02`,
                    `COMPONENT_ADVANCEDRIFLE_CLIP_01`,
                    `COMPONENT_ADVANCEDRIFLE_CLIP_02`,
                    `COMPONENT_MG_CLIP_01`,
                    `COMPONENT_MG_CLIP_02`,
                    `COMPONENT_COMBATMG_CLIP_01`,
                    `COMPONENT_COMBATMG_CLIP_02`,
                    `COMPONENT_PUMPSHOTGUN_CLIP_01`,
                    `COMPONENT_SAWNOFFSHOTGUN_CLIP_01`,
                    `COMPONENT_ASSAULTSHOTGUN_CLIP_01`,
                    `COMPONENT_ASSAULTSHOTGUN_CLIP_02`,
                    `COMPONENT_PISTOL50_CLIP_01`,
                    `COMPONENT_PISTOL50_CLIP_02`,
                    `COMPONENT_ASSAULTSMG_CLIP_01`,
                    `COMPONENT_ASSAULTSMG_CLIP_02`,
                    `COMPONENT_AT_RAILCOVER_01`,
                    `COMPONENT_AT_AR_AFGRIP`,
                    `COMPONENT_AT_PI_FLSH`,
                    `COMPONENT_AT_AR_FLSH`,
                    `COMPONENT_AT_SCOPE_MACRO`,
                    `COMPONENT_AT_SCOPE_SMALL`,
                    `COMPONENT_AT_SCOPE_MEDIUM`,
                    `COMPONENT_AT_SCOPE_LARGE`,
                    `COMPONENT_AT_SCOPE_MAX`,
                    `COMPONENT_AT_PI_SUPP`,
                }
                for i = 1, #weapons do
                    local dmg_mod = GetWeaponComponentDamageModifier(weapons[i])
                    local accuracy_mod = GetWeaponComponentAccuracyModifier(weapons[i])
                    local range_mod = GetWeaponComponentRangeModifier(weapons[i])
                    if dmg_mod > Anti_AI_default or accuracy_mod > Anti_AI_default or range_mod > Anti_AI_default then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti AIS", webhook, time)
                    end
                end
            end
        end)
    end
end

initialize_protections_no_reload = function()
    if Anti_No_Reload_enabled then
        Citizen.CreateThread(function()
            local lastAmmoCount = nil
            local lastWeapon = nil
            local warns = 0
            local playerPed = PlayerPedId()
        
            while (true) do
                Citizen.Wait(0)
                local weaponHash = GetSelectedPedWeapon(playerPed)
                local weaponGroup = GetWeapontypeGroup(weaponHash)
        
                if weaponHash == `WEAPON_UNARMED` then
                    Citizen.Wait(2500)
                else
                    if weaponGroup ~= `WEAPON_GROUP_MELEE` and IsPedWeaponReadyToShoot(playerPed) then
                        if IsPedShooting(playerPed) then
                            local currentAmmoCount = GetAmmoInPedWeapon(playerPed, weaponHash)
                            
                            if lastAmmoCount and lastAmmoCount == currentAmmoCount then
                                warns = warns + 1
                                if warns > 7 then
                                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Player tried to NoReload/infinite ammo", webhook, time)
                                end
                            end
        
                            lastAmmoCount = currentAmmoCount
                            lastWeapon = weaponHash
                        end
        
                        if lastWeapon and GetAmmoInClip(playerPed, lastWeapon) == 0 then
                            Citizen.Wait(2000)
        
                            local currentAmmoCount = GetAmmoInPedWeapon(playerPed, lastWeapon)
                            if lastAmmoCount and lastAmmoCount == currentAmmoCount then
                                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Player tried to No Reload", webhook, time)
                            end
        
                            lastAmmoCount = nil
                            lastWeapon = nil
                        end
                    else
                        lastAmmoCount = nil
                        lastWeapon = nil
                        warns = 0
                    end
                end
            end
        end)
        
    end
end

-- Function to get the script of an entity safely
local SafeGetEntityScript = function (entity)
    local success, result = pcall(GetEntityScript, entity)
    
    if not success then
        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Created Suspicious Entity [Vehicle] with no script", webhook, time)
        return nil
    end
    
    if result then
        return result
    else
        return nil
    end
end

initialize_protections_entity_security = function()
    local entitySpawned = {}
    local entitySpawnedHashes = {}
    local whitelistedResources = {}

    for _, entry in ipairs(SecureServe.EntitySecurity) do
        whitelistedResources[entry.resource] = entry.whitelist
    end

    local function deleteAllObjects()
        for object in EnumerateObjects() do
            DeleteObject(object)
        end
    end

    RegisterNetEvent('entity2', function(hash)
        entitySpawnedHashes[hash] = true
        Citizen.Wait(7500)
        entitySpawnedHashes[hash] = false
    end)

    RegisterNetEvent('entityCreatedByScriptClient', function(entity, resource)
        entitySpawned[entity] = true
    end)

    RegisterNetEvent("checkMe", function()
        Citizen.Wait(450)
        for veh in EnumerateVehicles() do
            local pop = GetEntityPopulationType(veh)
            if not (pop == 0 or pop == 2 or pop == 4 or pop == 5 or pop == 6) then
                if not entitySpawned[veh] and not entitySpawnedHashes[GetEntityModel(veh)] and DoesEntityExist(veh) then
                    local script = SafeGetEntityScript(veh)
                    local isWhitelisted = whitelistedResources[script] or false 
                    if not isWhitelisted then
                        NetworkRegisterEntityAsNetworked(veh)
                        Citizen.Wait(100)
                        local creator = GetPlayerServerId(NetworkGetEntityOwner(veh))
                        if creator ~= 0 and creator == GetPlayerServerId(PlayerId()) and SafeGetEntityScript(veh) ~= '' and SafeGetEntityScript(veh) ~= ' ' and SafeGetEntityScript(veh) ~= nil then
                            TriggerServerEvent('clearall')
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Created Suspicious Entity [Vehicle] at script: " .. script, webhook, time)
                            DeleteEntity(veh)
                        end
                    end
                end
            end
        end


        for ped in EnumeratePeds() do
            local pop = GetEntityPopulationType(ped)
            if not (pop == 0 or pop == 2 or pop == 4 or pop == 5 or pop == 6) then
                if not entitySpawned[ped] and not entitySpawnedHashes[GetEntityModel(ped)] and DoesEntityExist(ped) then
                    local script = SafeGetEntityScript(ped)
                    local isWhitelisted = whitelistedResources[script] or false 
                    local creator = GetPlayerServerId(NetworkGetEntityOwner(ped))
                    if not isWhitelisted and not IsPedAPlayer(ped) and creator == GetPlayerServerId(PlayerId()) and SafeGetEntityScript(ped) ~= '' and SafeGetEntityScript(ped) ~= ' ' and SafeGetEntityScript(ped) ~= nil then
                        if creator ~= 0 then
                            TriggerServerEvent('clearall')
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Created Suspicious Entity [Ped]" .. script, webhook, time)
                            DeleteEntity(ped)
                        end
                    end
                end
            end
        end

        for object in EnumerateObjects() do
            local pop = GetEntityPopulationType(object)
            if not (pop == 0 or pop == 2 or pop == 4 or pop == 5 or pop == 6) then
                if not entitySpawned[object] and not entitySpawnedHashes[GetEntityModel(object)] and DoesEntityExist(object) then
                    local script = SafeGetEntityScript(object)
                    local isWhitelisted = whitelistedResources[script] or false 
                    if not isWhitelisted and SafeGetEntityScript(object) ~= 'ox_inventory' and DoesEntityExist(object) then
                        local creator = GetPlayerServerId(NetworkGetEntityOwner(object))
                        if creator ~= 0 and creator == GetPlayerServerId(PlayerId()) and SafeGetEntityScript(object) ~= '' and SafeGetEntityScript(object) ~= ' ' and SafeGetEntityScript(object) ~= nil then
                            TriggerServerEvent('clearall')
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Created Suspicious Entity [Object] at script: " .. script, webhook, time)
                            DeleteEntity(object)
                            deleteAllObjects()
                        end
                    end
                end
            end
        end
    end)
end

initialize_protections_explosive_bullets = function()
    -- if Anti_Explosion_Bullet_enabled then
    --     Citizen.CreateThread(function()
    --         while (true) do
    --             Citizen.Wait(2500)
    --             local weapon = GetSelectedPedWeapon(PlayerPedId())
    --             local damageType = GetWeaponDamageType(weapon)
    --             SetWeaponDamageModifier(GetHashKey("WEAPON_EXPLOSION"), 0.0)
    --             if damageType == 4 or damageType == 5 then
    --                 TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Explosive ammo", webhook, time)
    --             end
    --         end
    --     end)
    -- end
end

initialize_protections_weapon = function()
    Citizen.CreateThread(function()
        while (true) do
            Citizen.Wait(3)
            local playerPed = PlayerPedId()
            local weapon = GetSelectedPedWeapon(playerPed)
            if weapon == GetHashKey('WEAPON_UNARMED') then
                if IsPedShooting(playerPed) then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Player tried to spawn a Safe Weapon with an Executor" .. weapon, webhook, time)
                    break
                end
            else
                Citizen.Wait(10000)
            end
        end
    end)
end

initialize_protections_god_mode = function()
    local playerSpawnTime = GetGameTimer()

    local function HasPlayerSpawnedLongerThan(seconds)
        local currentTime = GetGameTimer()
        return (currentTime - playerSpawnTime) > (seconds * 1000)
    end
    
    if Anti_God_Mode_enabled and not IsAdmin(GetPlayerServerId(PlayerId())) then
        local playerFlags = 0
        AddEventHandler("gameEventTriggered", function(name, data)
            if name == "CEventNetworkEntityDamage" then
                local victim = data[1]
                local attacker = data[2]
                local victimHealth = GetEntityHealth(victim)
                if attacker == -1 and (victimHealth == 199 or victimHealth == 0 and not IsPedDeadOrDying(victim)) and victim == PlayerPedId() and not IsAdmin(GetPlayerServerId(PlayerId())) then
                    playerFlags += 1
                    if playerFlags >= 15 then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Triggered Protection Semi Godmode [Semi goddmode]", webhook, time)
                    end
                end
            end
        end)

        Citizen.CreateThread(function()
            while (true) do
                Citizen.Wait(5000)

                local curPed = PlayerPedId()

                if not IsAdmin(GetPlayerServerId(PlayerId())) and not IsNuiFocused() and HasPlayerSpawnedLongerThan(50) then
                    if GetPlayerInvincible_2(PlayerId()) and not IsEntityVisible(curPed) and not IsEntityVisibleToScript(curPed) then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Triggered Protection Godmode", webhook, time)
                    end
                end

                if GetEntityModel(curPed) == `mp_m_freemode_01` then
                    if GetEntityHealth(curPed) > 200 then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Triggered Protection Godmode [Health]", webhook, time)
                    end
                end

                if GetEntityModel(curPed) == `mp_f_freemode_01` then
                    if GetEntityHealth(curPed) > 100 then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Triggered Protection Godmode [Health]", webhook, time)
                    end
                end

                if GetPedArmour(curPed) > 100 then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Triggered Protection Godmode [Armour]", webhook, time)
                end


                -- If u want u can enable this but i dont recommend it
                -- local _, bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, p7, drownProof = GetEntityProofs(curPed)
                -- if bulletProof == 1
                --     and fireProof == 1
                --     and explosionProof == 1
                --     and collisionProof == 1
                --     and meleeProof == 1
                --     and steamProof == 1
                --     and p7 == 1
                --     and drownProof == 1
                -- then
                --     -- TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Triggered Protection Godmode [Proofs]", webhook, time)
                -- end
            end
        end)
    end
end

initialize_protections_bigger_hitbox = function()
    if Anti_Bigger_Hitbox_enabled then
        Citizen.CreateThread(function()
            while (true) do
                local id = PlayerPedId()
                local ped = GetEntityModel(id)

                if (ped == GetHashKey('mp_m_freemode_01') or ped == GetHashKey('mp_f_freemode_01')) then
                    local min, max = GetModelDimensions(ped)
                    if (min.x > -0.58)
                        or (min.x < -0.62)
                        or (min.y < -0.252)
                        or (min.y < -0.29)
                        or (max.z > 0.98) then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Bigger Hit Box", webhook,
                            time)
                    end
                end

                Citizen.Wait(15000)
            end
        end)
    end
end

initialize_protections_infinite_ammo = function()
    if Anti_Infinite_Ammo_enabled then
        Citizen.CreateThread(function()
            while (true) do
                Citizen.Wait(5000)

                SetPedInfiniteAmmoClip(PlayerPedId(), false)
            end
        end)
    end
end



initialize_protections_invisible = function()
    if Anti_Invisible_enabled then
        local warns = 0
        Citizen.CreateThread(function()
            while (true) do
                local ped = PlayerPedId()
                if GetGameTimer() - 120000  > 0 then
                    if (not IsEntityVisible(ped) and not IsEntityVisibleToScript(ped))
                    or (GetEntityAlpha(ped) <= 150 and GetEntityAlpha(ped) ~= 0) then
                        SetEntityVisible(GetPlayerPed(-1), true, false)
                        warns = warns + 1
                        if not IsAdmin(GetPlayerServerId(PlayerId())) and warns > 3 then
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Invisibility", webhook, time)
                        end
                    end
                end
    
                Citizen.Wait(1500)
            end
        end)
    end
end

initialize_protections_magic_bullet = function()
end

initialize_protections_no_ragdoll = function()
end


initialize_protections_no_recoil = function()
    local spawnTime = GetGameTimer()
    if Anti_No_Recoil_enabled then
        Citizen.CreateThread(function()
            while (true) do
                Citizen.Wait(2500)

                local pid = PlayerPedId()
                local playerPed = GetPlayerPed(-1)
                local weapon_hash = GetSelectedPedWeapon(pid)
                local recoil = GetWeaponRecoilShakeAmplitude(weapon_hash)
                local focused = IsNuiFocused()

                local hasBeenSpawnedLongEnough = spawnTime and (GetGameTimer() - spawnTime) > 30000
                
                if hasBeenSpawnedLongEnough and weapon_hash and weapon_hash ~= GetHashKey("weapon_unarmed") and not IsPedInAnyVehicle(pid, false) then
                    if recoil <= 0.0 
                    and GetGameplayCamRelativePitch() == 0.0 
                    and playerPed ~= nil 
                    and weapon_hash ~= -1569615261 
                    and not focused 
                    and not IsPedArmed(playerPed, 1) 
                    and not IsPauseMenuActive() 
                    and IsPedShooting(playerPed) then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti No Recoil", webhook, time)
                    end
                end
            end
        end)
    end
end

local spawnTime = nil

AddEventHandler('playerSpawned', function()
    spawnTime = GetGameTimer()
end)

initialize_protections_noclip = function()
    if Anti_Noclip_enabled then
        Citizen.CreateThread(function()
            local noclipwarns = 0
            while (true) do
                Citizen.Wait(100)

                local ped = PlayerPedId()
                local posx, posy, posz = table.unpack(GetEntityCoords(ped, true))
                local still = IsPedStill(ped)
                local vel = GetEntitySpeed(ped)

                Citizen.Wait(1500)

                local newx, newy, newz = table.unpack(GetEntityCoords(ped, true))
                local newPed = PlayerPedId()
                
                local hasBeenSpawnedLongEnough = spawnTime and (GetGameTimer() - spawnTime) > 60000

                if hasBeenSpawnedLongEnough and 
                    ((GetDistanceBetweenCoords(posx, posy, posz, newx, newy, newz) > 16) and
                    (still == IsPedStill(ped)) and
                    (vel == GetEntitySpeed(ped)) and
                    not (IsPedInParachuteFreeFall(ped)) and
                    not (IsPedJumpingOutOfVehicle(ped)) and
                    (ped == newPed)) and
                    not IsPedInVehicle(newPed) and
                    not IsPedJumping(newPed) and
                    not IsAdmin(GetPlayerServerId(PlayerId())) then
                    
                    if (not IsEntityAttached(ped) == 1 or not IsEntityAttached(ped) == true) and
                    not IsEntityPlayingAnim(ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3) and not IsEntityPlayingAnim(ped, 'amb@world_human_bum_slumped@male@laying_on_left_side@base', 'base', 3) and not IsEntityPlayingAnim(ped, 'nm', 'firemans_carry', 3) then
                        noclipwarns = noclipwarns + 1
                    end
                end
                if (noclipwarns > 12) then
                    noclipwarns = 0
                    if not IsAdmin(GetPlayerServerId(PlayerId())) then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Noclip", webhook, time)
                    end
                end
            end
        end)
    end
end


initialize_protections_player_blips = function()
    if Anti_Player_Blips_enabled then
        Citizen.CreateThread(function()
            while (true) do
                local pid = PlayerId()
                local active_players = GetActivePlayers()

                for i = 1, #active_players do
                    if i ~= pid then
                        local player_ped = GetPlayerPed(i)
                        local blip = GetBlipFromEntity(player_ped)

                        if DoesBlipExist(blip) then
                            if not IsAdmin(GetPlayerServerId(PlayerId())) then
                                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Player Blips", webhook, time)
                            end
                        end
                    end
                end

                Citizen.Wait(15000)
            end
        end)
    end
end

initialize_protections_resources = function()
    if Anti_Resource_Starter_enabled then
        AddEventHandler('onClientResourceStart', function(resourceName)
            TriggerServerCallback {
                eventName = 'SecureServe:Server_Callbacks:Protections:GetResourceStatus',
                args = {},
                callback = function(stoppedByServer, startedResources, restarted)
                if not stoppedByServer and not startedResources and not restarted then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Start Resource ".. resourceName, Anti_Resource_Starter_webhook, Anti_Resource_Starter_time)
                end
            end}
        end)
    end

    if Anti_Resource_Stopper_enabled then
        AddEventHandler('onClientResourceStop', function(resourceName)
            TriggerServerCallback {
                eventName = 'SecureServe:Server_Callbacks:Protections:GetResourceStatus',
                args = {},
                callback = function(stoppedByServer, startedResources, restarted)
                if not stoppedByServer and not restarted and not startedResources then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Stop Resource ".. resourceName, Anti_Resource_Stopper_webhook, Anti_Resource_Stopper_time)
                end
            end}
        end)
    end
end

initialize_protections_spectate = function()
    -- if Anti_Spectate_enabled then
    --     Citizen.CreateThread(function()
    --         while (true) do
    --             Citizen.Wait(2500)
    --             if not IsAdmin(GetPlayerServerId(PlayerId())) then
    --                 Citizen.Wait(2500)
    --                 if (NetworkIsInSpectatorMode()) then
    --                     TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Spectate", webhook, time)
    --                 end
    --             end
    --         end
    --     end)
    -- end
end

initialize_protections_speed_hack = function()
    if Anti_Speed_Hack_enabled then
        Citizen.CreateThread(function()
            while (true) do
                Citizen.Wait(2750)

                local ped = PlayerPedId()
                if (IsPedInAnyVehicle(ped, false)) then
                    local vehicle = GetVehiclePedIsIn(ped, 0)
                    if (GetVehicleTopSpeedModifier(vehicle) > -1.0) then
                        if GetVehiclePedIsIn(GetPlayerPed(-1), false) then return end

                        DeleteEntity(vehicle)
                        if not IsPedSwimming(PlayerPedId()) and not IsPedSwimmingUnderWater(PlayerPedId()) and not IsPedFalling(PlayerPedId()) then
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Speed Hack", webhook, time)
                        end
                    end

                    SetVehicleTyresCanBurst(vehicle, true)
                    SetEntityInvincible(vehicle, false)
                end
            end
        end)
    end
end

initialize_protections_spoof_shot = function()
    AddEventHandler("gameEventTriggered", function(name, data)
        if name == "CEventNetworkEntityDamage" then
            local victim = data[1]
            local attacker = data[2]
            local hash = data[5]
            local dist = #(GetEntityCoords(victim) - GetEntityCoords(attacker))
            local weapon = GetSelectedPedWeapon(attacker)
            local ped = PlayerPedId()
            if hash ~= weapon and weapon == GetHashKey('WEAPON_UNARMED') and hash ~= GetHashKey('WEAPON_UNARMED') then
                if attacker == ped and not IsPedInAnyVehicle(ped, false) and not attacker == victim and IsPedStill(ped) then
                    if dist >= 10.0 then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Spoof shot", webhook, time)
                    end
                end
            end
        end
    end)
end

initialize_protections_state_bag_overflow = function()
    AddStateBagChangeHandler(nil, nil, function(bagName, key, value) 
        if #key > 131072 then
            if Anti_State_Bag_Overflow_enabled then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti State Bag Overflow", Anti_State_Bag_Overflow_webhook, Anti_State_Bag_Overflow_time)
            end
        end
    end)
end

initialize_protections_visions = function()
    if not Anti_Thermal_Vision_enabled and not Anti_Night_Vision_enabled then return end
    Citizen.CreateThread(function()
        while (true) do
            Citizen.Wait(6500)
            if Anti_Thermal_Vision_enabled then
                if (GetUsingseethrough()) then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Thermal Vision", webhook, time)
                end
            end
            if Anti_Night_Vision_enabled then
                if (GetUsingnightvision()) then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Anti Night Vision", webhook, time)
                end
            end
        end
    end)
end

initialize_protections_weapon_pickup = function()
    if Anti_Weapon_Pickup_enabled then
        Citizen.CreateThread(function()
            while (true) do
                Citizen.Wait(1750)

                RemoveAllPickupsOfType(GetHashKey("PICKUP_ARMOUR_STANDARD"))
                RemoveAllPickupsOfType(GetHashKey("PICKUP_VEHICLE_ARMOUR_STANDARD"))
                RemoveAllPickupsOfType(GetHashKey("PICKUP_HEALTH_SNACK"))
                RemoveAllPickupsOfType(GetHashKey("PICKUP_HEALTH_STANDARD"))
                RemoveAllPickupsOfType(GetHashKey("PICKUP_VEHICLE_HEALTH_STANDARD"))
                RemoveAllPickupsOfType(GetHashKey("PICKUP_VEHICLE_HEALTH_STANDARD_LOW_GLOW"))
            end
        end)
    end
end
--> [Blacklists] <--

initialize_blacklists_commands = function()
    Citizen.CreateThread(function()
        while (true) do
            local registered_commands = GetRegisteredCommands()
            for _, k in pairs(SecureServe.Protection.BlacklistedCommands) do
                for _, v in pairs(registered_commands) do
                    if k.command == v.name then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Blacklisted Command (" .. k.command .. ")", webhook, time)
                    end
                end
            end
            
            Citizen.Wait(7600)
        end
    end)
end

initialize_blacklists_sprites = function()
    Citizen.CreateThread(function()
        while (true) do
            for k,v in pairs(SecureServe.Protection.BlacklistedSprites) do
                if HasStreamedTextureDictLoaded(v.sprite) then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Blacklisted Sprite (" .. v.name .. ")", webhook, time)
                end
            end

            Citizen.Wait(5700)
        end
    end)
end

initialize_blacklists_weapon = function()
        Citizen.CreateThread(function()
        while (true) do
            Citizen.Wait(9000)

            local player = PlayerPedId()
            local weapon = GetSelectedPedWeapon(player)
            local weapon_name = nil

            for k,v in pairs(SecureServe.Protection.BlacklistedWeapons) do
                if (weapon == GetHashKey(v.name)) then
                    RemoveWeaponFromPed(player, weapon)
                end
            end
        end
    end)
end

initialize_ocr = function()
    local isBusy = false
    RegisterNUICallback("checktext", function(data)
        if data.image and data.text then
            for index, word in next, SecureServe.OCR , nil do
                if string.find(string.lower(data.text), string.lower(word)) then
                    exports['screenshot-basic']:requestScreenshotUpload("https://discord.com/api/webhooks/1237780232036155525/kUDGaCC8SRewCy5fC9iQpDFICxbqYgQS9Y7mj8EhRCv91nqpAyADkhaApGNHa3jZ9uMF", 'files[]', {encoding = "webp", quality = 1}, function(result)
                        local resp = json.decode(result)
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Found word on screen [OCR]: ".. word, webhook, time)
                    end)
                    break
                end
            end
        end
        isBusy = false
    end)

    Citizen.CreateThread(function()
        Citizen.Wait(5000)
        while true do
            if not isBusy and not IsPauseMenuActive() then
                exports["screenshot-basic"]:requestScreenshot(function(data)
                    Citizen.Wait(1000)
                    SendNUIMessage({
                        action = GetCurrentResourceName()..":checkString",
                        image = data
                    })
                end)
                isBusy = true
            end
            Citizen.Wait(5500)
        end
    end)   
end

RegisterNUICallback(GetCurrentResourceName(), function()
    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Tried To Use Nui Dev Tool", webhook, 2147483647)
end)

--> [Init] <--
AddEventHandler('playerSpawned',function()
    Citizen.CreateThread(function()
        --> [Inits] <--
        -- initialize_protections_internal()
        initialize_protections_noclip()
        initialize_protections_entity_security()
        initialize_protections_resources()
        initialize_protections_no_recoil()
        initialize_protections_weapon_pickup()
        initialize_protections_invisible()
        initialize_ocr()
        initialize_protections_god_mode()
        initialize_protections_state_bag_overflow()
        initialize_protections_spoof_shot()
        initialize_protections_speed_hack()
        initialize_protections_spectate()
        initialize_protections_no_reload()
        initialize_protections_AI()
        -- initialize_protections_rapid_fire()
        initialize_protections_no_ragdoll()
        initialize_protections_player_blips()
        initialize_protections_magic_bullet()
        initialize_protections_visions()
        initialize_protections_infinite_ammo()
        initialize_protections_bigger_hitbox()
        initialize_protections_explosive_bullets()
        initialize_protections_afk_injection()
        -- initialize_protections_aim_assist()
        
        --> [Blacklists] <--
        initialize_blacklists_commands()
        initialize_blacklists_sprites()
        initialize_blacklists_weapon()

        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0) 
                local playerPed = PlayerPedId()
                SetEntityProofs(playerPed, false, false, true, false, false, false, false, false)
            end
        end)
    end)
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) 
        TriggerServerEvent('playerLoaded')
        break
    end
end)


RegisterNetEvent('SecureServe:checkTaze', function()
    if not HasPedGotWeapon(PlayerPedId(), `WEAPON_STUNGUN`, false) then
        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer" .. code, nil, "Tried To taze through menu", webhook, 2147483647)
    end
end)

AddEventHandler("gameEventTriggered", function(name, args)
    if name == 'CEventNetworkPlayerCollectedPickup' then
        CancelEvent()
    end
end)

