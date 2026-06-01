local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiInputBlock = {}

local CRITICAL_CONTROLS = {
    [30] = true,
    [31] = true,
    [32] = true,
    [33] = true,
    [34] = true,
    [35] = true,
    [21] = true,
    [22] = true,
    [23] = true,
    [24] = true,
    [25] = true,
    [37] = true,
    [44] = true,
    [199] = true,
    [200] = true,
    [202] = true,
}

function AntiInputBlock.initialize()
    if not ConfigLoader.get_protection_setting("Anti Input Block", "enabled") then return end

    local _DisableControlAction = DisableControlAction
    local disabled_count = 0
    local last_window = GetGameTimer()

    _G.DisableControlAction = function(group, control, disable)
        if Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
            return _DisableControlAction(group, control, disable)
        end

        if disable == true and CRITICAL_CONTROLS[control] then
            local now = GetGameTimer()
            if now - last_window > 1000 then
                disabled_count = 0
                last_window = now
            end
            disabled_count = disabled_count + 1
            if disabled_count > 8 then
                disabled_count = 0
                ProtectionHelper.punish('Anti Input Block',
                    "Mass DisableControlAction on critical controls")
                return
            end
        end

        return _DisableControlAction(group, control, disable)
    end
end

ProtectionManager.register_protection("input_block", AntiInputBlock.initialize)
return AntiInputBlock
