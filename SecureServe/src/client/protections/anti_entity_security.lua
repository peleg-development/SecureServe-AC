local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Utils = require("shared/lib/utils")
local Cache = require("client/core/cache")

---@class AntiEntitySecurityModule
local AntiEntitySecurity = {
    active_handlers = {},
    entity_cache = {},
    cleanup_interval = 120000, 
    last_cache_cleanup = 0,
    entity_check_count = 0 
}

---@description Initialize Entity Security protection
function AntiEntitySecurity.initialize()
    AntiEntitySecurity.cleanup()

    local whitelisted_resources = {}
    local last_check_times = {}
    local CHECK_COOLDOWN = 1000 
    
    local secureServe = ConfigLoader.get_secureserve()
    if not secureServe or not secureServe.Module or not secureServe.Module.Entity then
        return
    end
    
    local blacklisted_vehicles = {}
    local blacklisted_peds = {}
    local blacklisted_objects = {}
    
    for _, entry in ipairs(secureServe.Module.Entity.SecurityWhitelist) do
        whitelisted_resources[entry.resource] = entry.whitelist
    end

    local function checkEntityResource(entity, entityType, modelHash)
        AntiEntitySecurity.entity_check_count = AntiEntitySecurity.entity_check_count + 1
        if AntiEntitySecurity.entity_check_count % 3 ~= 0 then 
            return 
        end
        
        if not entity or not DoesEntityExist(entity) then return end
        
        local entityId = tostring(entity)
        if AntiEntitySecurity.entity_cache[entityId] then
            return
        end
        
        AntiEntitySecurity.entity_cache[entityId] = {
            time = GetGameTimer(),
            type = entityType
        }
        
        local entityScript = GetEntityScript(entity)
        if not entityScript then entityScript = "unknown" end
        
        if whitelisted_resources[entityScript] then
            return 
        end
        
        if DoesEntityExist(entity) then
            SetEntityAsMissionEntity(entity, true, true)
            if IsEntityAVehicle(entity) then
                DeleteVehicle(entity)
            else
                DeleteEntity(entity)
            end
        end
        
        local detectionMessage = string.format("Created blacklisted %s (hash: %s) from unauthorized resource: %s", 
            entityType, modelHash, entityScript)
            
        TriggerServerEvent("SecureServe:Server:Methods:ModulePunish", nil, detectionMessage, "entity_security", 2147483647)
    end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(30000) 
            
            local current_time = GetGameTimer()
            if (current_time - AntiEntitySecurity.last_cache_cleanup) < AntiEntitySecurity.cleanup_interval then
                goto continue 
            end
            
            local count = 0
            local cache_size = 0
            
            for _ in pairs(AntiEntitySecurity.entity_cache) do
                cache_size = cache_size + 1
            end
            
            if cache_size > 100 then
                for entityId, info in pairs(AntiEntitySecurity.entity_cache) do
                    if current_time - info.time > AntiEntitySecurity.cleanup_interval then
                        AntiEntitySecurity.entity_cache[entityId] = nil
                        count = count + 1
                    end
                end
                
                AntiEntitySecurity.entity_check_count = 0
                
                if count > 0 then
                    collectgarbage("step", 50)
                end
                
                AntiEntitySecurity.last_cache_cleanup = current_time
            end
            
            ::continue::
        end
    end)

    AntiEntitySecurity.event_handler = RegisterNetEvent("SecureServe:CheckEntityResource", function(netId, modelHash)
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity == nil or not DoesEntityExist(entity) then return end
        
        local entityType = "Unknown"
        if IsEntityAVehicle(entity) then
            entityType = "Vehicle"
        elseif IsEntityAPed(entity) then
            entityType = "Ped"
        elseif IsEntityAnObject(entity) then
            entityType = "Object"
        end
        
        local entityScript = GetEntityScript(entity)
        if not entityScript then entityScript = "unknown" end
        if entityScript ~= "unknown" then
            local isWhitelisted = false
            if whitelisted_resources[entityScript] then
                isWhitelisted = true
                return 
            end
            
            if not isWhitelisted then
                if DoesEntityExist(entity) then
                    SetEntityAsMissionEntity(entity, true, true)
                    if IsEntityAVehicle(entity) then
                        DeleteVehicle(entity)
                    else
                        DeleteEntity(entity)
                    end
                end
                                
                local detectionMessage = string.format("Created blacklisted %s (hash: %s) from unauthorized resource: %s", 
                    entityType, modelHash, entityScript)
                TriggerServerEvent("SecureServe:Server:Methods:ModulePunish", nil, detectionMessage, "entity_security", 2147483647)
            end
        end
    end)

    local function handleEntityStateBag(entityType, bagName, value, entityGetFunction, entityHash, blacklist)
        if not value then return end
        
        local current_time = GetGameTimer()
        if last_check_times[entityType] and (current_time - last_check_times[entityType]) < CHECK_COOLDOWN then
            return
        end
        last_check_times[entityType] = current_time
        
        local entity = entityGetFunction(bagName)
        if not entity or not DoesEntityExist(entity) then return end
        
        local hash = GetEntityModel(entity)
        
        if blacklist and blacklist[hash] then
            SetEntityAsMissionEntity(entity, true, true)
            
            if entityType == "Vehicle" then
                DeleteVehicle(entity)
            else
                DeleteEntity(entity)
            end
            
            checkEntityResource(entity, entityType, hash)
        end
    end

    AntiEntitySecurity.active_handlers.vehicle = AddStateBagChangeHandler("VehicleCreate", "entity:", function(bagName, key, value)
        handleEntityStateBag("Vehicle", bagName, value, 
            function(bag) return GetEntityFromStateBagName(bag) end,
            "vehicleHash", blacklisted_vehicles)
    end)
    
    AntiEntitySecurity.active_handlers.ped = AddStateBagChangeHandler("PedCreate", "entity:", function(bagName, key, value)
        handleEntityStateBag("Ped", bagName, value, 
            function(bag) return GetEntityFromStateBagName(bag) end,
            "pedHash", blacklisted_peds)
    end)
    
    AntiEntitySecurity.active_handlers.object = AddStateBagChangeHandler("ObjectCreate", "entity:", function(bagName, key, value)
        handleEntityStateBag("Object", bagName, value, 
            function(bag) return GetEntityFromStateBagName(bag) end,
            "objectHash", blacklisted_objects)
    end)
end

function AntiEntitySecurity.cleanup()
    for name, handler in pairs(AntiEntitySecurity.active_handlers) do
        RemoveStateBagChangeHandler(handler)
    end
    AntiEntitySecurity.active_handlers = {}
    
    AntiEntitySecurity.entity_cache = {}
    AntiEntitySecurity.last_cache_cleanup = GetGameTimer()
    AntiEntitySecurity.entity_check_count = 0
    
    collectgarbage("step", 50)
end

ProtectionManager.register_protection("entity_security", AntiEntitySecurity.initialize)

return AntiEntitySecurity