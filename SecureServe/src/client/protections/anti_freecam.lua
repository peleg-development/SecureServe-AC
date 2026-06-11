local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache = require("client/core/cache")

---@class AntiFreecamModule
local AntiFreecam = {}

-- Fix: module was previously empty (no detection). We detect the gameplay camera being detached from the player, a classic freecam sign.
local STRIKE_LIMIT      = 4
local MAX_CAM_DISTANCE  = 30.0

local function isExempt()
    return Cache.Get("hasPermission", "freecam")
        or Cache.Get("hasPermission", "all")
        or Cache.Get("isAdmin")
        or Cache.Get("isInVehicle")            -- large vehicles can move the camera far away: avoid the false positive
        or NetworkIsInSpectatorMode()
        or IsPlayerDead(PlayerId())
        or (IsCutsceneActive and IsCutsceneActive())
        or (IsScreenFadedOut and IsScreenFadedOut())
end

function AntiFreecam.initialize()
    if not ConfigLoader.get_protection_setting("Anti Freecam", "enabled") then return end

    Citizen.CreateThread(function()
        -- Fix: strike system to avoid banning on a single transient spike (spawn, scripted camera transition).
        local strikes = 0

        while true do
            Citizen.Wait(1500)

            local ped = Cache.Get("ped")
            if ped and DoesEntityExist(ped) and not isExempt() then
                local distance = #(GetGameplayCamCoord() - GetEntityCoords(ped))

                if distance > MAX_CAM_DISTANCE then
                    strikes = strikes + 1
                    if strikes >= STRIKE_LIMIT then
                        strikes = 0
                        ProtectionHelper.punish('Anti Freecam',
                            ("Anti Freecam (Cam dist: %.1f)"):format(distance))
                    end
                elseif strikes > 0 then
                    strikes = strikes - 1
                end
            elseif strikes > 0 then
                strikes = strikes - 1
            end
        end
    end)
end

ProtectionManager.register_protection("freecam", AntiFreecam.initialize)
return AntiFreecam
