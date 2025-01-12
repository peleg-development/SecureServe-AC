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

local alive = {}
local allowedStop = {}
local failureCount = {}

local checkInterval = 5000  
local maxFailures = 40   

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            alive[tonumber(playerId)] = false
            TriggerClientEvent('checkalive', tonumber(playerId))
        end

        Wait(checkInterval)

        for _, playerId in ipairs(players) do
            if not alive[tonumber(playerId)] and allowedStop[tonumber(playerId)] then
                failureCount[tonumber(playerId)] = (failureCount[tonumber(playerId)] or 0) + 1
                if failureCount[tonumber(playerId)] >= maxFailures then
                    punish_player(tonumber(playerId), 'You have been dropped for not responding to the server.', webhook, time)
                end
            else
                failureCount[tonumber(playerId)] = 0
            end
        end
    end
end))

RegisterNetEvent('addalive', LPH_NO_VIRTUALIZE(function()
    local src = source
    alive[tonumber(src)] = true
end))

RegisterNetEvent('allowedStop', LPH_NO_VIRTUALIZE(function()
    local src = source
    allowedStop[src] = true
end))

AddEventHandler('playerDropped', function()
    local src = source
    alive[src] = nil
    allowedStop[src] = nil
    failureCount[src] = nil
end)



RegisterNetEvent('requestConfig', function()
    local src = source
    TriggerClientEvent('receiveConfig', src, SecureServe)
end)

GlobalState.SecureServe_events = math.random(1, 99999);

local function setTimeState()
    GlobalState.SecureServe = os.time()
end

Citizen.CreateThread(LPH_JIT_MAX(function()
    while true do
        setTimeState()  
        Citizen.Wait(760)
    end
end))

local playerStates = {}

RegisterNetEvent('playerLoaded', function()
    local src = source
    playerStates[src] = { loaded = true, loadTime = GetGameTimer() }
end)


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
--> [Methoods] <--
local COLORS = {
    ["Red Orange"] = "^1",
    ["Light Green"] = "^2",
    ["Light Yellow"] = "^3",
    ["Dark Blue"] = "^4",
    ["Light Blue"] = "^5",
    ["Violet"] = "^6",
    ["White"] = "^7",
    ["Blood Red"] = "^8",
    ["Fuchsia"] = "^9"
}

--> [EVENTS] <--
local encryption_key = "c4a2ec5dc103a3f730460948f2e3c01df39ea4212bc2c82f"

local xor_encrypt = LPH_NO_VIRTUALIZE(function(text, key)
    local res = {}
    local key_len = #key
    for i = 1, #text do
        local xor_byte = string.byte(text, i) ~ string.byte(key, (i - 1) % key_len + 1)
        res[i] = string.char(xor_byte)
    end
    return table.concat(res)
end)

local encryptEventName = LPH_NO_VIRTUALIZE(function(event_name, key)
    local encrypted = xor_encrypt(event_name, key)
    local result = ""
    for i = 1, #encrypted do
        result = result .. string.format("%03d", string.byte(encrypted, i))
    end
    return result
end)

local xor_decrypt = LPH_NO_VIRTUALIZE(function(encrypted_text, key)
    local res = {}
    local key_len = #key
    for i = 1, #encrypted_text do
        local xor_byte = string.byte(encrypted_text, i) ~ string.byte(key, (i - 1) % key_len + 1)
        res[i] = string.char(xor_byte)
    end
    return table.concat(res)
end)

local decryptEventName = LPH_NO_VIRTUALIZE(function(encrypted_name, key)
    local encrypted = {}
    for i = 1, #encrypted_name, 3 do
        local byte_str = encrypted_name:sub(i, i + 2)
        local byte = tonumber(byte_str)
        if byte and byte >= 0 and byte <= 255 then
            table.insert(encrypted, string.char(byte))
        else
            -- print("Decryption failed: invalid byte detected ->", byte_str)
            return encrypted_name
        end
    end
    return xor_decrypt(table.concat(encrypted), key)
end)

local events = {}

RegisterNetEvent("TriggerdServerEventCheck", function(event, time)
    events[event] = time
end)

local function isWhitelisted(event_name)
    if not SecureServe or not SecureServe.EventWhitelist or type(SecureServe.EventWhitelist) ~= "table" then
        -- print("Error: EventWhitelist is missing or not a table.")
        return false
    end

    if not event_name or type(event_name) ~= "string" or event_name == "" then
        -- print("Error: event_name is invalid or empty.")
        return false
    end    

    for _, whitelisted_event in ipairs(SecureServe.EventWhitelist) do
        if type(whitelisted_event) == "string" then
            if event_name == whitelisted_event or event_name == encryptEventName(whitelisted_event, encryption_key) then
                return true
            end
        else
            -- print("Warning: Non-string value found in EventWhitelist. Skipping.")
        end
    end

    return false
end

local encryption_key = "c4a2ec5dc103a3f730460948f2e3c01df39ea4212bc2c82f"


exports('CheckTime', function(event, time, source)
    Wait(1000)

    if type(event) ~= "string" or event == "" then
        -- print("Invalid event name:", tostring(event))
        punish_player(source, "Triggered invalid event: " .. tostring(event), webhook, time)
        return
    end

    local playerState = playerStates[source]
    if playerState and playerState.loaded then
        if not events[event] and not isWhitelisted(event) then
            Wait(500)
            if not events[event] then
                Wait(500)
                local encrypted_event = encryptEventName(event, encryption_key)
                if not events[event] and not events[encrypted_event] then
                    punish_player(source, "Triggered unauthorized event: " .. event, webhook, time)
                end
            end
        else
            local eventTime = events[event]
            if eventTime == false then return end
            if eventTime and math.abs(time - eventTime) >= 10 then
                punish_player(source, "Exceeded timestamp for event: " .. event, webhook, time)
            end
        end
    end
end)


exports('IsEventWhitelisted', LPH_NO_VIRTUALIZE(function(event_name, src)
    -- print(src, event_name, (GetPlayerPing(src) > 0) )
    if not isWhitelisted(event_name) then
        if src and GetPlayerPing(src) > 0 then
            punish_player(src, "Triggerd server event via excutor: " .. event_name, webhook, 2147483647)
        end
    end
end))

sm_print = function(color, content)
    print(COLORS["Light Blue"] .. "[SecureServe] " .. COLORS["White"] .. ": " .. COLORS[color] .. content .. COLORS["White"])
end

RegisterNetEvent("SecureServe:Server:Methods:Print", function(color, content)
    print(color, content)
end)

escape_pattern = function(s)
	return s:gsub("([^%w])", "%%%1")
end

local admins = {}
AddEventHandler("txAdmin:events:adminAuth",function (data)
    if data.isAdmin then
        table.insert(admins, data.netid)
        admins[data.netid] = true
        print(('^7[^4 AUTH ^7] ✅ Admin [%s] %s (%s) has been authenticated using txAdmin!'):format(data.netid,GetPlayerName(data.netid),data.username))
    end
end)

Isadmin = function(pl)
    return SecureServe.IsAdmin(pl) or admins[pl] == true
end

IsMenuAdmin = function(pl)
    local identifiers = GetPlayerIdentifiers(pl)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 6) == "steam:" then
            for _, adminID in ipairs(SecureServe.AdminMenu.Admins) do
                if id == adminID then
                    return true 
                end
            end
        end
    end
    return false
end


RegisterNetEvent('SecureServe:RequestAdminStatus', function(player, cb)
    local src = source
    local isAdmin = Isadmin(src) 
    cb(isAdmin)
end)

