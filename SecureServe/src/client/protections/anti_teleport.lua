local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiTeleportModule
local AntiTeleport = {}

---@description Initialize Anti Teleport protection
function AntiTeleport.initialize()
    if not ConfigLoader.get_protection_setting("Anti Teleport", "enabled") then return end
    
    local lastPos = vector3(0, 0, 0)
    local teleport_threshold = 150.0
    local teleport_flags = 0
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
            
            if lastPos == vector3(0, 0, 0) then
                lastPos = current_pos
                goto continue
            end
            
            local distance = #(current_pos - lastPos)
            
            if distance <= teleport_threshold or Cache.Get("hasPermission", "teleport") or Cache.Get("isAdmin") then
                lastPos = current_pos
                goto continue
            end
            
            local ped = Cache.Get("ped")
            if Cache.Get("isFalling") or 
               IsPedInParachuteFreeFall(ped) or 
               IsPedRagdoll(ped) or 
               Cache.Get("isSwimming") or
               Cache.Get("isSwimmingUnderWater") then
                teleport_flags = 0
                lastPos = current_pos
                goto continue
            end
            
            teleport_flags = teleport_flags + 1
            
            if teleport_flags >= 3 then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Teleport", webhook, time)
                teleport_flags = 0
            end
            
            lastPos = current_pos
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("teleport", AntiTeleport.initialize)

return AntiTeleport 