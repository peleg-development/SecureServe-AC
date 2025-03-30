local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiNoclipModule
local AntiNoclip = {}

---@description Initialize Anti Noclip protection
function AntiNoclip.initialize()
    if not Anti_Noclip_enabled then return end
    
    local lastPos = vector3(0, 0, 0)
    local teleport_threshold = 16.0
    local clip_flags = 0
    local lastCheckTime = 0
    local CHECK_INTERVAL = 1500 
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(CHECK_INTERVAL)
            
            local currentTime = GetGameTimer()
            if currentTime - lastCheckTime < CHECK_INTERVAL then
                Citizen.Wait(CHECK_INTERVAL - (currentTime - lastCheckTime))
                goto continue
            end
            
            lastCheckTime = currentTime
            
            local current_pos = Cache.Get("coords")
            local isInVehicle = Cache.Get("isInVehicle")
            
            if not isInVehicle then
                local distance = #(current_pos - lastPos)
                
                if distance <= teleport_threshold then
                    lastPos = current_pos
                    goto continue
                end
                
                local isFalling = Cache.Get("isFalling")
                local ped = Cache.Get("ped")
                
                if isFalling or 
                   IsPedRagdoll(ped) or 
                   Cache.Get("isSwimming") or
                   Cache.Get("isSwimmingUnderWater") then
                    clip_flags = 0
                    lastPos = current_pos
                    goto continue
                end
                
                clip_flags = clip_flags + 1
                
                if clip_flags >= 7 and not Cache.Get("isAdmin") then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Noclip", Anti_Noclip_webhook, Anti_Noclip_time)
                    clip_flags = 0
                end
            else
                clip_flags = 0
            end
            
            lastPos = current_pos
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("noclip", AntiNoclip.initialize)

return AntiNoclip 