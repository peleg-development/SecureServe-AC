local ProtectionManager = require("client/protections/protection_manager")

local Cache = require("client/core/cache")

---@class AntiGiveWeaponModule
local AntiGiveWeapon = {}
local trusted_weapon_expiry = {}
local last_selected_weapon = GetHashKey("WEAPON_UNARMED")
local spoof_detection_count = 0
local TRUST_WINDOW_MS = 15000
local MAX_SPOOF_DETECTIONS = 3

local function is_valid_hash(hash)
    return type(hash) == "number" and hash ~= 0
end

local function is_unarmed(weapon_hash)
    return weapon_hash == GetHashKey("WEAPON_UNARMED")
end

local function is_known_weapon(weapon_hash)
    if not SecureServe or type(SecureServe.Weapons) ~= "table" then
        return false
    end
    return SecureServe.Weapons[weapon_hash] ~= nil
end

local function trust_weapon(weapon_hash)
    if not is_valid_hash(weapon_hash) then return end
    trusted_weapon_expiry[weapon_hash] = GetGameTimer() + TRUST_WINDOW_MS
end

local function is_weapon_trusted(weapon_hash)
    local expires_at = trusted_weapon_expiry[weapon_hash]
    if not expires_at then return false end
    return expires_at > GetGameTimer()
end

local function cleanup_expired_trusts()
    local now = GetGameTimer()
    for weapon_hash, expires_at in pairs(trusted_weapon_expiry) do
        if expires_at <= now then
            trusted_weapon_expiry[weapon_hash] = nil
        end
    end
end

---@description Initialize Anti Give Weapon protection
function AntiGiveWeapon.initialize()
    if not ConfigLoader.get_protection_setting("Anti Give Weapon", "enabled") then return end

    RegisterNetEvent("SecureServe:Weapons:Whitelist", function(data)
        local weapon = data and data.weapon
        local resource = data and data.resource

        if not weapon or not resource then return end

        trust_weapon(weapon)
    end)

    Citizen.CreateThread(function()
        if not SecureServe.Module.ModuleEnabled then return end
        while true do
            Wait(500)
            cleanup_expired_trusts()

            local player_ped = Cache.Get("ped")
            if not player_ped or player_ped <= 0 or not DoesEntityExist(player_ped) then
                goto continue
            end

            local selected_weapon = Cache.Get("selectedWeapon")
            if not is_valid_hash(selected_weapon) then
                goto continue
            end

            if selected_weapon ~= last_selected_weapon then
                if not is_unarmed(selected_weapon) and not HasPedGotWeapon(player_ped, selected_weapon, false) then
                    spoof_detection_count = spoof_detection_count + 1
                else
                    spoof_detection_count = 0
                end
            end

            if spoof_detection_count >= MAX_SPOOF_DETECTIONS then
                TriggerServerEvent(
                    "SecureServe:Server:Methods:PunishPlayer",
                    nil,
                    "Spoof weapon state",
                    webhook,
                    time
                )
                spoof_detection_count = 0
                goto continue
            end

            if not is_unarmed(selected_weapon) and not is_weapon_trusted(selected_weapon) and not is_known_weapon(selected_weapon) then
                -- Unknown weapons are not auto-removed to avoid false positives with custom framework weapons.
            end

            last_selected_weapon = selected_weapon

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("give_weapon", AntiGiveWeapon.initialize)

return AntiGiveWeapon
