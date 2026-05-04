local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiNoReload = {}

function AntiNoReload.initialize()
    if not ConfigLoader.get_protection_setting("Anti No Reload", "enabled") then return end

    Citizen.CreateThread(function()
        local last_ammo_count = nil
        local last_weapon = nil
        local warns = 0

        while true do
            Citizen.Wait(150)

            if Cache.Get("hasPermission", "noreload")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                warns = 0
                last_ammo_count = nil
                last_weapon = nil
                goto continue
            end

            local player_ped = Cache.Get("ped")
            if not player_ped or not DoesEntityExist(player_ped) then
                goto continue
            end

            local weapon_hash = Cache.Get("selectedWeapon")
            local weapon_group = GetWeapontypeGroup(weapon_hash)

            if weapon_hash == GetHashKey("WEAPON_UNARMED")
                or weapon_group == GetHashKey("WEAPON_GROUP_MELEE")
                or weapon_group == GetHashKey("WEAPON_GROUP_THROWN")
                or weapon_group == GetHashKey("WEAPON_GROUP_FIREEXTINGUISHER")
                or weapon_group == GetHashKey("WEAPON_GROUP_PETROLCAN")
            then
                warns = 0
                last_ammo_count = nil
                last_weapon = nil
                goto continue
            end

            if last_weapon and last_weapon ~= weapon_hash then
                warns = 0
                last_ammo_count = nil
                last_weapon = weapon_hash
                goto continue
            end

            if IsPedWeaponReadyToShoot(player_ped) and IsPedShooting(player_ped) then
                local current_ammo_count = GetAmmoInPedWeapon(player_ped, weapon_hash)

                if last_ammo_count and last_ammo_count == current_ammo_count then
                    warns = warns + 1
                    if warns >= 15 then
                        ProtectionHelper.punish('Anti No Reload', "Player tried to NoReload/infinite ammo")
                        warns = 0
                    end
                else
                    if warns > 0 then warns = warns - 1 end
                end

                last_ammo_count = current_ammo_count
                last_weapon = weapon_hash
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("no_reload", AntiNoReload.initialize)

return AntiNoReload
