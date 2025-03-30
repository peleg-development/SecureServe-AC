local ProtectionManager = require("client/protections/protection_manager")

---@class AntiVisionsModule
local AntiVisions = {}

---@description Initialize Anti Night Vision and Anti Thermal Vision protections
function AntiVisions.initialize()
    if not ConfigLoader.get_protection_setting("Anti Visions", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(6500)
            
            if ConfigLoader.get_protection_setting("Anti Visions", "enabled") then
                if GetUsingseethrough() then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Thermal Vision", webhook, time)
                end
            end
            
            if ConfigLoader.get_protection_setting("Anti Visions", "enabled") then
                if GetUsingnightvision() then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Night Vision", webhook, time)
                end
            end
        end
    end)
end

ProtectionManager.register_protection("visions", AntiVisions.initialize)

return AntiVisions 