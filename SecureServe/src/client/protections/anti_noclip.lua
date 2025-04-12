local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiNoclipModule
local AntiNoclip = {}

---@description Initialize Anti Noclip protection
function AntiNoclip.initialize()
    if not ConfigLoader.get_protection_setting("Anti Noclip", "enabled") then return end
    
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
            
            if Cache.Get("hasPermission", "noclip") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                lastPos = current_pos
                clip_flags = 0
                goto continue
            end
            
            if isInVehicle then
                local vehicle = GetVehiclePedIsIn(Cache.Get("ped"), false)
                if vehicle ~= 0 then
                    local speed = GetEntitySpeed(vehicle) * 3.6 
                    if speed > 50.0 then
                        lastPos = current_pos
                        goto continue
                    end
                end
            end

            if not isInVehicle then
                local distance = #(current_pos - lastPos)
                
                if distance <= teleport_threshold then
                    lastPos = current_pos
                    goto continue
                end
                
                local isFalling = Cache.Get("isFalling")
                local ped = Cache.Get("ped")
                
                if isFalling then
                    clip_flags = 0
                    lastPos = current_pos
                    goto continue
                end
                
                clip_flags = clip_flags + 1
                
                if clip_flags >= 12 then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Noclip", webhook, time)
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