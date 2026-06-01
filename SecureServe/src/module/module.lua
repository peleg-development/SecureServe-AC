-- ATENCION: esta capa es ofuscacion, NO seguridad. La defensa real esta en
-- las validaciones server-side (anti_execution, ban_manager, etc).
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

if not IsDuplicityVersion() then
     TriggerEvent("SecureServe:Client:LoadedKey", GetCurrentResourceName())
end

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

if not _G.__SecureServe_EntityWrapsApplied then
    _G.__SecureServe_EntityWrapsApplied = true

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
end

if IsDuplicityVersion() then
    -- Double-application guard. module.lua loads in EVERY resource (via the
    -- shared_script injected by install.js). If a resource restarts hot, the
    -- file re-runs and would wrap an already-wrapped RegisterNetEvent, which
    -- causes the encryption to be applied twice and breaks every event.
    if not _G.__SecureServe_EventWrapsApplied then
        _G.__SecureServe_EventWrapsApplied = true

    local _AddEventHandler = AddEventHandler
    local _RegisterNetEvent = RegisterNetEvent
    local events_to_listen = {}

    -- The server-side wrap registers BOTH the plain and the encrypted alias
    -- so that clients running module.lua (whose TriggerServerEvent encrypts
    -- the event name) reach a handler.
    --
    -- How the handler ends up attached to BOTH aliases automatically:
    --
    --   1. RegisterNetEvent(name, cb) -> we record `events_to_listen[name]=enc`
    --      and call `_RegisterNetEvent(enc)` to allow the encrypted alias
    --      inbound, then `_RegisterNetEvent(name, cb)` for the plain alias.
    --   2. The internal modern-signature path of _RegisterNetEvent(name, cb)
    --      calls `AddEventHandler(name, cb)` — and `_G.AddEventHandler` is
    --      our wrap. Our wrap sees that `events_to_listen[name]` already
    --      points to `enc`, so it attaches the handler to BOTH plain and
    --      encrypted aliases on its own.
    --
    -- Lesson from a previous bad fix: do NOT add the handler manually to the
    -- encrypted alias here. The wrap of AddEventHandler already handles it,
    -- and doing it manually causes the handler to be attached twice to the
    -- encrypted alias, which makes every incoming encrypted event run the
    -- handler twice (e.g. canary tick counter is consumed twice -> replay
    -- ban).
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

    RegisterServerEvent = RegisterNetEvent
    end -- /__SecureServe_EventWrapsApplied
else
    -- Client side: wrap TriggerServerEvent to encrypt outbound event names so
    -- that the server (which now has handlers on both plain and encrypted
    -- aliases) routes them correctly.
    --
    -- Same double-application guard as on the server: this file may re-execute
    -- on hot restart and we must not stack the encryption.
    if not _G.__SecureServe_ClientEventWrapsApplied then
        _G.__SecureServe_ClientEventWrapsApplied = true

    local _TriggerServerEvent = TriggerServerEvent

    _G.TriggerServerEvent = function(eventName, ...)
        local encryptedEvent = encryptDecrypt(eventName)
        return _TriggerServerEvent(encryptedEvent, ...)
    end

    end -- /__SecureServe_ClientEventWrapsApplied

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
