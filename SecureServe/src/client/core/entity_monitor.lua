---@class EntityMonitorModule
local EntityMonitor = {
    tracked_entities = {},
    suspicious_entities = {}
}

local Utils = require("shared/lib/utils")

---@description Initialize entity monitoring
function EntityMonitor.initialize()
   return 
end

---@description Get the name of an entity type
---@param entity_type number The entity type number
---@return string The entity type name
function EntityMonitor.get_entity_type_name(entity_type)
    if entity_type == 1 then
        return "Ped"
    elseif entity_type == 2 then
        return "Vehicle"
    elseif entity_type == 3 then
        return "Object"
    else
        return "Unknown"
    end
end

return EntityMonitor 