RegisterNetEvent('SecureServe:RequestMenuAdminStatus', function(player, cb)
    local src = source
    local isMenuAdmin = IsMenuAdmin(src) 
    TriggerClientEvent('SecureServe:ReturnMenuAdminStatus', src, isMenuAdmin)
end)


RegisterServerCallback {
    eventName = 'SecureServe:Server_Callbacks:Protections:IsMenuAdmin',
    eventCallback = function(source)
        return SecureServe.IsMenuAdmin(source)
    end
}

RegisterServerCallback {
    eventName = 'SecureServe:Server_Callbacks:Protections:IsAdmin',
    eventCallback = function(source)
        return SecureServe.Isadmin(source)
    end
}

send_log = LPH_JIT_MAX(function(webhook, title, message)
    local embed = {
        {
            ["color"] = "3447003",
            ["title"] = "SecureServe | " .. title,
            ["description"] = message,
            ["footer"] = {
                ["text"] = "SecureServe | Secure Your Server Now",
                ["icon_url"] = "https://images-ext-1.discordapp.net/external/ATCidz-Uio1fj26KQZH1mmy20YnxQxQxv-sc0gBFGFw/%3Fformat%3Dwebp%26quality%3Dlossless/https/images-ext-1.discordapp.net/external/z9bSkH3p8iTlOClfnK7zVOEC9i5xcORJZfsuqlcf1XA/https/cdn.discordapp.com/icons/814390233898156063/c959fc0889d2436b87ccbf2f73d4f30e.png?format=webp&quality=lossless"
            },
        }
    }
    
    PerformHttpRequest(webhook, function(error, text, footer) end, "POST", json.encode({username = "SecureServe | Logging System", avatar_url = "https://images-ext-1.discordapp.net/external/ATCidz-Uio1fj26KQZH1mmy20YnxQxQxv-sc0gBFGFw/%3Fformat%3Dwebp%26quality%3Dlossless/https/images-ext-1.discordapp.net/external/z9bSkH3p8iTlOClfnK7zVOEC9i5xcORJZfsuqlcf1XA/https/cdn.discordapp.com/icons/814390233898156063/c959fc0889d2436b87ccbf2f73d4f30e.png?format=webp&quality=lossless", embeds = embed}), {["Content-Type"] = "application/json"})
end)

function ScreenshotLog(data, reason, punishment, banId, webhook)
  local steam = data.steam
  local discord = data.discord
  local license = data.license
  local ip = data.ip
  local HWID = data.hwid
  local playerId = data.playerId
  local steamDec = tonumber(steam:gsub("steam:", ""), 16)
  local steamprofile = steam == "Not Found" and "Steam profile not found" or ("[Steam Profile](https://steamcommunity.com/profiles/%s)"):format(steamDec)
  local discordping = "<@" .. discord:gsub('discord:', '') .. "> (".. discord:gsub('discord:', '') .. ")"

  local embed = {
      {
          color = 38880, 
          author = {
              name = "SecureServe Logs",
              icon_url = "https://images-ext-1.discordapp.net/external/ATCidz-Uio1fj26KQZH1mmy20YnxQxQxv-sc0gBFGFw/%3Fformat%3Dwebp%26quality%3Dlossless/https/images-ext-1.discordapp.net/external/z9bSkH3p8iTlOClfnK7zVOEC9i5xcORJZfsuqlcf1XA/https/cdn.discordapp.com/icons/814390233898156063/c959fc0889d2436b87ccbf2f73d4f30e.png?format=webp&quality=lossless"
          },
          title = "Player Detected",
          description = ("**Punishment Method:** %s\n**Reason:** %s\n**Ban ID:** %s"):format(punishment, reason, banId),
          fields = {
              { name = "Player", value = "[#" .. playerId .. "] " .. GetPlayerName(playerId), inline = true },
              { name = "Discord", value = discordping, inline = true },
              { name = "Steam", value = steamprofile, inline = true },
              { name = "License", value = license or "N/A", inline = true },
              { name = "HWID", value = HWID or "N/A", inline = true },
              { name = "IP Address", value = ("[Info](https://ipinfo.io/%s)"):format(ip:gsub('ip:', '')), inline = true },
          },
          image = { url = data.image },
          footer = {
              text = "SecureServe Anticheat - " .. os.date('%d.%m.%Y - %H:%M:%S'),
              icon_url = "https://images-ext-1.discordapp.net/external/ATCidz-Uio1fj26KQZH1mmy20YnxQxQxv-sc0gBFGFw/%3Fformat%3Dwebp%26quality%3Dlossless/https/images-ext-1.discordapp.net/external/z9bSkH3p8iTlOClfnK7zVOEC9i5xcORJZfsuqlcf1XA/https/cdn.discordapp.com/icons/814390233898156063/c959fc0889d2436b87ccbf2f73d4f30e.png?format=webp&quality=lossless"
          }
      }
  }

  PerformHttpRequest(SecureServe.Webhooks.Simple, function(err, text, headers) end, 'POST', json.encode({ username = "SecureServe Logs", avatar_url = "https://images-ext-1.discordapp.net/external/ATCidz-Uio1fj26KQZH1mmy20YnxQxQxv-sc0gBFGFw/%3Fformat%3Dwebp%26quality%3Dlossless/https/images-ext-1.discordapp.net/external/z9bSkH3p8iTlOClfnK7zVOEC9i5xcORJZfsuqlcf1XA/https/cdn.discordapp.com/icons/814390233898156063/c959fc0889d2436b87ccbf2f73d4f30e.png?format=webp&quality=lossless", embeds = embed }), { ['Content-Type'] = 'application/json' })
end

local banned = {}
function getBanID()
    local banID = 0
    local data = getBanList()
    for id, _ in pairs(data) do
        banID = math.max(banID, id)
    end
    return banID + 1
end

function BetterPrint(text,type)
    local types = {
        ["error"] = "^7[^1 ERROR ^7] ",
        ["warning"] = "^7[^3 WARNING ^7] ",
        ["config"] = "^7[^3 CONFIG WARNING ^7] ",
        ["info"] = "^7[^5 INFO ^7] ",
        ["success"] = "^7[^2 SUCCESS ^7] ",
    }
    return print("^7[^5 SecureServe ^7] "..types[string.lower(type)]..text)
  end

function getBanList()
    local path = GetResourcePath(GetCurrentResourceName()) .. "/bans.json"
    local file = LoadResourceFile(GetCurrentResourceName(), "bans.json")
    if not file then
        return {}
    end
    local decoded = json.decode(file)
    if not decoded then
        return {}
    end
    return decoded
end

RegisterNetEvent('banPlayerAntiCheat', function(player, reason, webhook, raw_time)
    punish_player(player, reason, webhook, raw_time)
end)

exports('banPlayer', function(player, reason)
    local webhook = SecureServe.Webhooks.Simple
    local raw_time = 2147483647

    punish_player(player, reason, webhook, raw_time)
end)

