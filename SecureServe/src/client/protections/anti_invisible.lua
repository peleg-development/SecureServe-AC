local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiInvisibleModule
local AntiInvisible = {}

---@description Initialize Anti Invisible protection
function AntiInvisible.initialize()
    if not ConfigLoader.get_protection_setting("Anti Invisible", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(15000)
            
            if Cache.Get("hasPermission", "invisible") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end
            
            ---@todo v1.3.0: Implement Anti Invisible protection
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("invisible", AntiInvisible.initialize)

return AntiInvisible 