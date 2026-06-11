local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")

local Cache = require("client/core/cache")

local AntiSpectate = {}

function AntiSpectate.initialize()
    if not ConfigLoader.get_protection_setting("Anti Spectate", "enabled") then return end

    -- Fix: added consecutive strikes (instead of immediate punishment) because NetworkIsInSpectatorMode is true during legitimate session transitions -> false positive / instant ban otherwise.
    local STRIKE_LIMIT = 3

    Citizen.CreateThread(function()
        local strikes = 0

        while true do
            Citizen.Wait(4500)

            local is_exempt = Cache.Get("hasPermission", "spectate")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")

            if not is_exempt and NetworkIsInSpectatorMode() then
                strikes = strikes + 1
                if strikes >= STRIKE_LIMIT then
                    strikes = 0
                    ProtectionHelper.punish('Anti Spectate', "Anti Spectate")
                end
            elseif strikes > 0 then
                strikes = strikes - 1
            end
        end
    end)
end

ProtectionManager.register_protection("spectate", AntiSpectate.initialize)

return AntiSpectate
