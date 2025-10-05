local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiGodmodeModule
local AntiGodmode = {}

local detectedTimes = 0

function AntiGodmode.initialize()
    if not ConfigLoader.get_protection_setting("Anti Godmode", "enabled") then return end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)

            if Cache.Get("hasPermission", "godmode") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end

            local ped = Cache.Get("ped")
            local vehicle = Cache.Get("vehicle")

            if vehicle then
                if not GetEntityCanBeDamaged(vehicle) then
                    SetEntityCanBeDamaged(vehicle, true)
                end
            end

            if not GetEntityCanBeDamaged(ped) then
                SetEntityCanBeDamaged(ped, true)
                detectedTimes = detectedTimes + 1
                if detectedTimes > 3 then
                    detectedTimes = 0
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Godmode", webhook, time)
                end
            end

            if (GetPlayerInvincible(PlayerId()) or GetPlayerInvincible_2(PlayerId())) and not IsEntityPositionFrozen(ped) then
                SetEntityInvincible(ped, false)
                SetEntityCanBeDamaged(ped, true)
                detectedTimes = detectedTimes + 1
                if detectedTimes > 3 then
                    detectedTimes = 0
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Godmode", webhook, time)
                end
            end


            
            local bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, p7, drownProof =
            GetEntityProofs(ped)
            if fireProof == 1 or explosionProof == 1 or steamProof == 1 or p7 == 1 or drownProof == 1 then
                SetEntityProofs(ped, false, false, false, false, false, false, false, false)
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("godmode", AntiGodmode.initialize)
return AntiGodmode
