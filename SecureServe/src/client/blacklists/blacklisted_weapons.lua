local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class BlacklistedWeaponsModule
local BlacklistedWeapons = {}

---@description Initialize Blacklisted Weapons check
function BlacklistedWeapons.initialize()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(4000)

            local player = Cache.Get("ped")
            local weapon = Cache.Get("selectedWeapon")
            
            for k, v in pairs(SecureServe.Protection.BlacklistedWeapons) do
                if weapon == GetHashKey(v.name) then
                    RemoveWeaponFromPed(player, weapon)
                end
            end
        end
    end)
end

ProtectionManager.register_protection("blacklisted_weapons", BlacklistedWeapons.initialize)

return BlacklistedWeapons 