function punish_player(player, reason, webhook, raw_time)
if not banned[player] then

    if IsPlayerAceAllowed(player, 'bypass') then return end
    if GetPlayerPing(player) < 1 then
        print("Player " .. player .. " is not in the server.")
        return
    end

    if type(raw_time) ~= "number" then
        time = SecureServe.BanTimes[raw_time]
    end

    local name = GetPlayerName(player)
    local steam = GetPlayerIdentifierByType(player, "steam") or "none"
    local license = GetPlayerIdentifierByType(player, "license") or "none"
    local license2 = GetPlayerIdentifierByType(player, "license2") or "none"
    local discord = GetPlayerIdentifierByType(player, "discord") or "none"
    local xbl = GetPlayerIdentifierByType(player, "xbl") or "none"
    local liveid = GetPlayerIdentifierByType(player, "liveid") or "none"
    local ip = GetPlayerIdentifierByType(player, "ip") or "none"
    local hwid1 = GetPlayerToken(player, 1) or "none"
    local hwid2 = GetPlayerToken(player, 2) or "none"
    local hwid3 = GetPlayerToken(player, 3) or "none"
    local hwid4 = GetPlayerToken(player, 4) or "none"
    local hwid5 = GetPlayerToken(player, 5) or "none"
    
    local currentTimestamp = os.time()
    local date = tostring(os.date("%Y-%m-%d %H:%M:%S", currentTimestamp))
    local expire_date = tostring(os.date("%Y-%m-%d %H:%M:%S", (currentTimestamp + time)))

    local id = getBanID()
    local data = getBanList()

    BetterPrint(("Player ^3%s^7 has been banned for ^3%s^7"):format(name,reason),"info")
    TriggerClientEvent('SecureServe:Server:Methods:GetScreenShot', player, reason, id, webhook, time)
    banned[player] = true
    local ban_info = {
        id = id,
        name = name,
        reason = reason,
        steam = steam,
        license = license,
        license2 = license2,
        discord = discord,
        xbl = xbl,
        liveid = liveid,
        ip = ip,
        hwid1 = hwid1,
        hwid2 = hwid2,
        hwid3 = hwid3,
        hwid4 = hwid4,
        hwid5 = hwid5,
        expire = expire_date
    }

    data[#data + 1] = ban_info
    SaveResourceFile(GetCurrentResourceName(), "bans.json", json.encode(data, { indent = true }), -1)


    if webhook == nil then webhook = "https://discord.com/api/webhooks/1237077520210329672/PvyzM9Vr43oT3BbvBeLLeS-BQnCV4wSUQDhbKBAXr9g9JcjshPCzQ7DL1pG8sgjIqpK0" end
    send_log(
        webhook,
        "Punished Player - " .. name,
        "Player/Punishment Information\n----------------------------------------------------------------------------\nPlayer Name: `" .. name ..
        "`\nTime: `" .. raw_time ..
        "`\nReason: `" .. reason ..
        "`\nSteam: `" .. steam or "none" ..
        "`\nIPV4: `" .. ip ..
        "`\nRockstar License: `" .. license or "none"..
        "`\nRockstar License 2: `" .. license2 or "none" ..
        "`\nXbox: `" .. xbl or "none" ..
        "`\nXbox Live: `" .. liveid or "none" ..
        "`\nDiscord: `" .. discord or "none" ..
        "`\nHWID 1: `" .. hwid1 or "none"..
        "`\nHWID 2: `" .. hwid2 or "none"..  
        "`\nHWID 3: `" .. hwid3 or "none".. 
        "`\nHWID 4: `" .. hwid4 or "none".. 
        "`\nHWID 5: `" .. hwid5 or "none".. "`"
    )

    if time == 2147483647 then
        send_log(
            "https://discord.com/api/webhooks/1237077520210329672/PvyzM9Vr43oT3BbvBeLLeS-BQnCV4wSUQDhbKBAXr9g9JcjshPCzQ7DL1pG8sgjIqpK0",
            "A player has been banned for " .. reason
        )
    end
end
end


RegisterNetEvent('SecureServe:Server:Methods:Upload', function (screenshot, reason, id, time)
    local playername = GetPlayerName(source)
    local punish = "ban"
    local banID = id

    local HWID = GetPlayerToken(source, 1)
    local HWID2 = GetPlayerToken(source, 2)
    local HWID3 = GetPlayerToken(source, 3)
    local HWID4 = GetPlayerToken(source, 4)
    local HWID5 = GetPlayerToken(source, 5)
    if HWID5 == nil then HWID5 = "Not Found" end
    if HWID4 == nil then HWID4 = "Not Found" end
    if HWID3 == nil then HWID3 = "Not Found" end
    if HWID2 == nil then HWID2 = "Not Found" end
    if HWID == nil then HWID = "Not Found" end

    local steam = "Not Found"
    local ip = "Not Found"
    local discord = "Not Found"
    local license = "Not Found"
    local fivem = "Not Found"

    for k, v in pairs(GetPlayerIdentifiers(source)) do
      if string.sub(v, 1, string.len("steam:")) == "steam:" then
        steam = v
      elseif string.sub(v, 1, string.len("license:")) == "license:" then
        license = v
      elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
        discord = v
      elseif string.sub(v, 1, string.len("fivem:")) == "fivem:" then
        fivem = v
      elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
        ip = v
      end
    end
    
    steam = steam:gsub('steam:', '')
    discord = discord:gsub('discord:', '')
    license = license:gsub('license:', '')
    fivem = fivem:gsub('fivem:', '')
    ip = ip:gsub('ip:', '')
    
    local requestPayload = json.encode({
        steamhex = steam,
        license = license,
        discord = discord,
        token = HWID 
    })


    ScreenshotLog({license=license,discord=discord,steam=steam,ip=ip,fivem=fivem,hwid=HWID,image=screenshot,playerId=tostring(source)}, reason, punish, banID)
    
    banned[source] = true
    if reason ~= 'External Executor Detected (Player Usally Has (SkriptGG, HX, TZX)' then
    DropPlayer(source, "You have been punished from " .. SecureServe.ServerName .. 
    ".\nTo view more information please reconnect to the server.")
    end
    banned[source] = nil
end)

RegisterNetEvent('TEST', function()
    print('tes')
end)



RegisterNetEvent("SecureServe:Server:Methods:PunishPlayer" .. GlobalState.SecureServe_events, function(player, reason, webhook, time)
    if not player then player = source end
    punish_player(player, reason, webhook, time)
end)



AddEventHandler("playerConnecting", function(name, setCallback, deferrals)
    local src = source
    local tokens = {}
    for i = 1, 5 do
        table.insert(tokens, GetPlayerToken(src, i))
    end
    deferrals.defer()
    local hwid_2 = GetPlayerToken(source, 1)
    Citizen.Wait(0)

    local data = getBanList()
    local identifiers = GetPlayerIdentifiers(src)
    local isBanned = false

    for _, identifier in ipairs(identifiers) do
        for _, ban in ipairs(data) do
            for k, v in pairs(ban) do
                if v == identifier then
                    isBanned = true
                    local id = ban.id or "Unknown Id"
                    local reason = ban.reason or "Unknown Reason"
                    local expire = ban.expire or "Unknown Expiry"
                    local updated = false

                    for i, token in ipairs(tokens) do
                        if ban["hwid" .. i] ~= token then
                            ban["hwid" .. i] = token
                            updated = true
                        end
                    end
                    if updated then
                        SaveResourceFile(GetCurrentResourceName(), "bans.json", json.encode(data, { indent = true }), -1)
                    end

                    local card = [[
                        {
                            "type": "AdaptiveCard",
                            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                            "version": "1.3",
                            "backgroundImage": {
                                "url": "https://www.transparenttextures.com/patterns/black-linen.png"
                            },
                            "body": [
                                {
                                    "type": "Container",
                                    "style": "emphasis",
                                    "bleed": true,
                                    "items": [
                                        {
                                            "type": "Image",
                                            "url": "https://img.icons8.com/color/452/error.png",
                                            "horizontalAlignment": "Center",
                                            "size": "Large",
                                            "spacing": "Large"
                                        },
                                        {
                                            "type": "TextBlock",
                                            "text": "Access Denied",
                                            "wrap": true,
                                            "horizontalAlignment": "Center",
                                            "size": "ExtraLarge",
                                            "weight": "Bolder",
                                            "color": "Attention",
                                            "spacing": "Medium"
                                        },
                                        {
                                            "type": "TextBlock",
                                            "text": "You are banned from this server.",
                                            "wrap": true,
                                            "horizontalAlignment": "Center",
                                            "size": "Large",
                                            "weight": "Bolder",
                                            "color": "Attention",
                                            "spacing": "Small"
                                        },
                                        {
                                            "type": "TextBlock",
                                            "text": "This ban never expires. If you think this was a mistake or you just want to appeal your ban, please join the support Discord below.",
                                            "wrap": true,
                                            "horizontalAlignment": "Center",
                                            "size": "Medium",
                                            "spacing": "Medium"
                                        }
                                    ]
                                }
                            ],
                            "actions": [
                                {
                                    "type": "Action.ShowCard",
                                    "title": "Ban Details",
                                    "card": {
                                        "type": "AdaptiveCard",
                                        "body": [
                                            {
                                                "type": "FactSet",
                                                "facts": [
                                                    {
                                                        "title": "Ban ID:",
                                                        "value": "%s"
                                                    },
                                                
                                                    {
                                                        "title": "Expires:",
                                                        "value": "Never"
                                                    }
                                                ]
                                            }
                                        ],
                                        "actions": [
                                            {
                                                "type": "Action.OpenUrl",
                                                "title": "Join Discord",
                                                "url": "%s",
                                                "style": "positive",
                                                "iconUrl": "https://img.icons8.com/ios-filled/452/discord-logo.png"
                                            }
                                        ]
                                    }
                                }
                            ]
                        }
                                       
                    ]]
                    
                    local discordLink = SecureServe.DiscordLink or "https://discord.com"
                    deferrals.presentCard(string.format(card, id, expire, discordLink), function(data, rawData) end)
                    Citizen.CreateThread(function()
                        while true do
                          Wait(0)
                          deferrals.presentCard(string.format(card, id, expire, discordLink), function(data, rawData) end)
                          CancelEvent()
                        end
                      end)
                    return
                end
            end
        end
    end

    deferrals.done()
end)


--> [Misc] <--
initialize_misc_module = function()
    local ac_name = GetCurrentResourceName()

    local function has_script_keywords(manifest_code)
        local keywords = {"client_script", "client_scripts", "server_script", "server_scripts", "shared_script", "shared_scripts"}
        for _, keyword in ipairs(keywords) do
            if string.find(manifest_code, keyword) then
                return true
            end
        end
        return false
    end

    local function install_module()
        local num_resources = GetNumResources()
        local changes = 0
    
        for i = 0, num_resources - 1 do
            local resource = GetResourceByFindIndex(i)
    
            if (resource ~= "_cfx_internal" and resource ~= "monitor") and (resource ~= ac_name) then
                local fxmanifest = LoadResourceFile(resource, "fxmanifest.lua")
                local resource_lua = LoadResourceFile(resource, "__resource.lua")
                local manifest_file = (fxmanifest and "fxmanifest.lua") or (resource_lua and "__resource.lua")
                local manifest_code = LoadResourceFile(resource, manifest_file)
    
                if manifest_code and not string.find(manifest_code, string.format([[shared_script "@%s/module.lua"]], ac_name)) then
                    if has_script_keywords(manifest_code) then
                        local str = string.format([[shared_script "@%s/module.lua"
%s]], ac_name, manifest_code)
                        SaveResourceFile(resource, manifest_file, str, -1)
                        changes = changes + 1
                    end
                end
            end
        end
    
        if changes > 0 then
            print("Exiting in 5 seconds...")
            sm_print("Blood Red", "Please Restart your server so the module will work! make sure secureserve is ensured first!")
            Citizen.Wait(5000)
        else
            print("No applicable resources need the module, or all already have it installed.")
        end
    end
    
    RegisterCommand("ssinstall", function(source, args, rawCommand)
        install_module()
    end, true)
    
    RegisterCommand("ssuninstall", function(_, args)
        local num_resources = GetNumResources()
        
        for i = 0, num_resources - 1 do
            local resource_name = GetResourceByFindIndex(i)
            if (resource_name ~= "_cfx_internal" and resource_name ~= "monitor") and (resource_name ~= ac_name) then
                local fxmanifest = LoadResourceFile(resource_name, "fxmanifest.lua")
                local resource = LoadResourceFile(resource_name, "__resource.lua")
                local manifest_file = (fxmanifest and "fxmanifest.lua") or (resource and "__resource.lua")
                local manifest_code = LoadResourceFile(resource_name, manifest_file)
    
                SaveResourceFile(resource_name, manifest_file, manifest_code:gsub(string.format([[shared_script "@%s/module.lua"]], args[1] or ac_name), ""), -1)
            end
        end
    
        print("Module has been uninstalled from all resources!")
        print("Exiting in 5 seconds...")
        Citizen.Wait(5000)
        os.exit(0)
    end, true)

    AddEventHandler('onResourceStart', function(resource)
        if resource == ac_name then
            install_module()
        end
    end)
end

initialize_misc_module()

--> [Prtoections] <--
initialize_protections_damage = LPH_JIT_MAX(function ()
    AddEventHandler("weaponDamageEvent", function(source, data)
        if true and data.weaponType == 3452007600 and data.weaponDamage == 512 then
            punish_player(source, "Tried to kill player using cheats", webhook, time)
            CancelEvent()
        elseif true and data.weaponType == 133987706 and data.damageTime > 200000 and data.weaponDamage > 200 then
            punish_player(source, "Tried to kill player using cheats", webhook, time)
            CancelEvent()
        end
    
        if true then
            if data.silenced and data.weaponDamage == 0 and data.weaponType == 2725352035 then
                punish_player(source, "Tried to kill player using cheats", webhook, time)
            elseif data.silenced and data.weaponDamage == 0 and data.weaponType == 3452007600 then
                punish_player(source, "Tried to kill player using cheats", webhook, time)
            end
        end
    end)
end)

initialize_protections_entity_lockdown = function()
    Citizen.CreateThread(function ()
        SetConvar("sv_filterRequestControl", "4")
        SetConvar("sv_entityLockdown", SecureServe.EntityLockdownMode)
        SetConvar("onesync_distanceCullVehicles", "true")
    end)
end

RegisterNetEvent('clearall', function()
    for i, obj in pairs(GetAllObjects()) do
        DeleteEntity(obj)
    end
    for i, ped in pairs(GetAllPeds()) do
        DeleteEntity(ped)
    end
    for i, veh in pairs(GetAllVehicles()) do
        DeleteEntity(veh)
    end
end)

function clear()
    for i, obj in pairs(GetAllObjects()) do
        DeleteEntity(obj)
    end
    for i, ped in pairs(GetAllPeds()) do
        DeleteEntity(ped)
    end
    for i, veh in pairs(GetAllVehicles()) do
        DeleteEntity(veh)
    end
end

initialize_protections_entity_spam = LPH_JIT_MAX(function()
    local SV_VEHICLES = {}
    local SV_PEDS = {}
    local SV_OBJECT = {}
    local SV_Userver = {}


    AddEventHandler('entityCreated', function (entity)
        if DoesEntityExist(entity) then
            local POPULATION = GetEntityPopulationType(entity)
            if POPULATION == 7 or POPULATION == 0 then
                TriggerClientEvent('checkMe', -1)
            end
        end
    end)

    AddEventHandler("entityCreated", function(ENTITY)
        if DoesEntityExist(ENTITY) then
            local TYPE       = GetEntityType(ENTITY)
            local OWNER      = NetworkGetFirstEntityOwner(ENTITY)
            local POPULATION = GetEntityPopulationType(ENTITY)
            local MODEL      = GetEntityModel(ENTITY)
            local HWID       = GetPlayerToken(OWNER, 0)
            if TYPE == 2 and POPULATION == 7 then
                if SV_VEHICLES[HWID] ~= nil then
                    SV_VEHICLES[HWID].COUNT = SV_VEHICLES[HWID].COUNT + 1
                    if os.time() - SV_VEHICLES[HWID].TIME >= 10 then
                        SV_VEHICLES[HWID] = nil
                    else
                        if SV_VEHICLES[HWID].COUNT >= SecureServe.maxVehicle then
                            for _, vehilce in ipairs(GetAllVehicles()) do
                                local ENO = NetworkGetFirstEntityOwner(vehilce)
                                if ENO == OWNER then
                                    if DoesEntityExist(vehilce) then
                                        DeleteEntity(vehilce)
                                    end
                                end
                            end
                            if not SV_Userver[HWID] then
                            SV_Userver[HWID] = true
                                clear()
                                punish_player(OWNER, "Try To Spam Vehicles: ".. SV_VEHICLES[HWID].COUNT, webhook, time)
                                CancelEvent()
                            end
                        end
                    end
                else
                    SV_VEHICLES[HWID] = {
                        COUNT = 1,
                        TIME  = os.time()
                    }
                end
            elseif TYPE == 1 and POPULATION == 7 then
                if SV_PEDS[HWID] ~= nil then
                    SV_PEDS[HWID].COUNT = SV_PEDS[HWID].COUNT + 1
                    if os.time() - SV_PEDS[HWID].TIME >= 10 then
                        SV_PEDS[HWID] = nil
                    else
                        for _, peds in ipairs(GetAllPeds()) do
                            local ENO = NetworkGetFirstEntityOwner(peds)
                            if ENO == OWNER then
                                if DoesEntityExist(peds) then
                                    DeleteEntity(peds)
                                end
                            end
                        end
                        if SV_PEDS[HWID].COUNT >= SecureServe.maxPed then
                            if not SV_Userver[HWID] then
                            clear()
                            punish_player(OWNER, "Try To Spam Peds: ".. SV_PEDS[HWID].COUNT, webhook, time)
                            CancelEvent()
                            SV_Userver[HWID] = true
                            end
                        end
                    end
                else
                    SV_PEDS[HWID] = {
                        COUNT = 1,
                        TIME  = os.time()
                    }
                    
                end
            elseif TYPE == 3 and POPULATION == 7 then
                HandleAntiSpamObjects(HWID, OWNER)
            end
        end
    end)

    local COOLDOWN_TIME = 10
    function HandleAntiSpamObjects(HWID, OWNER)
    
        if SV_OBJECT[HWID] ~= nil then
            SV_OBJECT[HWID].COUNT = SV_OBJECT[HWID].COUNT + 1
            if os.time() - SV_OBJECT[HWID].TIME >= COOLDOWN_TIME then
                SV_OBJECT[HWID] = nil
            else
                if SV_OBJECT[HWID].COUNT >= SecureServe.maxObject then
                    for _, objects in ipairs(GetAllObjects()) do
                        local ENO = NetworkGetFirstEntityOwner(objects)
                        if ENO == OWNER and DoesEntityExist(objects) then
                            DeleteEntity(objects)
                        end
                    end
                    if not SV_Userver[HWID] then
                        SV_Userver[HWID] = true
                        clear()
                        punish_player(OWNER, "Try To Spam Objects: ".. SV_OBJECT[HWID].COUNT, webhook, time)
                        CancelEvent()
                    end
                end
            end
        else
            SV_OBJECT[HWID] = {
                COUNT = 1,
                TIME = os.time()
            }
        end
    end
    ECount = {}
end)

RegisterNetEvent("serverwhitels", function (entity)
    TriggerClientEvent('addtowhitelist', -1, entity)
end)

initialize_protections_explosions = LPH_JIT_MAX(function()
    local whitelist = {}

    RegisterNetEvent("SecureServe:Explosions:Whitelist", function(data)
        if (data.source == nil) then return end
        whitelist[data.source] = true
    end)
    
    local explosions = {}
    local detected = {}
    local false_explosions = {
        [11] = true,
        [12] = true,
        [13] = true,
        [24] = true,
        [30] = true,
    }

    AddEventHandler('explosionEvent', function(sender, ev)
        explosions[sender] = explosions[sender] or {}
    
        local explosionType = ev.explosionType
        local explosionPos = ev.posX and ev.posY and ev.posZ and vector3(ev.posX, ev.posY, ev.posZ) or "Unknown"
        local explosionDamage = ev.damageScale or "Unknown"
        local explosionOwner = GetPlayerName(sender) or "Unknown"
    
        print(string.format("Explosion detected! Type: %s | Position: %s | Damage Scale: %s | Owner: %s", 
            explosionType, explosionPos, explosionDamage, explosionOwner))
        local resourceName = GetInvokingResource()
        if GetPlayerPing(sender) > 0  then
            if whitelist[sender] or SecureServe.ExplosionsWhitelist[resourceName] then
                whitelist[sender] = false
            else
                punish_player(sender, string.format("Explosion Details: Type: %s, Position: %s, Damage Scale: %s", 
                    explosionType, explosionPos, explosionDamage), webhook, time)
                    CancelEvent()
            end
        end
    
        for k, v in pairs(SecureServe.Protection.BlacklistedExplosions) do
            if ev.explosionType == v.id then
                local explosionInfo = string.format("Explosion Type: %d, Position: (%.2f, %.2f, %.2f)", ev.explosionType, ev.posX, ev.posY, ev.posZ)

                if v.limit and explosions[sender][v.id] and explosions[sender][v.id] >= v.limit then
                    punish_player(sender, "Exceeded explosion limit at explosion: " .. v.id .. ". " .. explosionInfo, v.webhook or SecureServe.Webhooks.BlacklistedExplosions or "https://discord.com/api/webhooks/1237077520210329672/PvyzM9Vr43oT3BbvBeLLeS-BQnCV4wSUQDhbKBAXr9g9JcjshPCzQ7DL1pG8sgjIqpK0", v.time)
                    CancelEvent()
                    return
                end

                explosions[sender][v.id] = (explosions[sender][v.id] or 0) + 1

                if v.limit and explosions[sender][v.id] > v.limit then
                    punish_player(sender, "Exceeded explosion limit at explosion: " .. v.id .. ". " .. explosionInfo, v.webhook or SecureServe.Webhooks.BlacklistedExplosions or "https://discord.com/api/webhooks/1237077520210329672/PvyzM9Vr43oT3BbvBeLLeS-BQnCV4wSUQDhbKBAXr9g9JcjshPCzQ7DL1pG8sgjIqpK0", v.time)
                    CancelEvent()
                    return
                end

                if v.limit then
                    if explosions[sender][v.id] > v.limit then
                        if false_explosions[ev.explosionType] then return end
                        if not detected[sender] then
                            detected[sender] = true
                            CancelEvent()
                            punish_player(sender, "Exceeded explosion limit at explosion: " .. v.id .. ". " .. explosionInfo, v.webhook or SecureServe.Webhooks.BlacklistedExplosions or "https://discord.com/api/webhooks/1237077520210329672/PvyzM9Vr43oT3BbvBeLLeS-BQnCV4wSUQDhbKBAXr9g9JcjshPCzQ7DL1pG8sgjIqpK0", v.time)
                        end
                    end
                end

                if v.audio and ev.isAudible == false then
                    punish_player(sender, "Used inaudible explosion. " .. explosionInfo, v.webhook or SecureServe.Webhooks.BlacklistedExplosions or "https://discord.com/api/webhooks/1237077520210329672/PvyzM9Vr43oT3BbvBeLLeS-BQnCV4wSUQDhbKBAXr9g9JcjshPCzQ7DL1pG8sgjIqpK0", v.time)
                    CancelEvent()
                    return
                end

                if v.invisible and ev.isInvisible == true then
                    punish_player(sender, "Used invisible explosion. " .. explosionInfo, v.webhook or SecureServe.Webhooks.BlacklistedExplosions or "https://discord.com/api/webhooks/1237077520210329672/PvyzM9Vr43oT3BbvBeLLeS-BQnCV4wSUQDhbKBAXr9g9JcjshPCzQ7DL1pG8sgjIqpK0", v.time)
                    CancelEvent()
                    return
                end

                if v.damageScale and ev.damageScale > 1.0 then
                    punish_player(sender, "Used boosted explosion. " .. explosionInfo, v.webhook or SecureServe.Webhooks.BlacklistedExplosions or "https://discord.com/api/webhooks/1237077520210329672/PvyzM9Vr43oT3BbvBeLLeS-BQnCV4wSUQDhbKBAXr9g9JcjshPCzQ7DL1pG8sgjIqpK0", v.time)
                    return
                end

                if SecureServe.Protection.CancelOtherExplosions then
                    for k, v in pairs(SecureServe.Protection.BlacklistedExplosions) do
                        if ev.explosionType ~= v.id then
                            CancelEvent()
                        end
                    end
                end
            end
        end

        if ev.ownerNetId == 0 then
            CancelEvent()
        end
    end)

end)

AddEventHandler('entityCreating', function(entity)
    local model
    local owner
    local entityType

    if not DoesEntityExist(entity) then
        CancelEvent()
        return
    end

    if DoesEntityExist(entity) then
        model = GetEntityModel(entity)
        entityType = GetEntityType(entity)
        owner = NetworkGetEntityOwner(entity)
    end
    if entityType == 3 then
        for _, player in pairs(GetPlayers()) do
            local playerPed = GetPlayerPed(player)
            local playerCoords = GetEntityCoords(playerPed)
            local entityCoords = GetEntityCoords(entity)
            local distance = #(playerCoords - entityCoords)

            if distance < 5 then
                CancelEvent()
            end
        end
    end
end)

local playerHeartbeats = {}

local function onPlayerDisconnected()
    local playerId = source
    playerHeartbeats[playerId] = nil
end
AddEventHandler("playerDropped", onPlayerDisconnected)

RegisterNetEvent("mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS", function(key)
    local playerId = source
    if string.len(key) < 15 or string.len(key) > 35 or key == nil then
        punish_player(playerId, "Tried to stop the anticheat", webhook, -1)
    else
        playerHeartbeats[playerId] = os.time()
    end
end)

Citizen.CreateThread(LPH_JIT_MAX(function()
    while true do
        Citizen.Wait(10 * 1000)
        for playerId, lastHeartbeatTime in pairs(playerHeartbeats) do
            if lastHeartbeatTime == nil then return end
            local currentTime = os.time()
            local timeSinceLastHeartbeat = currentTime - lastHeartbeatTime
            if timeSinceLastHeartbeat > 15 * 1000 then
                BetterPrint(
                    ("Player [%s] %s didn't sent any heartbeat to the server in required time. Last response: %s seconds ago")
                    :format(playerId, GetPlayerName(playerId), timeSinceLastHeartbeat), "info")
                punish_player(playerId, "Tried to stop the anticheat", webhook, -1)
                playerHeartbeats[playerId] = nil
            end
        end
    end
end))

initialize_server_protections_play_sound = function()
    if (Anti_Play_Sound_enabled) then
        if (GetConvar("sv_enableNetworkedSounds", "true") == "false") then return end
        SetConvar("sv_enableNetworkedSounds", "false")
    end
end

initialize_protections_ptfx = LPH_JIT_MAX(function()
    local particlesSpawned = {}
    AddEventHandler('ptFxEvent', function(sender, data)
        if (Anti_Particles_enabled) then
            particlesSpawned[sender] = (particlesSpawned[sender] or 0) + 1
            if (particlesSpawned[sender] > Anti_Particles_limit) then
                CancelEvent()
                punish_player(sender, "Anti Particle Spam", webhook, time)                
                return
            end
            if (data.effectHash == 2341015072) then
                CancelEvent()
                punish_player(sender, "Anti Fire Player", webhook, time)                
            end
            CancelEvent()
        end
    end)
end)


initialize_server_protections_anti_resource = LPH_JIT_MAX(function()
    local stoppedResources = {}
    local startedResources = {}
    local restarted = {}
    local restarteda = false
    AddEventHandler('onResourceStart', function(resourceName)
        stoppedResources[resourceName] = nil
        startedResources[resourceName] = true
    end)

    AddEventHandler('onResourceStop', function(resourceName)
        stoppedResources[resourceName] = true
        startedResources[resourceName] = nil
    end)
    
    RegisterServerCallback {
        eventName = 'SecureServe:Server_Callbacks:Protections:GetResourceStatus',
        eventCallback = function(source, resourceName)
            Wait(1000)
            if stoppedResources[resourceName] == startedResources[resourceName] then
                restarteda = true
            else
                restarteda = false
            end
            return stoppedResources[resourceName], startedResources[resourceName], restarteda
        end
    }
end)


AddEventHandler('entityCreating', function(entity)
    local model
    local owner
    local entityType
  
    if not DoesEntityExist(entity) then
      CancelEvent()
      return
    end
  
    if DoesEntityExist(entity) then
      model = GetEntityModel(entity)
      entityType = GetEntityType(entity)
      owner = NetworkGetEntityOwner(entity)
    end
    if entityType == 2 and DoesEntityExist(entity) then
        local src = NetworkGetEntityOwner(entity)
        local entityPopulationType = GetEntityPopulationType(entity)
    
        if src == nil or owner == nil then
          CancelEvent()
        end

        for k, v in pairs(SecureServe.Protection.BlacklistedVehicles) do
            if model == GetHashKey(v.name) then
                    punish_player(source, "Blacklisted Vehicle (" .. v.name .. ")", webhook, time)
            CancelEvent()
            end
        end
    end
end)  


local playerProximitySpawns = {}
local proximityThreshold = 10.0 
local timeWindow = 60000 
local maxProximitySpawns = 15 
local cooldownPeriod = 1000 

local function initializePlayerData(playerId)
    playerProximitySpawns[playerId] = {
        spawns = {},
        lastSpawnTime = 0
    }
end

local function isEntityNearAnyPlayer(entity)
    local entityCoords = GetEntityCoords(entity)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - entityCoords)
        if distance <= proximityThreshold then
            return true, playerId
        end
    end
    return false, nil
