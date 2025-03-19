local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiFreecamModule
local AntiFreecam = {}

---@description Initialize Anti Freecam protection
function AntiFreecam.initialize()
    if not Anti_Freecam_enabled then return end
    
    Citizen.CreateThread(function()
        local lastCamCoord = nil
        local lastPlayerCoord = nil
        local warnings = 0
        
        while true do
            Citizen.Wait(2000)
            
            if not ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) then
                local playerPed = Cache.Get("ped")
                local playerCoord = Cache.Get("coords")
                local camCoord = GetGameplayCamCoord()
                
                local distance = #(camCoord - playerCoord)
                
                if distance > 15.0 and not IsPedInAnyVehicle(playerPed, false) then
                    if lastCamCoord and lastPlayerCoord then
                        local camMovement = #(camCoord - lastCamCoord)
                        local playerMovement = #(playerCoord - lastPlayerCoord)
                        
                        if camMovement > 0.1 and playerMovement < 0.1 then
                            warnings = warnings + 1
                            
                            if warnings >= 3 then
                                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                                    "Freecam detected - Camera distance: " .. math.floor(distance), 
                                    Anti_Freecam_webhook, 
                                    Anti_Freecam_time)
                                warnings = 0
                            end
                        end
                    end
                else
                    warnings = 0
                end
                
                lastCamCoord = camCoord
                lastPlayerCoord = playerCoord
            end
        end
    end)
end

ProtectionManager.register_protection("freecam", AntiFreecam.initialize)

return AntiFreecam 