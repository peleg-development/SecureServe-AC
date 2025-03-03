local createEntity = function(originalFunction, ...)
	local entity = originalFunction(...)
	if entity and DoesEntityExist(entity) then
		if IsDuplicityVersion() then
			TriggerClientEvent('entity2', -1, GetEntityModel(entity))
			TriggerEvent("entityCreatedByScript", entity, 'fdgfd', true, GetEntityModel(entity))
		else
			TriggerEvent('entityCreatedByScriptClient', entity)
			TriggerServerEvent("entityCreatedByScript", entity, 'fdgfd', true, GetEntityModel(entity))
		end
		return entity
	end
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

CreateObject = function(...) return createEntity(_CreateObject, ...) end
CreateObjectNoOffset = function(...) return createEntity(_CreateObjectNoOffset, ...) end
CreateVehicle = function(...) return createEntity(_CreateVehicle, ...) end
CreatePed = function(...) return createEntity(_CreatePed, ...) end
CreatePedInsideVehicle = function(...) return createEntity(_CreatePedInsideVehicle, ...) end
CreateRandomPed = function(...) return createEntity(_CreateRandomPed, ...) end
CreateRandomPedAsDriver = function(...) return createEntity(_CreateRandomPedAsDriver, ...) end
CreateScriptVehicleGenerator = function(...) return createEntity(_CreateScriptVehicleGenerator, ...) end
CreateVehicleServerSetter = function(...) return createEntity(_CreateVehicleServerSetter, ...) end
CreateAutomobile = function(...) return createEntity(_CreateAutomobile, ...) end

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

local xor_decrypt = function(encrypted_text, key)
    local res = {}
    local key_len = #key
    for i = 1, #encrypted_text do
        local xor_byte = string.byte(encrypted_text, i) ~ string.byte(key, (i - 1) % key_len + 1)
        res[i] = string.char(xor_byte)
    end
    return table.concat(res)
end

local decryptEventName = function(encrypted_name, key)
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
end


local fxEvents = {
    ["onResourceStart"] = true,
    ["onResourceStarting"] = true,
    ["onResourceStop"] = true,
    ["onServerResourceStart"] = true,
    ["onServerResourceStop"] = true,
    ["gameEventTriggered"] = true,
    ["populationPedCreating"] = true,
    ["rconCommand"] = true,
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

if IsDuplicityVersion() then
    local _AddEventHandler = AddEventHandler
    local _RegisterNetEvent = RegisterNetEvent

	local eventsToRegister = {}
	local eventQueue = {}
	
	RegisterNetEvent = function(event_name, ...)
		local encrypted_event_name = encryptEventName(event_name, encryption_key)
	
		if select("#", ...) == 0 then
			eventsToRegister[encrypted_event_name] = {}
			CancelEvent()
			return
		end

		_RegisterNetEvent(encrypted_event_name, ...)
		_RegisterNetEvent(event_name, ...)

		eventQueue[event_name] = {encrypted_event_name, {...}}
	end
	
	AddEventHandler = function(event_name, handler)
        local encrypted_event_name = encryptEventName(event_name, encryption_key)
		if not fxEvents[event_name] and not event_name:find("__cfx_") then
			if tonumber(event_name) == nil then
				if handler and type(handler) == 'function' and eventsToRegister[encrypted_event_name] then
					_AddEventHandler(event_name, handler)
					eventsToRegister[encrypted_event_name][#eventsToRegister[encrypted_event_name] + 1] = handler
				else
					_AddEventHandler(event_name, handler)
				end
			else
				_AddEventHandler(event_name, handler)
			end
		else
			_AddEventHandler(event_name, handler)
		end
	end

    Citizen.CreateThread(function ()
        for event_name, handlers in pairs(eventsToRegister) do
			_RegisterNetEvent(event_name, table.unpack(handlers))
            local decrypted_name = decryptEventName(event_name, encryption_key)
			exports["SecureServe"]:add_event_handler(event_name, decrypted_name, handler)
		end

		eventsToRegister = {}
    end)

	Citizen.CreateThread(function()
		for event_name, data in pairs(eventQueue) do
			local encrypted_event_name, handlers = table.unpack(data)
			exports["SecureServe"]:register_net_event(event_name, encrypted_event_name, handlers)
		end
	
		eventQueue = {}
	end)
	
	RegisterServerEvent = RegisterNetEvent
else
	local whitelistedEvents = {}

	Citizen.CreateThread(function()
		if GetCurrentResourceName() == "monitor" or GetCurrentResourceName() == "SecureServe" then
			whitelistedEvents = {}
		else
			local success, events = pcall(function()
				return exports["SecureServe"]:get_event_whitelist()
			end)
	
			if success and events then
				whitelistedEvents = {}
	
				for _, eventName in ipairs(events) do
					local encryptedEventName = encryptEventName(eventName, encryption_key)
					whitelistedEvents[eventName] = true
					whitelistedEvents[encryptedEventName] = true
				end
			else
				whitelistedEvents = {}
			end
		end
	end)
	
	local _TriggerServerEvent = TriggerServerEvent
	TriggerServerEvent = function(event_name, ...)
		local value = false
	
		if GetCurrentResourceName() ~= "monitor" and GetCurrentResourceName() ~= "SecureServe" then
			value = whitelistedEvents[event_name] or fxEvents[event_name]
		end

		-- print("[DEBUG] Triggered Server Event ".. event_name)
		
		if value then
			_TriggerServerEvent(event_name, ...)
		else
			_TriggerServerEvent(encryptEventName(event_name, encryption_key), ...)
		end
	end		

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
	
	AddExplosion = function(...) return handleExplosionEvent(_AddExplosion, ...) end
	AddExplosionWithUserVfx = function(...) return handleExplosionEvent(_AddExplosionWithUserVfx, ...) end
	ExplodeVehicle = function(...) return handleExplosionEvent(_ExplodeVehicle, ...) end
	NetworkExplodeVehicle = function(...) return handleExplosionEvent(_NetworkExplodeVehicle, ...) end
	ShootSingleBulletBetweenCoords = function(...) return handleExplosionEvent(_ShootSingleBulletBetweenCoords, ...) end
	AddOwnedExplosion = function(...) return handleExplosionEvent(_AddOwnedExplosion, ...) end
	StartScriptFire = function(...) return handleExplosionEvent(_StartScriptFire, ...) end
	RemoveScriptFire = function(...) return handleExplosionEvent(_RemoveScriptFire, ...) end	
end