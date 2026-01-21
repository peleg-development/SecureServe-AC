local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiInvisibleModule
local AntiInvisible = {
    alpha_threshold = 50,
    max_detections = 4,
    reset_time = 60 
}

local detections = 0
local last_detection_time = 0

function AntiInvisible.initialize()
    if not ConfigLoader.get_protection_setting("Anti Invisible", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000) 
            
            local ped = Cache.Get("ped")
            local is_exempt = Cache.Get("hasPermission", "invisible") or 
                              Cache.Get("hasPermission", "all") or 
                              Cache.Get("isAdmin")

            local is_ignorable = IsCutscenePlaying() or 
                                 IsPedDeadOrDying(ped, 1) or 
                                 IsPlayerSwitchInProgress()

            if not is_exempt and not is_ignorable then
                
                if not IsEntityVisible(ped) or GetEntityAlpha(ped) < AntiInvisible.alpha_threshold then
                    
                    SetEntityVisible(ped, true, 0)
                    ResetEntityAlpha(ped)

                    if (GetGameTimer() - last_detection_time) > AntiInvisible.reset_time then
                        detections = 0 
                    end

                    detections = detections + 1
                    last_detection_time = GetGameTimer()

                    if detections > AntiInvisible.max_detections then
                        detections = 0
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", 
                            nil, 
                            "Anti Invisible (Alpha: " .. GetEntityAlpha(ped) .. ")", 
                            webhook, 
                           time
                        )
                    end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("invisible", AntiInvisible.initialize)
return AntiInvisible