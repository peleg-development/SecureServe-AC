local ProtectionManager = require("client/protections/protection_manager")

local Cache = require("client/core/cache")

---@class AntiInvisibleModule
local AntiInvisible = {alpha_threshold = 50}
local invisibilityDetections = 0

function AntiInvisible.initialize()
    if not ConfigLoader.get_protection_setting("Anti Invisible", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(3000)
            
            if Cache.Get("hasPermission", "invisible") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end

            local ped = Cache.Get("ped")
            if not IsEntityVisible(ped) or GetEntityAlpha(ped) == 0 then
                if
                    HasModelLoaded(joaat("mp_f_freemode_01")) and
                        HasModelLoaded(joaat("mp_m_freemode_01"))
                 then
                    SetEntityVisible(ped, true)
                    ResetEntityAlpha(ped)
                    invisibilityDetections = invisibilityDetections + 1
                    if invisibilityDetections > 4 then
                        invisibilityDetections = 0
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Invisible", webhook, time)
                    end
                end
            end
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("invisible", AntiInvisible.initialize)
return AntiInvisible