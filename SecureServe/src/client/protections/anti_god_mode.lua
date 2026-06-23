local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiGodmode = {}

local STRIKE_LIMIT = 3

local function isExempt()
    return Cache.Get("hasPermission", "godmode")
        or Cache.Get("hasPermission", "all")
        or Cache.Get("isAdmin")
end

local function normalizeVehicleDamage()
    local vehicle = Cache.Get("vehicle")
    if vehicle and DoesEntityExist(vehicle) and not GetEntityCanBeDamaged(vehicle) then
        SetEntityCanBeDamaged(vehicle, true)
    end
end

local function normalizePedProofs(ped)
    -- Fix: GetEntityProofs returns booleans (not 1), so the old == 1 test never matched; we only check bulletProof because SecureServe intentionally sets explosionProof every 5s (false positive otherwise).
    local _, bulletProof = GetEntityProofs(ped)
    if bulletProof then
        SetEntityProofs(ped, false, false, true, false, false, false, false, false)
        return true
    end
    return false
end

local function detectGodmode(ped)
    local detected = false

    normalizeVehicleDamage()

    if not GetEntityCanBeDamaged(ped) then
        SetEntityCanBeDamaged(ped, true)
        detected = true
    end

    if GetPlayerInvincible(PlayerId()) and not IsEntityPositionFrozen(ped) then
        SetEntityInvincible(ped, false)
        SetEntityCanBeDamaged(ped, true)
        detected = true
    end

    -- Fix: the result was ignored, so a detected bulletproof did not count as godmode.
    if normalizePedProofs(ped) then
        detected = true
    end

    return detected
end

function AntiGodmode.initialize()
    if not ConfigLoader.get_protection_setting("Anti Godmode", "enabled") then return end

    Citizen.CreateThread(function()
        local strikes = 0

        while true do
            Citizen.Wait(1000)

            if isExempt() then
                strikes = 0
            else
                local ped = Cache.Get("ped")
                if ped and DoesEntityExist(ped) then
                    if detectGodmode(ped) then
                        strikes = strikes + 1
                        if strikes >= STRIKE_LIMIT then
                            strikes = 0
                            ProtectionHelper.punish("Anti Godmode")
                        end
                    elseif strikes > 0 then
                        strikes = strikes - 1
                    end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("godmode", AntiGodmode.initialize)

return AntiGodmode
