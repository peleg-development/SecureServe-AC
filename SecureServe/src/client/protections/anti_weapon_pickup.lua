local ProtectionManager = require("client/protections/protection_manager")
local Cache             = require("client/core/cache")

---@class AntiWeaponPickupModule
local AntiWeaponPickup = {}

-- Build the lookup of forbidden weapon hashes from config. Anything in
-- BlacklistedWeapons is auto-removed if the player picks it up.
local function build_blacklist_lookup()
    local out = {}
    if SecureServe and SecureServe.Protection and SecureServe.Protection.BlacklistedWeapons then
        for _, entry in ipairs(SecureServe.Protection.BlacklistedWeapons) do
            if entry and entry.name then
                out[GetHashKey(entry.name)] = true
            end
        end
    end
    return out
end

---@description Initialize Anti Weapon Pickup protection
--
-- Older versions of this protection used to spam:
--   GiveWeaponToPed(ped, WEAPON_UNARMED, ...)  -> useless
--   RemoveAllPickupsOfType(PICKUP_HEALTH_*/ARMOUR_*) -> wiped pickups
--                                                      from legitimate scripts
-- That has been removed. Now we only strip blacklisted weapons that the
-- player ends up carrying (pickup, give event, etc).
function AntiWeaponPickup.initialize()
    if not ConfigLoader.get_protection_setting("Anti Weapon Pickup", "enabled") then return end

    local blacklist = build_blacklist_lookup()
    if not next(blacklist) then return end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000)

            local ped = Cache.Get("ped")
            if ped and DoesEntityExist(ped) then
                for weapon_hash in pairs(blacklist) do
                    if HasPedGotWeapon(ped, weapon_hash, false) then
                        RemoveWeaponFromPed(ped, weapon_hash)
                    end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("weapon_pickup", AntiWeaponPickup.initialize)

return AntiWeaponPickup
