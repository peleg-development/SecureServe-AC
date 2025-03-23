local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiFreecamModule
local AntiFreecam = {
    last_check_time = 0,
    suspicious_activity = 0,
    warning_threshold = 5, 
    cam_history = {},
    history_size = 5,
    last_detection_time = 0,
    cooldown = 60000
}

---@description Initialize Anti Freecam protection
function AntiFreecam.initialize()
    if not Anti_Freecam_enabled then return end
    
    Citizen.CreateThread(function()
        local lastCamCoord = nil
        local lastPlayerCoord = nil
        
        while true do
            Citizen.Wait(2500) 
            
            local playerPed = Cache.Get("ped")
            local playerCoord = Cache.Get("coords")
            local camCoord = GetGameplayCamCoord()
            local current_time = GetGameTimer()
            
            if ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) then
                goto continue
            end
            
            if (current_time - AntiFreecam.last_detection_time) < AntiFreecam.cooldown then
                AntiFreecam.suspicious_activity = 0
                goto continue
            end
            
            table.insert(AntiFreecam.cam_history, {
                cam = camCoord,
                player = playerCoord,
                time = current_time
            })
            
            if #AntiFreecam.cam_history > AntiFreecam.history_size then
                table.remove(AntiFreecam.cam_history, 1)
            end

            if IsCutsceneActive() or IsPlayerSwitchInProgress() or IsPauseMenuActive() then
                AntiFreecam.suspicious_activity = 0
                goto continue
            end
            
            if IsPedInAnyVehicle(playerPed, false) then
                AntiFreecam.suspicious_activity = 0
                goto continue
            end
            
            local distance = #(camCoord - playerCoord)
            
            local distance_threshold = 20.0 
            
            if GetInteriorFromEntity(playerPed) ~= 0 then
                distance_threshold = 10.0
            end
            
            if #AntiFreecam.cam_history >= 3 then
                local newest = AntiFreecam.cam_history[#AntiFreecam.cam_history]
                local oldest = AntiFreecam.cam_history[#AntiFreecam.cam_history - 2]
                
                local cam_movement = #(newest.cam - oldest.cam)
                local player_movement = #(newest.player - oldest.player)
                local time_diff = newest.time - oldest.time
                
                if distance > distance_threshold and cam_movement > 3.0 and player_movement < 0.5 then
                    if not IsFirstPersonAimCamActive() then
                        AntiFreecam.suspicious_activity = AntiFreecam.suspicious_activity + 1
                    end
                    
                    if AntiFreecam.suspicious_activity >= AntiFreecam.warning_threshold then
                        local detection_info = string.format(
                            "Freecam detected - Distance: %.1f, Cam movement: %.1f, Player movement: %.1f",
                            distance, cam_movement, player_movement
                        )
                        
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                            detection_info, 
                            Anti_Freecam_webhook, 
                            2147483647) 
                        
                        AntiFreecam.suspicious_activity = 0
                        AntiFreecam.last_detection_time = current_time
                    end
                else
                    if AntiFreecam.suspicious_activity > 0 then
                        AntiFreecam.suspicious_activity = AntiFreecam.suspicious_activity - 0.5
                    end
                end
            end
                     
            lastCamCoord = camCoord
            lastPlayerCoord = playerCoord

            ::continue::
        end
    end)
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2500) 
            
            if ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) then
                goto continue
            end
            
            local playerPed = Cache.Get("ped")
            local playerCoord = Cache.Get("coords")
            local camCoord = GetGameplayCamCoord()
            
            if IsCutsceneActive() or IsPlayerSwitchInProgress() or IsPauseMenuActive() then
                goto continue
            end
            
            local ray = StartShapeTestRay(playerCoord.x, playerCoord.y, playerCoord.z, camCoord.x, camCoord.y, camCoord.z, -1, playerPed, 0)
            local _, hit, endCoords, _, _ = GetShapeTestResult(ray)
            
            if hit == 1 then
                local obstacle_distance = #(playerCoord - endCoords)
                local cam_distance = #(playerCoord - camCoord)
                
                if obstacle_distance < cam_distance and cam_distance > 10.0 and not IsPedInAnyVehicle(playerPed, false) then
                    local playerInterior = GetInteriorFromEntity(playerPed)
                    local camInterior = GetInteriorAtCoords(camCoord.x, camCoord.y, camCoord.z)
                    
                    if playerInterior ~= 0 and camInterior ~= playerInterior then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                            "Freecam detected - Camera through walls: Player interior " .. playerInterior .. ", Camera interior " .. camInterior, 
                            Anti_Freecam_webhook, 
                            2147483647) 
                    end
                end
            end
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("freecam", AntiFreecam.initialize)

return AntiFreecam 

