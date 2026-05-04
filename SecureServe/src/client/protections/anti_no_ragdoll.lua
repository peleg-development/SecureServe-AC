local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")

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
            if not ped or not DoesEntityExist(ped) then goto continue end
            
            if Cache.Get("isInVehicle") then
                ragdoll_flags = 0
                goto continue
            end

            local in_anim = IsEntityPlayingAnim(ped, "anim@heists@", "", 3)
                or GetIsTaskActive(ped, 152)
                or GetIsTaskActive(ped, 151)
                or IsPedUsingAnyScenario(ped)
                or IsPedInCover(ped, false)
                or IsPedRagdoll(ped)

            if in_anim then
                ragdoll_flags = 0
                goto continue
            end

            if not CanPedRagdoll(ped) then
                ragdoll_flags = ragdoll_flags + 1
                
                if ragdoll_flags >= 6 then
                    ProtectionHelper.punish('Anti No Ragdoll', "Anti No Ragdoll")
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