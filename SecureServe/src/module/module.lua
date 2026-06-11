local RESOURCE_NAME = GetCurrentResourceName()
local KEY_RESOURCE = "SecureServe"
local KEY_FILE = "secureserve.key"
local ENTITY_WAIT_TIMEOUT = 5000
local TOKEN_PREFIX = "SecureServe:EventToken:"
local TOKEN_FIELD = "__secureServeEventToken"

local encryptionKey = ""

local fxEvents = {
    ["onResourceStart"] = true,
    ["onResourceStarting"] = true,
    ["onResourceStop"] = true,
    ["onServerResourceStart"] = true,
    ["onServerResourceStop"] = true,
    ["gameEventTriggered"] = true,
    ["populationPedCreating"] = true,
    ["rconCommand"] = true,
    ["__cfx_internal:commandFallback"] = true,
    ["playerConnecting"] = true,
    ["playerDropped"] = true,
    ["onResourceListRefresh"] = true,
    ["weaponDamageEvent"] = true,
    ["vehicleComponentControlEvent"] = true,
    ["respawnPlayerPedEvent"] = true,
    ["explosionEvent"] = true,
    ["fireEvent"] = true,
    ["entityRemoved"] = true,
    ["playerJoining"] = true,
    ["startProjectileEvent"] = true,
    ["playerEnteredScope"] = true,
    ["playerLeftScope"] = true,
    ["ptFxEvent"] = true,
    ["removeAllWeaponsEvent"] = true,
    ["giveWeaponEvent"] = true,
    ["removeWeaponEvent"] = true,
    ["clearPedTasksEvent"] = true,
}

local function loadEncryptionKey()
    local keyFile = LoadResourceFile(KEY_RESOURCE, KEY_FILE)
    if not keyFile or keyFile == "" then
        print("^3[WARNING] Failed to load SecureServe encryption key. Using temporary key.^7")
        return "temp_key_" .. RESOURCE_NAME
    end

    local key = keyFile:gsub("%s+", "")
    if key == "" then return "temp_key_" .. RESOURCE_NAME end
    return key
end

local function transform(input, direction)
    local text = tostring(input or "")
    local output = {}
    local keyLength = #encryptionKey

    if keyLength == 0 then return text end

    for i = 1, #text do
        local char = text:byte(i)
        local keyChar = encryptionKey:byte((i - 1) % keyLength + 1)
        output[i] = string.char((char + (keyChar * direction)) % 256)
    end

    return table.concat(output)
end

function encryptDecrypt(input)
    return transform(input, 1)
end

function decrypt(input)
    return transform(input, -1)
end

local function waitForEntity(entity)
    local function now()
        if GetGameTimer then return GetGameTimer() end
        return math.floor(os.clock() * 1000)
    end

    local startedAt = now()

    while entity and entity ~= 0 and not DoesEntityExist(entity) do
        Wait(1)
        if (now() - startedAt) > ENTITY_WAIT_TIMEOUT then
            return false
        end
    end

    return entity and entity ~= 0 and DoesEntityExist(entity)
end

local function reportCreatedEntity(entity)
    if not waitForEntity(entity) then return end

    local model = GetEntityModel(entity)
    if not IsDuplicityVersion() then
        TriggerServerEvent("SecureServe:Server:Methods:Entity:Create", entity, RESOURCE_NAME, model)
    else
        TriggerEvent("SecureServe:Server:Methods:Entity:CreateServer", entity, RESOURCE_NAME, model)
    end
end

local function createEntity(originalFunction, ...)
    local entity = originalFunction(...)

    if IsDuplicityVersion() then
        Citizen.CreateThread(function()
            reportCreatedEntity(entity)
        end)
    else
        reportCreatedEntity(entity)
    end

    return entity
end

local function wrapEntityNative(name)
    local originalFunction = _G[name]
    if type(originalFunction) ~= "function" then return end

    _G[name] = function(...)
        return createEntity(originalFunction, ...)
    end
end

local function isValidResource(resourceName)
    if type(resourceName) ~= "string" or resourceName == "" then return false end

    local invalidResources = {
        fivem = true,
        gta = true,
        citizen = true,
        system = true,
    }

    return invalidResources[resourceName:lower()] ~= true
end

local function getWeaponHash(args, weaponArgIndex)
    if not weaponArgIndex or not args[weaponArgIndex] then return nil end

    local weaponArg = args[weaponArgIndex]
    if type(weaponArg) == "string" then
        return GetHashKey(weaponArg)
    end

    return weaponArg
end

local function wrapWeaponNative(native)
    local originalFunction = _G[native.name]
    if type(originalFunction) ~= "function" then return end

    _G[native.name] = function(...)
        local args = { ... }
        local resourceName = GetCurrentResourceName()

        if isValidResource(resourceName) then
            TriggerEvent("SecureServe:Weapons:Whitelist", {
                weapon = getWeaponHash(args, native.argIndex),
                source = GetPlayerServerId(PlayerId()),
                resource = resourceName,
            })
        end

        return originalFunction(table.unpack(args))
    end