end

local function updateProximitySpawns(playerId, currentTime)
    local playerData = playerProximitySpawns[playerId]
    
    for i = #playerData.spawns, 1, -1 do
        if currentTime - playerData.spawns[i] > timeWindow then
            table.remove(playerData.spawns, i)
        else
            break 
        end
    end
    
    table.insert(playerData.spawns, currentTime)
    
    return #playerData.spawns
end

AddEventHandler('entityCreating', function(entity)
    local ownerPlayerId = NetworkGetEntityOwner(entity)
    local isNearPlayer, nearestPlayerId = isEntityNearAnyPlayer(entity)
    
    if isNearPlayer then
        if not playerProximitySpawns[ownerPlayerId] then
            initializePlayerData(ownerPlayerId)
        end

        local playerData = playerProximitySpawns[ownerPlayerId]
        local currentTime = GetGameTimer()

        if currentTime - playerData.lastSpawnTime < cooldownPeriod then
            CancelEvent()
            print(ownerPlayerId, "Entity spawning too quickly near players", 'this is a beta funciton please update us if its not working corretely')
            return
        end

        local proximitySpawnCount = updateProximitySpawns(ownerPlayerId, currentTime)

        if proximitySpawnCount > maxProximitySpawns then
            CancelEvent()
            print(ownerPlayerId, "Excessive entity spawning near players detected: " .. proximitySpawnCount .. " spawns in " .. timeWindow/1000 .. " seconds", 'this is a beta funciton please update us if its not working corretely')
            return
        end

        playerData.lastSpawnTime = currentTime

        if proximitySpawnCount == maxProximitySpawns - 3 then
            print(ownerPlayerId, "You are approaching the entity spawn limit near players", 'this is a beta funciton please update us if its not working corretely')
        end

        if nearestPlayerId ~= ownerPlayerId then
            print(nearestPlayerId, "An entity was spawned near you by another player", 'this is a beta funciton please update us if its not working corretely')
        end
    end
end)

