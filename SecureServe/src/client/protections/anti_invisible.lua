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
            if not Anti_Invisible_enabled then return end
            
            if Cache.Get("isInvisible") then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Invisible", Anti_Invisible_webhook, Anti_Invisible_time)
            end
        end
    end)
end

ProtectionManager.register_protection("invisible", AntiInvisible.initialize)

return AntiInvisible 