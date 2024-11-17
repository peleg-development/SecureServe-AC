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


local createEntity = LPH_JIT_MAX(function(originalFunction, ...)
	local entity = originalFunction(...)
	if entity then
		if IsDuplicityVersion() then
			TriggerClientEvent('entity2', -1, GetEntityModel(entity))
			TriggerEvent("entityCreatedByScript", entity, 'fdgfd', true, GetEntityModel(entity))
		else
			TriggerEvent('entityCreatedByScriptClient', entity)
			TriggerServerEvent("entityCreatedByScript", entity, 'fdgfd', true, GetEntityModel(entity))
		end
		return entity
	end
end)

local _CreateObject = CreateObject
local _CreateObjectNoOffset = CreateObjectNoOffset
local _CreateVehicle = CreateVehicle
local _CreatePed = CreatePed
local _CreatePedInsideVehicle = CreatePedInsideVehicle
local _CreateRandomPed = CreateRandomPed
local _CreateRandomPedAsDriver = CreateRandomPedAsDriver
local _CreateScriptVehicleGenerator = CreateScriptVehicleGenerator
local _CreateVehicleServerSetter = CreateVehicleServerSetter

CreateObject = LPH_JIT_MAX(function(...) return createEntity(_CreateObject, ...) end)
CreateObjectNoOffset = LPH_JIT_MAX(function(...) return createEntity(_CreateObjectNoOffset, ...) end)
CreateVehicle = LPH_JIT_MAX(function(...) return createEntity(_CreateVehicle, ...) end)
CreatePed = LPH_JIT_MAX(function(...) return createEntity(_CreatePed, ...) end)
CreatePedInsideVehicle = LPH_JIT_MAX(function(...) return createEntity(_CreatePedInsideVehicle, ...) end)
CreateRandomPed = LPH_JIT_MAX(function(...) return createEntity(_CreateRandomPed, ...) end)
CreateRandomPedAsDriver = LPH_JIT_MAX(function(...) return createEntity(_CreateRandomPedAsDriver, ...) end)
CreateScriptVehicleGenerator = LPH_JIT_MAX(function(...) return createEntity(_CreateScriptVehicleGenerator, ...) end)
CreateVehicleServerSetter = LPH_JIT_MAX(function(...) return createEntity(_CreateVehicleServerSetter, ...) end)


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
            return nil
        end
    end
    return xor_decrypt(table.concat(encrypted), key)
end)

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
	["msk_core:server:triggerCallback"] = true,
}


if IsDuplicityVersion() then
    local _AddEventHandler = AddEventHandler
    local _RegisterNetEvent = RegisterNetEvent

	local eventsToRegister = {}

	RegisterNetEvent = LPH_JIT_MAX(function(event_name, ...)
        local encrypted_event_name = encryptEventName(event_name, encryption_key)
		if select("#", ...) == 0 then
			eventsToRegister[encrypted_event_name] = {}
			CancelEvent()
			return
		else
			_RegisterNetEvent(encrypted_event_name, ...)
			_RegisterNetEvent(encrypted_event_name,  function()
				if not (GetCurrentResourceName() == "monitor" or GetCurrentResourceName() == "SecureServe") then
					exports['SecureServe']:CheckTime(event_name, os.time(), source)
				end
			end)

			_RegisterNetEvent(event_name, ...)

			_RegisterNetEvent(event_name, function(...)
				if not exports['SecureServe']:IsEventWhitelisted(event_name) then
					if source and GetPlayerPing(source) > 0 then
						local TE = TriggerEvent
						local rencrypted_event_namea = encryptEventName("SecureServe:Server:Methods:PunishPlayer", encryption_key)
						TE(rencrypted_event_namea, source, "Triggerd server event via excutor: ".. event_name, webhook, 2147483647)
					end
				end
			end)
		end
	end)
	
	AddEventHandler = LPH_JIT_MAX(function(event_name, handler)
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
	end)

    Citizen.CreateThread(LPH_JIT_MAX(function ()
        for event_name, handlers in pairs(eventsToRegister) do
			_RegisterNetEvent(event_name, table.unpack(handlers))
            local decrypted_name = decryptEventName(event_name, encryption_key)
            if decrypted_name then
				_RegisterNetEvent(decrypted_name, function(...)
					if not exports['SecureServe']:IsEventWhitelisted(decrypted_name) then
						if source and GetPlayerPing(source) > 0 then
							local TE = TriggerEvent
							local rencrypted_event_namea = encryptEventName("SecureServe:Server:Methods:PunishPlayer", encryption_key)
							TE(rencrypted_event_namea, source, "Triggerd server event via excutor: ".. decrypted_name, webhook, 2147483647)
						end
					end
				end)
            else
                print("Failed to decrypt event name: " .. event_name .. "Event wont be protected and will be needed to chnage manully to use only RegisterNetEvent")
            end
        end
    end))

	RegisterServerEvent = RegisterNetEvent

else
	local whitelistedEvents = {}

	Citizen.CreateThread(LPH_JIT_MAX(function()
		if GetCurrentResourceName() == "monitor" or GetCurrentResourceName() == "SecureServe" then
			whitelistedEvents = {}
		else
			local success, events = pcall(function()
				return exports['SecureServe']:GetEventWhitelist()
			end)
			if success ~= false then
				whitelistedEvents = events
			else
				whitelistedEvents = {}
			end
		end
	end))

	local allowed = false
	RegisterNetEvent('allowed', function ()
		allowed = true
	end)

	local _TriggerServerEvent = TriggerServerEvent
	TriggerServerEvent = LPH_JIT_MAX(function(event_name, ...)
		local value = false
		if GetCurrentResourceName() == "monitor" or GetCurrentResourceName() == "SecureServe" then
			value = false
		elseif whitelistedEvents[event_name] or fxEvents[event_name] then
			value = true
		else
			value = false
		end
		if not value then
			local encrypted_event_name = encryptEventName(event_name, encryption_key)
			_TriggerServerEvent(encrypted_event_name, ...)
			if not  (GetCurrentResourceName() == "monitor" or GetCurrentResourceName() == "SecureServe") then
				if allowed then
					exports['SecureServe']:TriggeredEvent(event_name, GlobalState.SecureServe)
				end
			end
		else
			_TriggerServerEvent(event_name, ...)
		end
	end)


end