AddEventHandler('playerDropped', function()
    local playerId = source
    playerProximitySpawns[playerId] = nil
end)

--> [Init] <--

local timeout = 0
local ac_name = GetCurrentResourceName()
local user_data = {
    DiscordID = "N/A",
    expire = "N/A",
    date = "N/A",
    is_expired = true
}

RegisterServerCallback {
    eventName = 'SecureServe:Server_Callbacks:Protections:GetConfig',
    eventCallback = function(source)
        return SecureServe
    end
}

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    print(
[[^5
≺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━≻                                                                                                                                                                                                                                                   
                                                                                                  
  ____                                                 ____                                       
 6MMMMb\                                              6MMMMb\                                     
6M'    `                                             6M'    `                                     
MM         ____     ____  ___   ___ ___  __   ____   MM         ____  ___  __ ____    ___  ____   
YM.       6MMMMb   6MMMMb.`MM    MM `MM 6MM  6MMMMb  YM.       6MMMMb `MM 6MM `MM(    )M' 6MMMMb  
 YMMMMb  6M'  `Mb 6M'   Mb MM    MM  MM69 " 6M'  `Mb  YMMMMb  6M'  `Mb MM69 "  `Mb    d' 6M'  `Mb 
     `Mb MM    MM MM    `' MM    MM  MM'    MM    MM      `Mb MM    MM MM'      YM.  ,P  MM    MM 
      MM MMMMMMMM MM       MM    MM  MM     MMMMMMMM       MM MMMMMMMM MM        MM  M   MMMMMMMM 
      MM MM       MM       MM    MM  MM     MM             MM MM       MM        `Mbd'   MM       
L    ,M9 YM    d9 YM.   d9 YM.   MM  MM     YM    d9 L    ,M9 YM    d9 MM         YMP    YM    d9 
MYMMMM9   YMMMM9   YMMMM9   YMMM9MM__MM_     YMMMM9  MYMMMM9   YMMMM9 _MM_         M      YMMMM9  
                                                                                                  
                                                                                                                                                                                                                                     														
≺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━≻                                                                                                                                                                                                       
^0]])
    
    sm_print("Light Blue", "Authenticating with server...")

        
        Citizen.Wait(1000)


    SetConvar("Anti Cheat", "SecureServe-ac.com")
    SetConvarServerInfo("Anti Cheat", "SecureServe-ac.com")
    SetConvarReplicated("Anti Cheat", "SecureServe-ac.com")

    sm_print("Light Green", "I'm here dont worry im working!")

    --> [Modules] <--
    initialize_misc_module()

    --> [Protections] <--
    initialize_server_protections_anti_resource()
    initialize_server_protections_play_sound()
    initialize_protections_explosions()
    initialize_protections_entity_spam()
    initialize_protections_damage()
    initialize_protections_entity_lockdown()
    initialize_protections_ptfx()
    
