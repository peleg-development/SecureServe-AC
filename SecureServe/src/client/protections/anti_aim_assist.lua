local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiAimAssist = {}

-- GetLocalPlayerAimState() returns:
--  0 -> assisted aim (full lock)
--  1 -> assisted partial
--  2 -> assisted free aim
--  3 -> free aim
--
-- Detect sustained "assisted full lock" (0) without overwriting the user's
-- preference. We only flag when the state stays at 0 across multiple ticks
-- AND the player is actively aiming, to avoid menu/transition flickers.
function AntiAimAssist.initialize()
    if not ConfigLoader.get_protection_setting("Anti Aim Assist", "enabled") then
        return
    end

    Citizen.CreateThread(function()
        local strikes = 0
        local STRIKE_LIMIT = tonumber(ConfigLoader.get_protection_setting("Anti Aim Assist", "strike_limit")) or 4
        local INTERVAL     = tonumber(ConfigLoader.get_protection_setting("Anti Aim Assist", "check_interval_ms")) or 2500

        while true do
            Citizen.Wait(INTERVAL)

            local is_exempt = Cache.Get("hasPermission", "aimassist")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")

            if is_exempt then
                strikes = 0
                goto continue
            end

            local ped = Cache.Get("ped")
            if not ped or not DoesEntityExist(ped) then
                strikes = 0
                goto continue
            end

            -- Only evaluate while the player is actually aiming a weapon.
            local pid = PlayerId()
            local is_aiming = IsPlayerFreeAiming(pid) or IsControlPressed(0, 25) -- aim button

            if not is_aiming then
                if strikes > 0 then strikes = strikes - 1 end
                goto continue
            end

            local aim_state = GetLocalPlayerAimState()
            -- 0 = "assisted aim - full" which is the suspicious one. 1/2 are
            -- partial assists shipped by R* and used by controller players.
            if aim_state == 0 then
                strikes = strikes + 1
                if strikes >= STRIKE_LIMIT then
                    strikes = 0
                    ProtectionHelper.punish("Anti Aim Assist",
                        ("Anti Aim Assist (sustained full lock, state=%s)"):format(tostring(aim_state)))
                end
            else
                if strikes > 0 then strikes = strikes - 1 end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("aim_assist", AntiAimAssist.initialize)
return AntiAimAssist
