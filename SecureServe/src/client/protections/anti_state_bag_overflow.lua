local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")

local AntiStateBagOverflow = {
    active_handlers = {},
    last_check_time = 0,
    cooldown = 2000
}

function AntiStateBagOverflow.cleanup()
    for _, handler in pairs(AntiStateBagOverflow.active_handlers) do
        if handler then RemoveStateBagChangeHandler(handler) end
    end
    AntiStateBagOverflow.active_handlers = {}
end

function AntiStateBagOverflow.initialize()
    if not ConfigLoader.get_protection_setting("Anti State Bag Overflow", "enabled") then return end

    local KEY_LIMIT   = 4096
    local VALUE_LIMIT = 32768

    AntiStateBagOverflow.active_handlers.main = AddStateBagChangeHandler(nil, nil, function(bag_name, key, value)
        local current_time = GetGameTimer()
        if current_time - AntiStateBagOverflow.last_check_time < AntiStateBagOverflow.cooldown then
            return
        end
        AntiStateBagOverflow.last_check_time = current_time

        if type(key) == "string" and #key > KEY_LIMIT then
            ProtectionHelper.punish('Anti State Bag Overflow',
                ("Anti State Bag Overflow (key length %d)"):format(#key))
            return
        end

        if type(value) == "string" and #value > VALUE_LIMIT then
            ProtectionHelper.punish('Anti State Bag Overflow',
                ("Anti State Bag Overflow (value length %d)"):format(#value))
            return
        end
    end)

    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end
        AntiStateBagOverflow.cleanup()
        collectgarbage("collect")
    end)
end

ProtectionManager.register_protection("state_bag_overflow", AntiStateBagOverflow.initialize)

return AntiStateBagOverflow
