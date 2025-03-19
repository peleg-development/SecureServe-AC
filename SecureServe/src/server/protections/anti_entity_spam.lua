---@class AntiEntitySpamModule
local AntiEntitySpam = {}

local ban_manager = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

---@description Initialize anti-entity spam protection
function AntiEntitySpam.initialize()
    local SV_VEHICLES = {}
    local SV_PEDS = {}
    local SV_OBJECT = {}
    local SV_Userver = {}

    
    AddEventHandler('entityCreated', function (entity)
        if DoesEntityExist(entity) then
            local POPULATION = GetEntityPopulationType(entity)
            if POPULATION == 7 or POPULATION == 0 then
                
                TriggerClientEvent('check_new_entities', -1)
            end
        end
    end)

    AddEventHandler("entityCreating", function(ENTITY)
        if not DoesEntityExist(ENTITY) then return end
        
        local TYPE       = GetEntityType(ENTITY)
        local OWNER      = NetworkGetFirstEntityOwner(ENTITY)
        local POPULATION = GetEntityPopulationType(ENTITY)
        local MODEL      = GetEntityModel(ENTITY)
        local HWID       = GetPlayerToken(OWNER, 0)
    
        if config_manager.is_blacklisted_model(MODEL) then
            if (TYPE == 2 and config_manager.is_blacklisted_vehicle_protection_enabled()) or
               (TYPE == 1 and config_manager.is_blacklisted_ped_protection_enabled()) or
               (TYPE == 3 and config_manager.is_blacklisted_object_protection_enabled()) then
                
                CancelEvent()
                
                local entity_type_name = (TYPE == 2 and "Vehicle") or (TYPE == 1 and "Ped") or (TYPE == 3 and "Object") or "Unknown"
                ban_manager.ban_player(OWNER, "Blacklisted " .. entity_type_name, 
                    "Tried to spawn a blacklisted " .. entity_type_name:lower() .. " (Hash: " .. MODEL .. ")")
                return
            end
        end
        
        if POPULATION == 7 or POPULATION == 0 then 
            if TYPE == 2 then
                handleAntiSpam(HWID, OWNER, SV_VEHICLES, "Vehicle", config_manager.get_max_vehicles_per_player())
            elseif TYPE == 1 then
                handleAntiSpam(HWID, OWNER, SV_PEDS, "Ped", config_manager.get_max_peds_per_player())
            elseif TYPE == 3 then
                handleAntiSpam(HWID, OWNER, SV_OBJECT, "Object", config_manager.get_max_objects_per_player())
            end
        end
    end)
    
    local COOLDOWN_TIME = 10
    function handleAntiSpam(HWID, OWNER, STORAGE, entityType, maxEntities)
        if not STORAGE[HWID] then
            STORAGE[HWID] = { COUNT = 1, TIME = os.time() }
            return
        end
        
        STORAGE[HWID].COUNT = STORAGE[HWID].COUNT + 1
        if os.time() - STORAGE[HWID].TIME >= COOLDOWN_TIME then
            STORAGE[HWID] = nil
            return
        end
        
        if STORAGE[HWID].COUNT >= maxEntities then
            for _, entity in ipairs(GetAllEntitiesByType(entityType)) do
                local ENO = NetworkGetFirstEntityOwner(entity)
                if ENO == OWNER and DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
            end
            
            if not SV_Userver[HWID] then
                SV_Userver[HWID] = true
                clearSpamTracking()
                ban_manager.ban_player(OWNER, entityType .. " Spam", 
                    "Attempted to spam " .. entityType:lower() .. "s with count of: " .. STORAGE[HWID].COUNT)
                CancelEvent()
            end
        end
    end
    
    function GetAllEntitiesByType(entityType)
        if entityType == "Vehicle" then return GetAllVehicles() end
        if entityType == "Ped" then return GetAllPeds() end
        if entityType == "Object" then return GetAllObjects() end
        return {}
    end
    
    function clearSpamTracking()
        SV_VEHICLES, SV_PEDS, SV_OBJECT = {}, {}, {}
    end

end

return AntiEntitySpam 