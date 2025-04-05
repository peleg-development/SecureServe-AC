local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiInfiniteStaminaModule
local AntiInfiniteStamina = {}

---@description Initialize Anti Infinite Stamina protection
function AntiInfiniteStamina.initialize()
    if not ConfigLoader.get_protection_setting("Anti Infinite Stamina", "enabled") then return end
    
    local stamina_flags = 0
    local consecutive_checks = 0
    local sprint_start_time = 0
    local SPRINT_THRESHOLD = 15000 
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000)
            
            if Cache.Get("hasPermission", "infinitestamina") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                stamina_flags = 0
                consecutive_checks = 0
                sprint_start_time = 0
                goto continue
            end
            
            local ped = Cache.Get("ped")
            
            if Cache.Get("isInVehicle") or Cache.Get("isSwimming") or Cache.Get("isSwimmingUnderWater") then
                sprint_start_time = 0
                consecutive_checks = 0
                goto continue
            end
            
            if IsPedSprinting(ped) then
                if sprint_start_time == 0 then
                    sprint_start_time = GetGameTimer()
                end
                
                local sprint_duration = GetGameTimer() - sprint_start_time
                
                local stamina = GetPlayerSprintStaminaRemaining(PlayerId())
                
                if sprint_duration > SPRINT_THRESHOLD and stamina > 80 then
                    consecutive_checks = consecutive_checks + 1
                    
                    if consecutive_checks >= 3 then
                        stamina_flags = stamina_flags + 1
                        
                        if stamina_flags >= 3 then
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Infinite Stamina", webhook, time)
                            stamina_flags = 0
                            consecutive_checks = 0
                            sprint_start_time = 0
                        end
                    end
                else
                    consecutive_checks = 0
                end
            else
                sprint_start_time = 0
                consecutive_checks = 0
                
                if stamina_flags > 0 then
                    stamina_flags = stamina_flags - 1
                end
            end
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("infinite_stamina", AntiInfiniteStamina.initialize)

return AntiInfiniteStamina 