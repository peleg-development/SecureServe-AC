local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiNoRecoil = {
    max_detections   = 8,
    min_recoil_value = 0.05,
}

local WhitelistedWeapons = {
    [GetHashKey("WEAPON_UNARMED")]            = true,
    [GetHashKey("WEAPON_STUNGUN")]            = true,
    [GetHashKey("WEAPON_FIREEXTINGUISHER")]   = true,
    [GetHashKey("WEAPON_PETROLCAN")]          = true,
    [GetHashKey("WEAPON_SNIPERRIFLE")]        = true,
    [GetHashKey("WEAPON_HEAVYSNIPER")]        = true,
    [GetHashKey("WEAPON_HEAVYSNIPER_MK2")]    = true,
    [GetHashKey("WEAPON_MARKSMANRIFLE")]      = true,
    [GetHashKey("WEAPON_MARKSMANRIFLE_MK2")]  = true,
    [GetHashKey("WEAPON_RPG")]                = true,
    [GetHashKey("WEAPON_HOMINGLAUNCHER")]     = true,
    [GetHashKey("WEAPON_GRENADELAUNCHER")]    = true,
    [GetHashKey("WEAPON_GRENADELAUNCHER_SMOKE")] = true,
    [GetHashKey("WEAPON_FLAREGUN")]           = true,
    [GetHashKey("WEAPON_RAILGUN")]            = true,
    [GetHashKey("WEAPON_MINIGUN")]            = true,
    [GetHashKey("WEAPON_FIREWORK")]           = true,
}

function AntiNoRecoil.initialize()
    if not ConfigLoader.get_protection_setting("Anti No Recoil", "enabled") then return end

    local detections = 0
    -- Fix: we remember the max recoil already observed per weapon so we only flag it dropping to zero (real signature), instead of an absolute threshold that banned low-recoil weapons.
    local seen_amplitude = {}

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

                    -- Fix: guarded call because the native may be absent depending on the build (otherwise error and dead thread).
                    local recoil_shake = GetWeaponRecoilShakeAmplitude and GetWeaponRecoilShakeAmplitude(weapon_hash)

                    if weapon_hash and not WhitelistedWeapons[weapon_hash] and type(recoil_shake) == "number" then
                        local baseline = seen_amplitude[weapon_hash] or 0.0
                        if recoil_shake > baseline then
                            seen_amplitude[weapon_hash] = recoil_shake
                            baseline = recoil_shake
                        end

                        -- Fix: we only punish if the weapon clearly had recoil then drops to zero (tampering), never on a legitimately low value.
                        if baseline > AntiNoRecoil.min_recoil_value and recoil_shake <= 0.0 then
                            detections = detections + 1
                            if detections > AntiNoRecoil.max_detections then
                                ProtectionHelper.punish('Anti No Recoil',
                                    ("Anti No Recoil (Shake: %.2f, Baseline: %.2f)"):format(recoil_shake, baseline))
                                detections = 0
                            end
                        elseif detections > 0 then
                            detections = detections - 1
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
