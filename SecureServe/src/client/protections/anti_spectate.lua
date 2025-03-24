local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")

---@class AntiSpectateModule
local AntiSpectate = {}

---@description Initialize Anti Spectate protection
function AntiSpectate.initialize()
    if not Anti_Spectate_enabled then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
            
            if not ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) then
                if NetworkIsInSpectatorMode() then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                        "Spectating players detected", 
                        Anti_Spectate_webhook, 
                        Anti_Spectate_time)
                end
            end
        end
    end)
end

ProtectionManager.register_protection("spectate", AntiSpectate.initialize)

return AntiSpectate 