local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiAimAssist = {}

function AntiAimAssist.initialize()
    if not ConfigLoader.get_protection_setting("Anti Aim Assist", "enabled") then
        return
    end

    Citizen.CreateThread(function()
        local strikes = 0
        local STRIKE_LIMIT = 3

        while true do
            Citizen.Wait(2000)

            local is_exempt = Cache.Get("hasPermission", "aimassist")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")

            if is_exempt then
                strikes = 0
            else
                SetPlayerTargetingMode(3)

                local aim_state = GetLocalPlayerAimState()
                if aim_state ~= 3 then
                    strikes = strikes + 1
                    if strikes >= STRIKE_LIMIT then
                        strikes = 0
                        ProtectionHelper.punish("Anti Aim Assist",
                            ("Anti Aim Assist (Mode: %s)"):format(tostring(aim_state)))
                    end
                else
                    if strikes > 0 then strikes = strikes - 1 end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("aim_assist", AntiAimAssist.initialize)
return AntiAimAssist
