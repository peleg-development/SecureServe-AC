local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiNoRecoil = {
    max_detections   = 8,
    min_recoil_value = 0.05,
}

local WhitelistedWeaponsRaw = {
    "WEAPON_UNARMED",
    "WEAPON_STUNGUN",
    "WEAPON_FIREEXTINGUISHER",
    "WEAPON_PETROLCAN",
    "WEAPON_SNIPERRIFLE",
    "WEAPON_HEAVYSNIPER",
    "WEAPON_HEAVYSNIPER_MK2",
    "WEAPON_MARKSMANRIFLE",
    "WEAPON_MARKSMANRIFLE_MK2",
    "WEAPON_RPG",
    "WEAPON_HOMINGLAUNCHER",
    "WEAPON_GRENADELAUNCHER",
    "WEAPON_GRENADELAUNCHER_SMOKE",
    "WEAPON_COMPACTLAUNCHER",
    "WEAPON_FLAREGUN",
    "WEAPON_RAILGUN",
    "WEAPON_MINIGUN",
    "WEAPON_FIREWORK",
}

local WhitelistedWeapons = {}

local function add_to_whitelist(name)
    if type(name) ~= "string" then return end
    local hash = GetHashKey(name)
    if type(IsWeaponValid) == "function" and not IsWeaponValid(hash) then
        return
    end
    WhitelistedWeapons[hash] = true
end

for _, name in ipairs(WhitelistedWeaponsRaw) do add_to_whitelist(name) end

local function load_extra_whitelist()
    if SecureServe and SecureServe.Protection and SecureServe.Protection.NoRecoilWhitelist then
        for _, name in ipairs(SecureServe.Protection.NoRecoilWhitelist) do
            add_to_whitelist(name)
        end
    end
end

function AntiNoRecoil.initialize()
    if not ConfigLoader.get_protection_setting("Anti No Recoil", "enabled") then return end

    load_extra_whitelist()

    local detections = 0

    Citizen.CreateThread(function()
        while true do
            local sleep = 1000
            local player_ped = Cache.Get("ped")

            if player_ped and DoesEntityExist(player_ped) and IsPedShooting(player_ped) then
                sleep = 250

                local is_exempt = Cache.Get("hasPermission", "norecoil")
                    or Cache.Get("hasPermission", "all")
                    or Cache.Get("isAdmin")

                if not is_exempt and not Cache.Get("isInVehicle") then
                    local weapon_hash = Cache.Get("selectedWeapon")

                    if weapon_hash and not WhitelistedWeapons[weapon_hash] then
                        local recoil_shake = GetWeaponRecoilShakeAmplitude(weapon_hash)

                        if recoil_shake < AntiNoRecoil.min_recoil_value then
                            detections = detections + 1
                            if detections > AntiNoRecoil.max_detections then
                                ProtectionHelper.punish('Anti No Recoil',
                                    ("Anti No Recoil (Shake: %.2f)"):format(recoil_shake))
                                detections = 0
                            end
                        else
                            if detections > 0 then detections = detections - 1 end
                        end
                    end
                end
            else
                if detections > 0 then detections = detections - 1 end
            end

            Citizen.Wait(sleep)
        end
    end)
end

ProtectionManager.register_protection("no_recoil", AntiNoRecoil.initialize)

return AntiNoRecoil
