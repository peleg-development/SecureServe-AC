local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")

---@class AntiStateBagOverflowModule
local AntiStateBagOverflow = {
    active_handlers = {},
    last_check_time = 0,
    cooldown = 2000 
}

---@description Initialize Anti State Bag Overflow protection
function AntiStateBagOverflow.initialize()
    if not ConfigLoader.get_protection_setting("Anti State Bag Overflow", "enabled") then return end
    
    AntiStateBagOverflow.cleanup()
    
    AntiStateBagOverflow.active_handlers.main = AddStateBagChangeHandler(nil, nil, function(bag_name, key, value) 
        local current_time = GetGameTimer()
        if current_time - AntiStateBagOverflow.last_check_time < AntiStateBagOverflow.cooldown then
            return
        end
        AntiStateBagOverflow.last_check_time = current_time
        
        if type(key) == "string" and #key > 131072 then
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti State Bag Overflow", webhook, time)
        end
    end)
end

function AntiStateBagOverflow.cleanup()
    for _, handler in pairs(AntiStateBagOverflow.active_handlers) do
        RemoveStateBagChangeHandler(handler)
    end
    AntiStateBagOverflow.active_handlers = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    AntiStateBagOverflow.cleanup()
    collectgarbage("collect")
end)

ProtectionManager.register_protection("state_bag_overflow", AntiStateBagOverflow.initialize)

return AntiStateBagOverflow 