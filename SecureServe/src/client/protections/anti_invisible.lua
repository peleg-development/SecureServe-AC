local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiInvisibleModule
local AntiInvisible = {}

---@description Initialize Anti Invisible protection
function AntiInvisible.initialize()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2500)
            if not ConfigLoader.get_protection_setting("Anti Invisible", "enabled") then return end
            
            if Cache.Get("isInvisible") and not Cache.Get("isAdmin") then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Invisible", ConfigLoader.get_protection_setting("Anti Invisible", "webhook"), ConfigLoader.get_protection_setting("Anti Invisible", "time"))
            end
        end
    end)
end

ProtectionManager.register_protection("invisible", AntiInvisible.initialize)

return AntiInvisible 