end

local function tokenSyncEvent()
    return TOKEN_PREFIX .. "Sync:" .. RESOURCE_NAME
end

local function tokenRequestEvent()
    return TOKEN_PREFIX .. "Request:" .. RESOURCE_NAME
end

local function isControlEvent(eventName)
    return type(eventName) == "string" and eventName:sub(1, #TOKEN_PREFIX) == TOKEN_PREFIX
end

encryptionKey = loadEncryptionKey()

if not IsDuplicityVersion() then
    TriggerEvent("SecureServe:Client:LoadedKey", RESOURCE_NAME)
end

for _, nativeName in ipairs({
    "CreateObject",
    "CreateObjectNoOffset",
    "CreateVehicle",
    "CreatePed",
    "CreatePedInsideVehicle",
    "CreateRandomPed",
    "CreateRandomPedAsDriver",
    "CreateScriptVehicleGenerator",
    "CreateVehicleServerSetter",
    "CreateAutomobile",
}) do
    wrapEntityNative(nativeName)
end

if IsDuplicityVersion() then
    local originalAddEventHandler = AddEventHandler
    local originalRegisterNetEvent = RegisterNetEvent
    local registeredEvents = {}
    local publicTraps = {}
    local playerSessions = {}
    local startedAt = os.time()

    math.randomseed((GetGameTimer and GetGameTimer() or os.time()) + (#RESOURCE_NAME * 97))

    local function getProtectorConfig()
        local config = { Enabled = true, Mode = "log", GraceSeconds = 30 }
        local ok, result = pcall(function()
            return exports[KEY_RESOURCE]:get_event_protector_config()
        end)

        if ok and type(result) == "table" then
            config.Enabled = result.Enabled ~= false
            config.Mode = result.Mode == "enforce" and "enforce" or "log"
            config.GraceSeconds = tonumber(result.GraceSeconds) or 30
        end

        return config
    end

    local function isExemptEvent(eventName)
        if isControlEvent(eventName) or fxEvents[eventName] then return true end

        local ok, result = pcall(function()
            return exports[KEY_RESOURCE]:is_event_protector_exempt(eventName)
        end)

        return ok and result == true
    end

    local function isPlayerSource(src)
        src = tonumber(src)
        return src and src > 0 and GetPlayerPing(src) > 0
    end

    local function hashToken(raw)
        local hash = 5381
        for i = 1, #raw do
            hash = ((hash * 33) + raw:byte(i)) % 2147483647
        end
        return ("%08x"):format(hash)
    end

    local function newToken(src)
        local timer = GetGameTimer and GetGameTimer() or math.floor(os.clock() * 100000)
        local raw = table.concat({
            RESOURCE_NAME,
            tostring(src),
            tostring(os.time()),
            tostring(timer),
            tostring(math.random(100000, 999999)),
            tostring({}),
            encryptionKey,
        }, ":")

        return hashToken(raw) .. hashToken(raw:reverse())
    end

    local function issueToken(src)
        src = tonumber(src)
        if not src or src <= 0 then return end

        local session = {
            token = newToken(src),
            seq = 0,
            issuedAt = os.time(),
        }

        playerSessions[src] = session
        TriggerClientEvent(tokenSyncEvent(), src, session.token, RESOURCE_NAME)
    end

    local function isTokenEnvelope(value)
        return type(value) == "table" and value[TOKEN_FIELD] == true
    end

    local function inGrace(config)
        return (os.time() - startedAt) <= (tonumber(config.GraceSeconds) or 0)
    end

    local function reportViolation(src, eventName, detail, config)
        local message = ("Unauthorized network event: %s in resource: %s (%s)")
            :format(eventName, RESOURCE_NAME, detail)

        if config.Enabled and config.Mode == "enforce" and not inGrace(config) then
            local ok = pcall(function()
                exports[KEY_RESOURCE]:module_punish(src, message)
            end)
            if not ok then print("^1[SecureServe] " .. message .. "^7") end
            return true
        end

        print("^3[SecureServe] " .. message .. "^7")
        return false
    end

    local function validateEnvelope(src, envelope)
        if not isTokenEnvelope(envelope) then
            return false, "missing token"
        end

        if envelope.resource ~= RESOURCE_NAME then
            return false, "wrong resource"
        end

        local session = playerSessions[src]
        if not session then
            issueToken(src)
            return false, "missing session"
        end

        local seq = tonumber(envelope.seq)
        if envelope.token ~= session.token then
            return false, "invalid token"
        end

        if not seq or seq <= session.seq then
            return false, "replayed token"
        end

        session.seq = seq
        return true
    end

    local function protectedHandler(eventName, handler)
        return function(...)
            local src = tonumber(source)
            local packed = table.pack(...)
            local hasEnvelope = isTokenEnvelope(packed[1])
            local firstArg = hasEnvelope and 2 or 1

            if not isPlayerSource(src) then
                return handler(table.unpack(packed, 1, packed.n))
            end

            local config = getProtectorConfig()
            if config.Enabled == false or isExemptEvent(eventName) then
                return handler(table.unpack(packed, firstArg, packed.n))
            end

            local valid, detail = validateEnvelope(src, packed[1])
            if not valid then
                local rejected = reportViolation(src, eventName, detail, config)
                if rejected then return end
            end

            return handler(table.unpack(packed, firstArg, packed.n))
        end
    end

    local function localOnlyHandler(handler)
        return function(...)
            if isPlayerSource(source) then return end
            return handler(...)
        end
    end

    local function registerPublicTrap(eventName)
        if publicTraps[eventName] then return end
        publicTraps[eventName] = true

        originalRegisterNetEvent(eventName)
        originalAddEventHandler(eventName, function()
            local src = tonumber(source)
            if not isPlayerSource(src) then return end

            local config = getProtectorConfig()
            reportViolation(src, eventName, "public event trigger", config)
        end)
    end

    local function registerEncryptedEvent(eventName)
        local encryptedEventName = registeredEvents[eventName]
        if encryptedEventName then return encryptedEventName end

        encryptedEventName = encryptDecrypt(eventName)
        registeredEvents[eventName] = encryptedEventName
        originalRegisterNetEvent(encryptedEventName)
        return encryptedEventName
    end

    originalRegisterNetEvent(tokenRequestEvent())
    originalAddEventHandler(tokenRequestEvent(), function()
        issueToken(source)
    end)

    originalAddEventHandler("playerJoining", function()
        local src = source
        SetTimeout(2500, function()
            if isPlayerSource(src) then issueToken(src) end
        end)
    end)

    originalAddEventHandler("playerDropped", function()
        playerSessions[source] = nil
    end)

    Citizen.CreateThread(function()
        Wait(1500)
        for _, playerId in ipairs(GetPlayers()) do
            issueToken(tonumber(playerId))
        end
    end)

    _G.RegisterNetEvent = function(eventName, ...)
        if type(eventName) ~= "string" or isControlEvent(eventName) then
            return originalRegisterNetEvent(eventName, ...)
        end

        local encryptedEventName = registerEncryptedEvent(eventName)
        local args = table.pack(...)
        local callback = args[1]

        if isExemptEvent(eventName) then
            originalRegisterNetEvent(eventName)
            if type(callback) == "function" then
                originalAddEventHandler(eventName, callback)
                return originalAddEventHandler(encryptedEventName, callback)
            end
            return
        end

        registerPublicTrap(eventName)
        if type(callback) == "function" then
            originalAddEventHandler(eventName, localOnlyHandler(callback))
            return originalAddEventHandler(encryptedEventName, protectedHandler(eventName, callback))
        end
    end

    _G.AddEventHandler = function(eventName, handler, ...)
        if type(eventName) ~= "string" or type(handler) ~= "function" then
            return originalAddEventHandler(eventName, handler, ...)
        end

        local encryptedEventName = registeredEvents[eventName]
        if not encryptedEventName then
            return originalAddEventHandler(eventName, handler, ...)
        end

        if isExemptEvent(eventName) then
            originalAddEventHandler(encryptedEventName, handler, ...)
            return originalAddEventHandler(eventName, handler, ...)
        end

        registerPublicTrap(eventName)
        originalAddEventHandler(eventName, localOnlyHandler(handler), ...)
        return originalAddEventHandler(encryptedEventName, protectedHandler(eventName, handler), ...)
    end

    RegisterServerEvent = RegisterNetEvent
else
    local originalTriggerServerEvent = TriggerServerEvent
    local eventToken = nil
    local eventSeq = 0

    RegisterNetEvent(tokenSyncEvent(), function(token, resourceName)
        if resourceName and resourceName ~= RESOURCE_NAME then return end
        if type(token) ~= "string" or token == "" then return end

        eventToken = token
        eventSeq = 0
    end)

    Citizen.CreateThread(function()
        Wait(500)
        originalTriggerServerEvent(tokenRequestEvent())
    end)

    _G.TriggerServerEvent = function(eventName, ...)
        if type(eventName) ~= "string" or isControlEvent(eventName) then
            return originalTriggerServerEvent(eventName, ...)
        end

        if not eventToken then
            return originalTriggerServerEvent(encryptDecrypt(eventName), ...)
        end

        eventSeq = eventSeq + 1
        return originalTriggerServerEvent(encryptDecrypt(eventName), {
            [TOKEN_FIELD] = true,
            token = eventToken,
            seq = eventSeq,
            resource = RESOURCE_NAME,
        }, ...)
    end

    for _, native in ipairs({
        { name = "GiveWeaponToPed",     argIndex = 2 },
        { name = "RemoveWeaponFromPed", argIndex = 2 },
        { name = "RemoveAllPedWeapons", argIndex = nil },
        { name = "SetCurrentPedWeapon", argIndex = 2 },
    }) do
        wrapWeaponNative(native)
    end
end
