-- if GetCurrentResourceName() == "SecureServe" then
--     return
-- end
local encryption_key = ""


---@return string The encryption key from secureserve.key file
local function getEncryptionKey()
    local keyFile = LoadResourceFile("SecureServe", "secureserve.key")
    if not keyFile or keyFile == "" then
        print("^3[WARNING] Failed to load SecureServe encryption key. Using temporary key.^7")
        return "temp_key_" .. GetCurrentResourceName()
    end

    return keyFile:gsub("%s+", "")
end

encryption_key = getEncryptionKey()

---@param input string|number The input string or number to encrypt
---@return string The encrypted string
function encryptDecrypt(input)
    local output = {}
    for i = 1, #tostring(input) do
        local char = tostring(input):byte(i)
        local keyChar = encryption_key:byte((i - 1) % #encryption_key + 1)
        local encryptedChar = (char + keyChar) % 256  
        output[i] = string.char(encryptedChar)
    end
    return table.concat(output)
end

---@param input string The encrypted string to decrypt
---@return string The decrypted string
function decrypt(input)
    local output = {}
    for i = 1, #tostring(input) do
        local char = tostring(input):byte(i)
        local keyChar = encryption_key:byte((i - 1) % #encryption_key + 1)
        local decryptedChar = (char - keyChar) % 256  
        output[i] = string.char(decryptedChar)
    end
    return table.concat(output)
end

---@param originalFunction function The original entity creation function
---@return function The wrapped entity creation function
local function createEntity(originalFunction, ...)
    local entity = originalFunction(...)
    
    if not IsDuplicityVersion() then
        while not DoesEntityExist(entity) do
            Wait(1) 
        end
        TriggerServerEvent("SecureServe:Server:Methods:Entity:Create", entity, GetCurrentResourceName(), GetEntityModel(entity))
    else
        Citizen.CreateThread(function()
            while not DoesEntityExist(entity) do
                Wait(1) 
            end
            TriggerEvent("SecureServe:Server:Methods:Entity:CreateServer", entity, GetCurrentResourceName(), GetEntityModel(entity))
        end)
    end
 
    return entity
end

local _CreateObject = CreateObject
local _CreateObjectNoOffset = CreateObjectNoOffset
local _CreateVehicle = CreateVehicle
local _CreatePed = CreatePed
local _CreatePedInsideVehicle = CreatePedInsideVehicle
local _CreateRandomPed = CreateRandomPed
local _CreateRandomPedAsDriver = CreateRandomPedAsDriver
local _CreateScriptVehicleGenerator = CreateScriptVehicleGenerator
local _CreateVehicleServerSetter = CreateVehicleServerSetter
local _CreateAutomobile = CreateAutomobile 

_G.CreateObject = function(...) return createEntity(_CreateObject, ...) end
_G.CreateObjectNoOffset = function(...) return createEntity(_CreateObjectNoOffset, ...) end
_G.CreateVehicle = function(...) return createEntity(_CreateVehicle, ...) end
_G.CreatePed = function(...) return createEntity(_CreatePed, ...) end
_G.CreatePedInsideVehicle = function(...) return createEntity(_CreatePedInsideVehicle, ...) end
_G.CreateRandomPed = function(...) return createEntity(_CreateRandomPed, ...) end
_G.CreateRandomPedAsDriver = function(...) return createEntity(_CreateRandomPedAsDriver, ...) end
_G.CreateScriptVehicleGenerator = function(...) return createEntity(_CreateScriptVehicleGenerator, ...) end
_G.CreateVehicleServerSetter = function(...) return createEntity(_CreateVehicleServerSetter, ...) end
_G.CreateAutomobile = function(...) return createEntity(_CreateAutomobile, ...) end

if IsDuplicityVersion() then
    local _AddEventHandler = AddEventHandler
    local _RegisterNetEvent = RegisterNetEvent
    local events_to_listen = {}
    
    _G.RegisterNetEvent = function(event_name, ...)
        local enc_event_name = encryptDecrypt(event_name) 
        events_to_listen[event_name] = enc_event_name 

        _RegisterNetEvent(enc_event_name)
        return _RegisterNetEvent(event_name, ...)
    end
    
    _G.AddEventHandler = function(event_name, handler, ...)
        local enc_event_name = events_to_listen[event_name] 
        local handler_ref = _AddEventHandler(event_name, handler, ...) 
    
        if enc_event_name then
            _AddEventHandler(enc_event_name, handler, ...)
        end
    
        return handler_ref  
    end
    
    Citizen.CreateThread(function()
        for event_name, _ in pairs(events_to_listen) do
            local enc_event_name = encryptDecrypt(event_name)
            if event_name ~= "check_trigger_list" then
                _AddEventHandler(event_name, function ()
                    local src = source
                    if GetPlayerPing(src) > 0  then
                        local resourceName = GetCurrentResourceName()
                        local banMessage = ("Tried triggering a restricted event: %s in resource: %s."):format(event_name, resourceName)
                        exports["SecureServe"]:module_punish(src, banMessage)
                    end
                end)
        
                _AddEventHandler(enc_event_name, function ()
                    local src = source 
                    
                    if GetPlayerPing(src) > 0 and decrypt(enc_event_name) ~= "add_to_trigger_list" and decrypt(enc_event_name) ~= "check_trigger_list" then
                        -- TriggerEvent(encryptDecrypt("check_trigger_list"), src, decrypt(enc_event_name), GetCurrentResourceName())
                    end
                end)
            end
        end
    end)

    RegisterServerEvent = RegisterNetEvent
else
    local _TriggerServerEvent = TriggerServerEvent
    
    _G.TriggerServerEvent = function(eventName, ...)
        local encryptedEvent = encryptDecrypt(eventName)
        return _TriggerServerEvent(encryptedEvent, ...)
    end

    ---@param resourceName string The name of the resource to check
    ---@return boolean Whether the resource is valid
    local function isValidResource(resourceName)
        local invalidResources = {
            nil, 
            "fivem", 
            "gta", 
            "citizen", 
            "system"
        }
    
        for _, invalid in ipairs(invalidResources) do
            if resourceName == invalid then
                return false
            end
        end
    
        return true
    end
    
    ---@param originalFunction function The original explosion function
    ---@return function The wrapped explosion function
    local handleExplosionEvent = function(originalFunction, ...)
        local resourceName = GetCurrentResourceName()
        if isValidResource(resourceName) then
            TriggerServerEvent("SecureServe:Explosions:Whitelist", {
                source = GetPlayerServerId(PlayerId()),
                resource = resourceName
            })
        end
        return originalFunction(...)
    end
    
    local _AddExplosion = AddExplosion
    local _AddExplosionWithUserVfx = AddExplosionWithUserVfx
    local _ExplodeVehicle = ExplodeVehicle
    local _NetworkExplodeVehicle = NetworkExplodeVehicle
    local _ShootSingleBulletBetweenCoords = ShootSingleBulletBetweenCoords
    local _AddOwnedExplosion = AddOwnedExplosion
    local _StartScriptFire = StartScriptFire
    local _RemoveScriptFire = RemoveScriptFire
    
    _G.AddExplosion = function(...) return handleExplosionEvent(_AddExplosion, ...) end
    _G.AddExplosionWithUserVfx = function(...) return handleExplosionEvent(_AddExplosionWithUserVfx, ...) end
    _G.ExplodeVehicle = function(...) return handleExplosionEvent(_ExplodeVehicle, ...) end
    _G.NetworkExplodeVehicle = function(...) return handleExplosionEvent(_NetworkExplodeVehicle, ...) end
    _G.ShootSingleBulletBetweenCoords = function(...) return handleExplosionEvent(_ShootSingleBulletBetweenCoords, ...) end
    _G.AddOwnedExplosion = function(...) return handleExplosionEvent(_AddOwnedExplosion, ...) end
    _G.StartScriptFire = function(...) return handleExplosionEvent(_StartScriptFire, ...) end
    _G.RemoveScriptFire = function(...) return handleExplosionEvent(_RemoveScriptFire, ...) end 
    


    local function handleWeaponEvent(originalFunction, weaponArgIndex, ...)
        local args = { ... }
        local weaponHash = nil

        if weaponArgIndex and args[weaponArgIndex] then
            local weaponArg = args[weaponArgIndex]
            weaponHash = type(weaponArg) == "string" and GetHashKey(weaponArg) or weaponArg
        end

        local resourceName = GetCurrentResourceName()
        if isValidResource(resourceName) then
            TriggerEvent("SecureServe:Weapons:Whitelist", {
                weapon = weaponHash,
                source = GetPlayerServerId(PlayerId()),
                resource = resourceName
            })
        end

        return originalFunction(table.unpack(args))
    end

    local weaponNatives = {
        { name = "GiveWeaponToPed",              argIndex = 2 },
        { name = "RemoveWeaponFromPed",          argIndex = 2 },
        { name = "RemoveAllPedWeapons",          argIndex = nil }, 
        { name = "SetCurrentPedWeapon",          argIndex = 2 },
    }

    for _, native in ipairs(weaponNatives) do
        local originalFunction = _G[native.name]
        if originalFunction then
            _G[native.name] = function(...)
                return handleWeaponEvent(originalFunction, native.argIndex, ...)
            end
        end
    end
end
