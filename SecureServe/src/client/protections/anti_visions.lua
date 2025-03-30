local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")

---@class AntiVisionsModule
local AntiVisions = {}

---@description Initialize Anti Night Vision and Anti Thermal Vision protections
function AntiVisions.initialize()
    local enabled = ConfigLoader.get_protection_setting("Anti Visions", "enabled")
    if not enabled then return end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(6500)

            if GetUsingseethrough() then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Thermal Vision", webhook, time)
            end
            if GetUsingnightvision() then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Night Vision", webhook, time)
            end
        end
    end)
end

ProtectionManager.register_protection("visions", AntiVisions.initialize)

return AntiVisions
