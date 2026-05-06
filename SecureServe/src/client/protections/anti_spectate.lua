local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")

local Cache = require("client/core/cache")

local AntiSpectate = {}

function AntiSpectate.initialize()
    if not ConfigLoader.get_protection_setting("Anti Spectate", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(4500)
            
            if Cache.Get("hasPermission", "spectate") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end
            
            if NetworkIsInSpectatorMode() then
                ProtectionHelper.punish('Anti Spectate', "Anti Spectate")
            end
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("spectate", AntiSpectate.initialize)

return AntiSpectate
