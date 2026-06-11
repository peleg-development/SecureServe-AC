local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")

local Cache = require("client/core/cache")

local AntiSpectate = {}

function AntiSpectate.initialize()
    if not ConfigLoader.get_protection_setting("Anti Spectate", "enabled") then return end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(4500)

            local is_exempt = Cache.Get("hasPermission", "spectate")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")

            if not is_exempt and NetworkIsInSpectatorMode() then
                ProtectionHelper.punish('Anti Spectate', "Anti Spectate")
            end
        end
    end)
end

ProtectionManager.register_protection("spectate", AntiSpectate.initialize)

return AntiSpectate
