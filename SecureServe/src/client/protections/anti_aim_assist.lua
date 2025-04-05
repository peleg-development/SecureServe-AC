local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiAimAssistModule
local AntiAimAssist = {}

---@description Initialize Anti Aim Assist protection
function AntiAimAssist.initialize()
    if not ConfigLoader.get_protection_setting("Anti Aim Assist", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10000)
            local aim_state = GetLocalPlayerAimState()
            if Cache.Get("hasPermission", "aimassist") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end

            if aim_state ~= 3 then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Aim Assist " .. aim_state, webhook, time)
            end
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("aim_assist", AntiAimAssist.initialize)

return AntiAimAssist