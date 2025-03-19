local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class BlacklistedWeaponsModule
local BlacklistedWeapons = {}

---@description Initialize Blacklisted Weapons check
function BlacklistedWeapons.initialize()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(9000)

            local player = Cache.Get("ped")
            local weapon = Cache.Get("selectedWeapon")
            
            for k, v in pairs(SecureServe.Protection.BlacklistedWeapons) do
                if weapon == GetHashKey(v.name) then
                    RemoveWeaponFromPed(player, weapon)
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Blacklisted Weapon (" .. v.name .. ")", v.webhook, v.time)
                end
            end
        end
    end)
end

ProtectionManager.register_protection("blacklisted_weapons", BlacklistedWeapons.initialize)

return BlacklistedWeapons 