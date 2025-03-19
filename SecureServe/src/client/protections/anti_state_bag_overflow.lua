local ProtectionManager = require("client/protections/protection_manager")

---@class AntiStateBagOverflowModule
local AntiStateBagOverflow = {}

---@description Initialize Anti State Bag Overflow protection
function AntiStateBagOverflow.initialize()
    if not Anti_State_Bag_Overflow_enabled then return end
    
    AddStateBagChangeHandler(nil, nil, function(bag_name, key, value) 
        if #key > 131072 then
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti State Bag Overflow", Anti_State_Bag_Overflow_webhook, Anti_State_Bag_Overflow_time)
        end
    end)
end

ProtectionManager.register_protection("state_bag_overflow", AntiStateBagOverflow.initialize)

return AntiStateBagOverflow 