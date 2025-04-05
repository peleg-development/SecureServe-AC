local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiSuperJumpModule
local AntiSuperJump = {}

---@description Initialize Anti Super Jump protection
function AntiSuperJump.initialize()
    if not ConfigLoader.get_protection_setting("Anti Super Jump", "enabled") then return end
    
    local jump_flags = 0
    local last_height = 0
    local normal_jump_height = 1.2  
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
            
            if Cache.Get("hasPermission", "superjump") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                jump_flags = 0
                goto continue
            end
            
            local ped = Cache.Get("ped")
            local current_pos = Cache.Get("coords")
            
            if Cache.Get("isInVehicle") or Cache.Get("isSwimming") or Cache.Get("isSwimmingUnderWater") then
                last_height = current_pos.z
                goto continue
            end
            
            if IsPedJumping(ped) then
                Citizen.CreateThread(function()
                    local start_z = current_pos.z
                    local max_height = start_z
                    
                    for i = 1, 20 do
                        Citizen.Wait(50)
                        local pos = GetEntityCoords(ped)
                        if pos.z > max_height then
                            max_height = pos.z
                        end
                        
                        if not IsPedJumping(ped) then
                            break
                        end
                    end
                    
                    local jump_height = max_height - start_z
                    
                    if jump_height > normal_jump_height and not IsPedFalling(ped) then
                        jump_flags = jump_flags + 1
                        
                        if jump_flags >= 3 then
                            local webhook = ConfigLoader.get_protection_setting("Anti Super Jump", "webhook") or ""
                            local time = ConfigLoader.get_protection_setting("Anti Super Jump", "time") or 0
                            
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Super Jump", webhook, time)
                            jump_flags = 0
                        end
                    else
                        if jump_flags > 0 then
                            jump_flags = jump_flags - 1
                        end
                    end
                end)
            end
            
            last_height = current_pos.z
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("super_jump", AntiSuperJump.initialize)

return AntiSuperJump 