local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")
local ConfigLoader = require("client/core/config_loader")
---@class AntiNoRecoilModule
local AntiNoRecoil = {}

---@description Initialize Anti No Recoil protection
function AntiNoRecoil.initialize()
    if not ConfigLoader.get_protection_setting("Anti No Recoil", "enabled") then return end
    
    local spawn_time = GetGameTimer()
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2500)
            if Cache.Get("hasPermission", "norecoil") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end

            local player_ped = Cache.Get("ped")
            local weapon_hash = Cache.Get("selectedWeapon")
            local recoil = GetWeaponRecoilShakeAmplitude(weapon_hash)
            local focused = IsNuiFocused()

            local has_been_spawned_long_enough = spawn_time and (GetGameTimer() - spawn_time) > 30000
            
            if has_been_spawned_long_enough and weapon_hash and weapon_hash ~= GetHashKey("weapon_unarmed") and not Cache.Get("isInVehicle") then
                if recoil <= 0.0 
                and GetGameplayCamRelativePitch() == 0.0 
                and player_ped ~= nil 
                and weapon_hash ~= -1569615261 
                and not focused 
                and not IsPedArmed(player_ped, 1) 
                and not IsPauseMenuActive() 
                and IsPedShooting(player_ped) then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti No Recoil", webhook, time)
                end
            end
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("no_recoil", AntiNoRecoil.initialize)

return AntiNoRecoil 