end)

local function replaceEventRegistrations(filePath)
    local file = io.open(filePath, "r")
    if not file then
        -- print("Could not open file: " .. filePath)
        return
    end

    local content = file:read("*all")
    file:close()

    local netEventPattern = "RegisterNetEvent%s*%('([^']+)'%s*%)%s*AddEventHandler%s*%('%1'%s*,%s*function%(([^)]*)%)"
    content = content:gsub(netEventPattern, "RegisterNetEvent('%1', function(%2)")

    local serverEventPattern = "RegisterServerEvent%s*%('([^']+)'%s*%)%s*AddEventHandler%s*%('%1'%s*,%s*function%(([^)]*)%)"
    content = content:gsub(serverEventPattern, "RegisterNetEvent('%1', function(%2)")

    local outputFile = io.open(filePath, "w")
    if not outputFile then
        -- print("Could not open file for writing: " .. filePath)
        return
    end

    outputFile:write(content)
    outputFile:close()
    -- print("Updated file: " .. filePath)
end

local function fileContainsLine(filePath, lineToFind)
    local file = io.open(filePath, "r")
    if not file then
        -- print("Could not open file: " .. filePath)
        return false
    end

    for line in file:lines() do
        if line:match(lineToFind) then
            file:close()
            return true
        end
    end

    file:close()
    return false
