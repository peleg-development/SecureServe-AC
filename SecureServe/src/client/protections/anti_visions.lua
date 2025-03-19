local ProtectionManager = require("client/protections/protection_manager")

---@class AntiVisionsModule
local AntiVisions = {}

---@description Initialize Anti Night Vision and Anti Thermal Vision protections
function AntiVisions.initialize()
    if not Anti_Thermal_Vision_enabled and not Anti_Night_Vision_enabled then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(6500)
            
            if Anti_Thermal_Vision_enabled then
                if GetUsingseethrough() then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Thermal Vision", Anti_Thermal_Vision_webhook, Anti_Thermal_Vision_time)
                end
            end
            
            if Anti_Night_Vision_enabled then
                if GetUsingnightvision() then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Night Vision", Anti_Night_Vision_webhook, Anti_Night_Vision_time)
                end
            end
        end
    end)
end

ProtectionManager.register_protection("visions", AntiVisions.initialize)

return AntiVisions 