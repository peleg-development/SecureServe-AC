local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiAimAssistModule
local AntiAimAssist = {}

---@description 
function AntiAimAssist.initialize()
    if not ConfigLoader.get_protection_setting("Anti Aim Assist", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000) 

            local is_exempt = Cache.Get("hasPermission", "aimassist") or 
                              Cache.Get("hasPermission", "all") or 
                              Cache.Get("isAdmin")

            if not is_exempt then
                SetPlayerTargetingMode(3)

                local aim_state = GetLocalPlayerAimState() 
                
                if aim_state ~= 3 then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", 
                        nil, 
                        "Anti Aim Assist (Mode: " .. tostring(aim_state) .. ")", 
                        webhook, 
                        time
                    )
                end
            end
        end
    end)
end

ProtectionManager.register_protection("aim_assist", AntiAimAssist.initialize)

return AntiAimAssist