end


local function searchInDirectory(directory, resourceName)
    local findCommand
    if os.getenv("OS") == "Windows_NT" then
        findCommand = 'dir /s /b "' .. directory .. '\\*.lua"'
    else
        findCommand = 'find "' .. directory .. '" -type f -name "*.lua"'
    end

    local p = io.popen(findCommand)
    if not p then
        print("Could not open directory: " .. directory)
        return
    end


    
    for file in p:lines() do
        replaceEventRegistrations(file)
        -- if fileContainsLine(file, "CreateObject") or fileContainsLine(file, "CreateVehicle") or
        --    fileContainsLine(file, "CreatePed") or fileContainsLine(file, "CreatePedInsideVehicle") or
        --    fileContainsLine(file, "CreateRandomPed") or fileContainsLine(file, "CreateRandomPedAsDriver") then
        --     -- print("Whitelisted resource with entity creation: " .. resourceName)
        --     table.insert(SecureServe.EntitySecurity, {resource = resourceName, whitelist = true})
        -- end
    end

    p:close()
end

function SearchForAssetPackDependency()
    SecureServe.EntitySecurity = SecureServe.EntitySecurity or {}

    local resources = GetNumResources()
    for i = 0, resources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        local resourcePath = GetResourcePath(resourceName)
        if not resourcePath then
            -- print("Could not find resource path for: " .. resourceName)
            goto continue
        end

        local fxManifestPath = resourcePath .. "/fxmanifest.lua"
        local resourceLuaPath = resourcePath .. "/__resource.lua"

        if fileContainsLine(fxManifestPath, "dependency '/assetpacks'") or fileContainsLine(resourceLuaPath, "dependency '/assetpacks'") then
            -- print("Whitelisted encrypted resource: " .. resourceName)
            -- table.insert(SecureServe.EntitySecurity, {resource = resourceName, whitelist = true})
        else
            searchInDirectory(resourcePath, resourceName)
        end


        ::continue::
    end
