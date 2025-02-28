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

if IsDuplicityVersion() then
    local _AddEventHandler = AddEventHandler
    local _RegisterNetEvent = RegisterNetEvent
    local events_to_listen = {}
    local processed_events = {}
    
    _G.RegisterNetEvent = function(event_name, ...)
        if processed_events[event_name] then
            return processed_events[event_name]
        end
        
        local enc_event_name = encryptDecrypt(event_name) 
        events_to_listen[event_name] = enc_event_name 
        
        local result = _RegisterNetEvent(enc_event_name, ...)
        processed_events[event_name] = result
        
        return _RegisterNetEvent(event_name, ...)
    end
    
    _G.AddEventHandler = function(event_name, handler, ...)
        local enc_event_name = events_to_listen[event_name]
        local handler_ref = _AddEventHandler(event_name, handler, ...)
    
        if enc_event_name and not processed_events["handler_" .. enc_event_name] then
            _AddEventHandler(enc_event_name, handler, ...)
            processed_events["handler_" .. enc_event_name] = true
        end
    
        return handler_ref
    end
    
    Citizen.CreateThread(function()
        for event_name, enc_event_name in pairs(events_to_listen) do
            if not processed_events["security_" .. event_name] then
                processed_events["security_" .. event_name] = true
                
                _AddEventHandler(event_name, function ()
                    local src = source
    
                    if GetPlayerPing(src) > 0 then
                        local resourceName = GetCurrentResourceName()
                        local banMessage = ("Tried triggering a restricted event: %s in resource: %s."):format(event_name, resourceName)
                        
                        TriggerEvent("SecureServe:Server:Methods:ModulePunish" .. GlobalState.SecureServe_events, src, banMessage)
                    end
                end)
    
                -- _AddEventHandler(enc_event_name, function ()
                --     local src = source 
                    
                --     if GetPlayerPing(src) > 0 then
                --         local decrypted = decrypt(enc_event_name)
                --         if decrypted ~= "add_to_trigger_list" then
                --             TriggerEvent("check_trigger_list", src, decrypted)
                --         end
                --     end
                -- end)
            end
        end
    end)
    

	RegisterServerEvent = RegisterNetEvent
else
	local _TriggerServerEvent = TriggerServerEvent
    local run = false
    local eventsPending = {}
    local eventsSent = {}

    AddEventHandler("playerSpawned", function()
        run = true;
        for eventName, args in pairs(eventsPending) do
            _TriggerServerEvent(encryptDecrypt(eventName), table.unpack(args))
        end
        eventsPending = {}
    end)

    _G.TriggerServerEvent = function(eventName, ...)
        local encryptedEvent = encryptDecrypt(eventName)
        local args = {...}
        
        if eventsSent[eventName] then
            _TriggerServerEvent(encryptedEvent, ...)
            return
        end

        _TriggerServerEvent(encryptDecrypt("add_to_trigger_list"), encryptedEvent)

        eventsSent[eventName] = true
        
        if not run then
            eventsPending[eventName] = args
            return
        end
        
        return _TriggerServerEvent(encryptedEvent, ...)
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