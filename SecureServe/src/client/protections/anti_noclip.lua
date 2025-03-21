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
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)

            local current_pos = Cache.Get("coords")
            if not Cache.Get("isInVehicle") then
                local distance = #(current_pos - lastPos)
                if distance > teleport_threshold and 
                   not Cache.Get("isFalling") and 
                   not IsPedRagdoll(Cache.Get("ped")) and
                   not Cache.Get("isSwimming") and
                   not Cache.Get("isSwimmingUnderWater") then
        
                    clip_flags = clip_flags + 1
                    print(ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())))
                    if clip_flags >= 12 and not ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Noclip", Anti_Noclip_webhook, Anti_Noclip_time)
                        clip_flags = 0
                    end
                end
            else
                clip_flags = 0
            end
            
            lastPos = current_pos
        end
    end)
end

ProtectionManager.register_protection("noclip", AntiNoclip.initialize)

return AntiNoclip 