end

SearchForAssetPackDependency()


exports('isResourceWhitelistedServer', function(resourceName)
    for _, resource in ipairs(SecureServe.EntitySecurity) do
        if resource.resource == resourceName and resource.whitelist then
            return true
        end
    end
    return false
end)


AddEventHandler('weaponDamageEvent', function(sender, data)
    local getWeapon = data.weaponType
    if getWeapon == `WEAPON_STUNGUN` then
        TriggerClientEvent('SecureServe:checkTaze', sender)
    end
end)


    
local scriptCreatedEntities = {}
RegisterNetEvent('entityCreatedByScript', function(entity, resource, can, hash)
    local player = source
    local hashNumber = tonumber(hash)
    if scriptCreatedEntities[hashNumber] == nil then
        scriptCreatedEntities[hashNumber] = {}
    end
    scriptCreatedEntities[hashNumber][source] = true
    Wait(1500)
    if scriptCreatedEntities[hashNumber] == nil then
        scriptCreatedEntities[hashNumber] = {}
        scriptCreatedEntities[tonumber(hash)][source] = false
    else
        scriptCreatedEntities[tonumber(hash)][player] = false
    end
end)

local function logEntityInfo(entity, eventName)
    -- if DoesEntityExist(entity) then
    --     local entityModel = GetEntityModel(entity) or "Unknown"
    --     local entityCoords = GetEntityCoords(entity) or vector3(0, 0, 0)
    --     local entityOwner = NetworkGetEntityOwner(entity) or "Unknown"
    --     local entityType = GetEntityType(entity) or "Unknown"
    --     local entityHealth = GetEntityHealth(entity) or -1
    --     local entityMaxHealth = GetEntityMaxHealth(entity) or -1
    --     local entityScript = GetEntityScript(entity) or "Unknown"
    --     local entityPopulationType = GetEntityPopulationType(entity)
    --     if entityPopulationType == 0 then
    --         if not tonumber(entityOwner) and tonumber(entityOwner) ~= 0 then return end
    --         Wait(1050)
    --         if DoesEntityExist(entity) then
    --             if not scriptCreatedEntities[tonumber(entityModel)][source] then 
    --                 if not shouldPunishPlayer(entityOwner) then return end
    --                 DeleteEntity(entity)
    --                 local message = string.format(
    --                     "have been removed from the server for creating a suspicious entity.\n\nDetails:\n- Entity Model: %s\n- Entity Type: %s\n- Entity Coordinates: %s\n- Health: %d/%d\n- Script: %s",
    --                     entityModel, entityType, entityCoords, entityHealth, entityMaxHealth, entityScript
    --                 )
    --                 punish_player(entityOwner, message, webhook, time)   
    --             end            
    --         end
    --     end
    -- else
    --     print(string.format("[%s] Entity does not exist or was deleted: %d", eventName, entity))
    -- end
end

function shouldPunishPlayer(playerId)
    local playerState = playerStates[playerId]
    if playerState and playerState.loaded then
        local elapsedTime = GetGameTimer() - playerState.loadTime
        return elapsedTime > 30000 
    end
    return true
end

AddEventHandler('entityCreating', function(entity)
    local src = NetworkGetEntityOwner(entity)
    logEntityInfo(entity, "entityCreating")
end)

AddEventHandler('entityCreated', function(entity)
    local src = NetworkGetEntityOwner(entity)
    logEntityInfo(entity, "entityCreated")
end)





local function sendToDiscord(webhook, title, description, color, fields)
    if not webhook or webhook == "" or webhook == "YOUR_WEBHOOK_URL"  then
        print("[SecureServe] Error: Invalid webhook URL.")
        return
    end

    local payload = {
        username = "Server Logs",
        embeds = {{
            title = title,
            description = description,
            color = color,
            fields = fields,
            footer = {
                ["text"] = "SecureServe | Secure Your Server Now",
                ["icon_url"] = "https://images-ext-1.discordapp.net/external/ATCidz-Uio1fj26KQZH1mmy20YnxQxQxv-sc0gBFGFw/%3Fformat%3Dwebp%26quality%3Dlossless/https/images-ext-1.discordapp.net/external/z9bSkH3p8iTlOClfnK7zVOEC9i5xcORJZfsuqlcf1XA/https/cdn.discordapp.com/icons/814390233898156063/c959fc0889d2436b87ccbf2f73d4f30e.png?format=webp&quality=lossless"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
end

local function getPlayerIdentifiersInfo(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local steamId = "Unknown"
    local discordId = "Unknown"
    local license = "Unknown"
    local xbox = "Unknown"
    local live = "Unknown"
    local hwid = "Unknown"

    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "steam:") then
            steamId = identifier
        elseif string.find(identifier, "discord:") then
            discordId = "<@" .. string.gsub(identifier, "discord:", "") .. ">" 
        elseif string.find(identifier, "license:") then
            license = identifier
        elseif string.find(identifier, "xbl:") then
            xbox = identifier
        elseif string.find(identifier, "live:") then
            live = identifier
        elseif string.find(identifier, "hwid:") then
            hwid = identifier
        end
    end

    return steamId, discordId, license, xbox, live, hwid
end

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local playerId = source
    local steamId, discordId, license, xbox, live, hwid = getPlayerIdentifiersInfo(playerId)

    sendToDiscord(SecureServe.OtherLogs.JoinWebhook, "Player Connected",
        "**A new player has connected to the server!**",
        3066993, {
            {name = "Player Name", value = playerName, inline = true},
            {name = "Steam ID", value = steamId, inline = false},
            {name = "Discord ID", value = discordId, inline = false},
            {name = "License", value = license, inline = false},
            {name = "Xbox ID", value = xbox, inline = false},
            {name = "Live ID", value = live, inline = false},
            {name = "HWID", value = hwid, inline = false}
        })
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local playerName = GetPlayerName(playerId)
    local steamId, discordId, license, xbox, live, hwid = getPlayerIdentifiersInfo(playerId)

    sendToDiscord(SecureServe.OtherLogs.LeaveWebhook, "Player Disconnected",
        "**A player has left the server.**",
        15158332, {
            {name = "Player Name", value = playerName, inline = true},
            {name = "Reason", value = reason, inline = false},
            {name = "Steam ID", value = steamId, inline = false},
            {name = "Discord ID", value = discordId, inline = false},
            {name = "License", value = license, inline = false},
            {name = "Xbox ID", value = xbox, inline = false},
            {name = "Live ID", value = live, inline = false},
            {name = "HWID", value = hwid, inline = false}
        })
end)

AddEventHandler('onResourceStart', function(resourceName)
    local message = "**A resource has been started on the server.**"
    sendToDiscord(SecureServe.OtherLogs.ResourceWebhook, "Resource Started", message, 65280, {
        {name = "Resource Name", value = resourceName, inline = true},
        {name = "Timestamp", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false}
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    local message = "**A resource has been stopped on the server.**"
    sendToDiscord(SecureServe.OtherLogs.ResourceWebhook, "Resource Stopped", message, 16711680, {
        {name = "Resource Name", value = resourceName, inline = true},
        {name = "Timestamp", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false}
    })
end)
