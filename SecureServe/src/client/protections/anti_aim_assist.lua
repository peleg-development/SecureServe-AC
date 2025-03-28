local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")

---@class AntiAimAssistModule
local AntiAimAssist = {}

---@description Initialize Anti Aim Assist protection
function AntiAimAssist.initialize()
    local enabled = ConfigLoader.get_protection_setting("Anti Aim Assist", "enabled")
    if not enabled then return end
    
    local webhook = ConfigLoader.get_protection_setting("Anti Aim Assist", "webhook")
    local time = ConfigLoader.get_protection_setting("Anti Aim Assist", "time")
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10000)
            local aim_state = GetLocalPlayerAimState()

            if aim_state ~= 3 then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Aim Assist " .. aim_state, webhook, time)
            end
        end
    end)
end

ProtectionManager.register_protection("aim_assist", AntiAimAssist.initialize)

return AntiAimAssist