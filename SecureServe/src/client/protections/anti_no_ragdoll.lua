local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiNoRagdollModule
local AntiNoRagdoll = {}

---@description Initialize Anti No Ragdoll protection
function AntiNoRagdoll.initialize()
    if not ConfigLoader.get_protection_setting("Anti No Ragdoll", "enabled") then return end
    
    local ragdoll_flags = 0
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5000)  
            
            if Cache.Get("hasPermission", "noragdoll") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                ragdoll_flags = 0
                goto continue
            end
            
            local ped = Cache.Get("ped")
            
            if Cache.Get("isInVehicle") then
                ragdoll_flags = 0
                goto continue
            end
            
            if not CanPedRagdoll(ped) then
                ragdoll_flags = ragdoll_flags + 1
                
                if ragdoll_flags >= 3 then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti No Ragdoll", webhook, time)
                    ragdoll_flags = 0
                    
                    SetPedCanRagdoll(ped, true)
                end
            else
                if ragdoll_flags > 0 then
                    ragdoll_flags = ragdoll_flags - 1
                end
            end
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("no_ragdoll", AntiNoRagdoll.initialize)

return AntiNoRagdoll 