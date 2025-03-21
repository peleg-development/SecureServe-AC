local ProtectionManager = require("client/protections/protection_manager")
local Utils = require("shared/lib/utils")

---@class AntiEntitySecurityModule
local AntiEntitySecurity = {}

---@description Safely get the entity script
---@param entity number Entity handle
---@return string|nil script Name of the script that created the entity
local function safe_get_entity_script(entity)
    local success, result = pcall(GetEntityScript, entity)
    
    if not success then
        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Created Suspicious Entity [Vehicle] with no script", webhook, time)
        return nil
    end
    
    if result then
        return result
    else
        return nil
    end
end

---@description Delete all objects in the world
local function delete_all_objects()
    for object in Utils.enumerate_objects() do
        DeleteObject(object)
    end
end

---@description Initialize Entity Security protection
function AntiEntitySecurity.initialize()

    -- local entity_spawned = {}
    -- local entity_spawned_hashes = {}
    -- local whitelisted_resources = {}

    for _, entry in ipairs(SecureServe.Module.Entity.SecurityWhitelist) do
        whitelisted_resources[entry.resource] = entry.whitelist
    end

    local function checkEntityResource(entity, entityType, modelHash)
        local entityScript = GetEntityScript(entity)
        if not entityScript then entityScript = "unknown" end
        
        local isWhitelisted = false
        if whitelisted_resources[entityScript] then
            for _, hash in pairs(whitelisted_resources[entityScript]) do
                if hash == modelHash then
                    isWhitelisted = true
                    break
                end
            end
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
            
            TriggerServerEvent('clearall')
            
            local detectionMessage = string.format("Created blacklisted %s (hash: %s) from unauthorized resource: %s", 
                entityType, modelHash, entityScript)
                
            TriggerServerEvent("SecureServe:Server:Methods:ModulePunish", nil, detectionMessage, "entity_security", 0)
        end
    end

    -- Handler for server requests to check entity resources
    RegisterNetEvent("SecureServe:CheckEntityResource", function(netId, modelHash)
        local entity = NetworkGetEntityFromNetworkId(netId)
        if not entity or not DoesEntityExist(entity) then return end
        
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
                for _, hash in pairs(whitelisted_resources[entityScript]) do
                    if hash == modelHash then
                        isWhitelisted = true
                        break
                    end
                end
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
                
                TriggerServerEvent('clearall')
                
                local detectionMessage = string.format("Created blacklisted %s (hash: %s) from unauthorized resource: %s", 
                    entityType, modelHash, entityScript)
                TriggerServerEvent("SecureServe:Server:Methods:ModulePunish", nil, detectionMessage, "entity_security", 0)
            end
        end
    end)

    AddStateBagChangeHandler("VehicleCreate", "entity:", function(bagName, key, value, _unused, replicated)
        if not value then return end
        local vehicleEntity = GetEntityFromStateBagName(bagName)
        local vehicleHash = GetEntityModel(vehicleEntity)
        
        if blacklisted_vehicles[vehicleHash] then
            SetEntityAsMissionEntity(vehicleEntity, true, true)
            DeleteVehicle(vehicleEntity)
            
            checkEntityResource(vehicleEntity, "Vehicle", vehicleHash)
        end
    end)
    
    AddStateBagChangeHandler("PedCreate", "entity:", function(bagName, key, value, _unused, replicated)
        if not value then return end
        local pedEntity = GetEntityFromStateBagName(bagName)
        local pedHash = GetEntityModel(pedEntity)
        
        if blacklisted_peds[pedHash] then
            SetEntityAsMissionEntity(pedEntity, true, true)
            DeleteEntity(pedEntity)
            
            checkEntityResource(pedEntity, "Ped", pedHash)
        end
    end)
    
    AddStateBagChangeHandler("ObjectCreate", "entity:", function(bagName, key, value, _unused, replicated)
        if not value then return end
        local objectEntity = GetEntityFromStateBagName(bagName)
        local objectHash = GetEntityModel(objectEntity)
        
        if blacklisted_objects[objectHash] then
            SetEntityAsMissionEntity(objectEntity, true, true)
            DeleteEntity(objectEntity)
            
            checkEntityResource(objectEntity, "Object", objectHash)
        end
    end)
end

ProtectionManager.register_protection("entity_security", AntiEntitySecurity.initialize)

return AntiEntitySecurity 