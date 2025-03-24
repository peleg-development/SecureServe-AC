---@class AntiEntitySpamModule
local AntiEntitySpam = {
    vehicleTracker = {},
    pedTracker = {},
    objectTracker = {},
    markedUsers = {}
}

local ban_manager = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

---@description Initialize anti-entity spam protection
function AntiEntitySpam.initialize()
    AddEventHandler("entityCreating", function(entity)
        if not DoesEntityExist(entity) then return end
        
        local entityType  = GetEntityType(entity)
        local owner       = NetworkGetFirstEntityOwner(entity)
        local population  = GetEntityPopulationType(entity)
        local modelHash   = GetEntityModel(entity)
        local hwid        = GetPlayerToken(owner, 0)
    
        if config_manager.is_blacklisted_model(modelHash) then
            if (entityType == 2 and config_manager.is_blacklisted_vehicle_protection_enabled()) or
               (entityType == 1 and config_manager.is_blacklisted_ped_protection_enabled()) or
               (entityType == 3 and config_manager.is_blacklisted_object_protection_enabled()) then
                
                CancelEvent()
                
                local entityTypeName = (entityType == 2 and "Vehicle") or (entityType == 1 and "Ped") or (entityType == 3 and "Object") or "Unknown"
                ban_manager.ban_player(owner, "Blacklisted " .. entityTypeName, 
                    "Tried to spawn a blacklisted " .. entityTypeName:lower() .. " (Hash: " .. modelHash .. ")")
                return
            end
        end
        
        if population == 7 or population == 0 then 
            if entityType == 2 then
                AntiEntitySpam.handleAntiSpam(hwid, owner, AntiEntitySpam.vehicleTracker, "Vehicle", config_manager.get_max_vehicles_per_player())
            elseif entityType == 1 then
                AntiEntitySpam.handleAntiSpam(hwid, owner, AntiEntitySpam.pedTracker, "Ped", config_manager.get_max_peds_per_player())
            elseif entityType == 3 then
                AntiEntitySpam.handleAntiSpam(hwid, owner, AntiEntitySpam.objectTracker, "Object", config_manager.get_max_objects_per_player())
            end
        end
    end)
end

---@param hwid string Hardware ID of the player
---@param owner number Player server ID
---@param tracker table Tracking table for the entity type
---@param entityType string Type of entity being tracked
---@param maxEntities number Maximum allowed entities of this type
function AntiEntitySpam.handleAntiSpam(hwid, owner, tracker, entityType, maxEntities)
    local COOLDOWN_TIME = 10
    
    if not hwid then return end
    
    if not tracker[hwid] then
        tracker[hwid] = { count = 1, time = os.time() }
        return
    end
    
    tracker[hwid].count = tracker[hwid].count + 1
    if os.time() - tracker[hwid].time >= COOLDOWN_TIME then
        tracker[hwid] = nil
        return
    end
    
    if tracker[hwid].count >= maxEntities then
        for _, entity in ipairs(AntiEntitySpam.getAllEntitiesByType(entityType)) do
            local entityOwner = NetworkGetFirstEntityOwner(entity)
            if entityOwner == owner and DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
        
        if not AntiEntitySpam.markedUsers[hwid] then
            AntiEntitySpam.markedUsers[hwid] = true
            AntiEntitySpam.clearSpamTracking()
            ban_manager.ban_player(owner, entityType .. " Spam", 
                "Attempted to spam " .. entityType:lower() .. "s with count of: " .. tracker[hwid].count)
            CancelEvent()
        end
    end
end

---@param entityType string Type of entity to get
---@return table entities List of entities of the specified type
function AntiEntitySpam.getAllEntitiesByType(entityType)
    if entityType == "Vehicle" then return GetAllVehicles() end
    if entityType == "Ped" then return GetAllPeds() end
    if entityType == "Object" then return GetAllObjects() end
    return {}
end

---@description Clears all spam tracking tables
function AntiEntitySpam.clearSpamTracking()
    AntiEntitySpam.vehicleTracker = {}
    AntiEntitySpam.pedTracker = {}
    AntiEntitySpam.objectTracker = {}
end

return AntiEntitySpam 