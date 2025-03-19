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
    print("ghpfipdjmholjgfoljmlgmhkljmlkgmljkmhlkgmjlkmlgkflmjmklklfmgjmklklmfgjklmgklfmjlkmfg")

    local entity_spawned = {}
    local entity_spawned_hashes = {}
    local whitelisted_resources = {}

    for _, entry in ipairs(SecureServe.Module.Entity.SecurityWhitelist) do
        whitelisted_resources[entry.resource] = entry.whitelist
    end

    RegisterNetEvent('entity2', function(hash)
        entity_spawned_hashes[hash] = true
        Citizen.Wait(7500)
        entity_spawned_hashes[hash] = false
    end)

    RegisterNetEvent('entityCreatedByScriptClient', function(entity, resource)
        entity_spawned[entity] = true
    end)

    RegisterNetEvent("check_new_entities", function()
        Citizen.Wait(450)
        
        -- Check suspicious vehicles
        for veh in Utils.enumerate_vehicles() do
            local pop = GetEntityPopulationType(veh)
            if not (pop == 0 or pop == 2 or pop == 4 or pop == 5 or pop == 6) then
                if not entity_spawned[veh] and not entity_spawned_hashes[GetEntityModel(veh)] and DoesEntityExist(veh) then
                    local script = safe_get_entity_script(veh)
                    local is_whitelisted = whitelisted_resources[script] or false 
                    if not is_whitelisted then
                        NetworkRegisterEntityAsNetworked(veh)
                        Citizen.Wait(100)
                        local creator = GetPlayerServerId(NetworkGetEntityOwner(veh))
                        if creator ~= 0 and creator == GetPlayerServerId(PlayerId()) and safe_get_entity_script(veh) ~= '' and safe_get_entity_script(veh) ~= ' ' and safe_get_entity_script(veh) ~= nil then
                            TriggerServerEvent('clearall')
                            TriggerServerEvent("SecureServe:Server:Methods:ModulePunish", nil, "Created Suspicious Entity [Vehicle] at script: " .. script, webhook, time)
                            DeleteEntity(veh)
                        end
                    end
                end
            end
        end

        -- Check suspicious peds
        for ped in Utils.enumerate_peds() do
            local pop = GetEntityPopulationType(ped)
            if not (pop == 0 or pop == 2 or pop == 4 or pop == 5 or pop == 6) then
                if not entity_spawned[ped] and not entity_spawned_hashes[GetEntityModel(ped)] and DoesEntityExist(ped) then
                    local script = safe_get_entity_script(ped)
                    local is_whitelisted = whitelisted_resources[script] or false 
                    local creator = GetPlayerServerId(NetworkGetEntityOwner(ped))
                    if not is_whitelisted and not IsPedAPlayer(ped) and creator == GetPlayerServerId(PlayerId()) and safe_get_entity_script(ped) ~= '' and safe_get_entity_script(ped) ~= ' ' and safe_get_entity_script(ped) ~= nil then
                        if creator ~= 0 then
                            TriggerServerEvent('clearall')
                            TriggerServerEvent("SecureServe:Server:Methods:ModulePunish", nil, "Created Suspicious Entity [Ped]" .. script, webhook, time)
                            DeleteEntity(ped)
                        end
                    end
                end
            end
        end

        -- Check suspicious objects
        for object in Utils.enumerate_objects() do
            local pop = GetEntityPopulationType(object)
            if not (pop == 0 or pop == 2 or pop == 4 or pop == 5 or pop == 6) then
                if not entity_spawned[object] and not entity_spawned_hashes[GetEntityModel(object)] and DoesEntityExist(object) then
                    local script = safe_get_entity_script(object)
                    local is_whitelisted = whitelisted_resources[script] or false 
                    if not is_whitelisted and safe_get_entity_script(object) ~= 'ox_inventory' and DoesEntityExist(object) then
                        local creator = GetPlayerServerId(NetworkGetEntityOwner(object))
                        if creator ~= 0 and creator == GetPlayerServerId(PlayerId()) and safe_get_entity_script(object) ~= '' and safe_get_entity_script(object) ~= ' ' and safe_get_entity_script(object) ~= nil then
                            TriggerServerEvent('clearall')
                            TriggerServerEvent("SecureServe:Server:Methods:ModulePunish", nil, "Created Suspicious Entity [Object] at script: " .. script, webhook, time)
                            DeleteEntity(object)
                            delete_all_objects()
                        end
                    end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("entity_security", AntiEntitySecurity.initialize)

return AntiEntitySecurity 