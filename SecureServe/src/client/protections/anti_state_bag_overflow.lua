local ProtectionManager = require("client/protections/protection_manager")

---@class AntiStateBagOverflowModule
local AntiStateBagOverflow = {
    active_handlers = {},
    last_check_time = 0,
    cooldown = 2000 -- Check cooldown in milliseconds
}

---@description Initialize Anti State Bag Overflow protection
function AntiStateBagOverflow.initialize()
    if not Anti_State_Bag_Overflow_enabled then return end
    
    -- Clean up any existing handlers to prevent duplicates
    AntiStateBagOverflow.cleanup()
    
    -- More efficient state bag handler with cooldown
    AntiStateBagOverflow.active_handlers.main = AddStateBagChangeHandler(nil, nil, function(bag_name, key, value) 
        -- Skip overly frequent checks
        local current_time = GetGameTimer()
        if current_time - AntiStateBagOverflow.last_check_time < AntiStateBagOverflow.cooldown then
            return
        end
        AntiStateBagOverflow.last_check_time = current_time
        
        -- Check key length but only process strings to avoid errors
        if type(key) == "string" and #key > 131072 then
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti State Bag Overflow", Anti_State_Bag_Overflow_webhook, Anti_State_Bag_Overflow_time)
        end
    end)
end

function AntiStateBagOverflow.cleanup()
    -- Remove any existing handlers
    for _, handler in pairs(AntiStateBagOverflow.active_handlers) do
        RemoveStateBagChangeHandler(handler)
    end
    AntiStateBagOverflow.active_handlers = {}
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    AntiStateBagOverflow.cleanup()
    collectgarbage("collect")
end)

ProtectionManager.register_protection("state_bag_overflow", AntiStateBagOverflow.initialize)

return AntiStateBagOverflow 