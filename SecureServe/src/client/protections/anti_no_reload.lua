local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiNoReload = {}

-- Weapons whose ammo doesn't decrement on every shot (or that are single-shot
-- bolt-action / break-action). We MUST skip them in the no-reload heuristic
-- otherwise legitimate semi-auto fire flags strikes.
--
-- Note: WEAPON_MARKSMANPISTOL doesn't exist in vanilla GTA V; if you ever
-- need it add it via the config-level extension below. Each entry is
-- validated with IsWeaponValid so dead hashes don't poison the table.
local SemiAutoWhitelistRaw = {
    "WEAPON_SNIPERRIFLE",
    "WEAPON_HEAVYSNIPER",
    "WEAPON_HEAVYSNIPER_MK2",
    "WEAPON_MARKSMANRIFLE",
    "WEAPON_MARKSMANRIFLE_MK2",
    "WEAPON_PUMPSHOTGUN",
    "WEAPON_PUMPSHOTGUN_MK2",
    "WEAPON_SAWNOFFSHOTGUN",
    "WEAPON_DBSHOTGUN",
    "WEAPON_MUSKET",
    "WEAPON_FLAREGUN",
    "WEAPON_RAILGUN",
    "WEAPON_RPG",
    "WEAPON_HOMINGLAUNCHER",
    "WEAPON_GRENADELAUNCHER",
    "WEAPON_FIREWORK",
    "WEAPON_COMPACTLAUNCHER",
}

local SemiAutoWhitelist = {}

local function build_whitelist()
    for _, name in ipairs(SemiAutoWhitelistRaw) do
        local hash = GetHashKey(name)
        -- IsWeaponValid may not exist on every build; guard it.
        local valid = true
        if type(IsWeaponValid) == "function" then
            valid = IsWeaponValid(hash)
        end
        if valid then
            SemiAutoWhitelist[hash] = true
        end
    end

    -- Optional config-level extension.
    if SecureServe and SecureServe.Protection and SecureServe.Protection.NoReloadWhitelist then
        for _, name in ipairs(SecureServe.Protection.NoReloadWhitelist) do
            if type(name) == "string" then
                local h = GetHashKey(name)
                if type(IsWeaponValid) ~= "function" or IsWeaponValid(h) then
                    SemiAutoWhitelist[h] = true
                end
            end
        end
    end
end

build_whitelist()

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
                or SemiAutoWhitelist[weapon_hash]
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
                    if warns >= 30 then
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
