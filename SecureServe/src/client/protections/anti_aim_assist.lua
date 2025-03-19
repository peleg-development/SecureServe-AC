local ProtectionManager = require("client/protections/protection_manager")

---@class AntiAimAssistModule
local AntiAimAssist = {}

---@description Initialize Anti Aim Assist protection
function AntiAimAssist.initialize()
    if not Anti_Aim_Assist_enabled then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10000)
            local aim_state = GetLocalPlayerAimState()

            if aim_state ~= 3 then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Aim Assist " .. aim_state, Anti_Aim_Assist_webhook, Anti_Aim_Assist_time)
            end
        end
    end)
end

ProtectionManager.register_protection("aim_assist", AntiAimAssist.initialize)

return AntiAimAssist 