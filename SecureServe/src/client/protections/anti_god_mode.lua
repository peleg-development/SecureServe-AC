local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiGodModeModule
local AntiGodMode = {}

---@description Initialize Anti God Mode protection
function AntiGodMode.initialize()
    if not ConfigLoader.get_protection_setting("Anti God Mode", "enabled") then return end


    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1500)
            if Cache.Get("hasPermission", "godmode") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end

            ---@todo v1.3.0: Implement Anti God Mode protection
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("god_mode", AntiGodMode.initialize)

return AntiGodMode