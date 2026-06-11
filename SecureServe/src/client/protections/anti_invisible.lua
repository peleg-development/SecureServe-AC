local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiInvisible = {
    alphaThreshold = 50,
    maxDetections  = 8,
    resetTime      = 60000,
}

local function isExempt()
    return Cache.Get("hasPermission", "invisible")
        or Cache.Get("hasPermission", "all")
        or Cache.Get("isAdmin")
end

local function shouldIgnore(ped)
    return IsCutscenePlaying()
        or IsPedDeadOrDying(ped, true)
        or IsPlayerSwitchInProgress()
        or NetworkIsInSpectatorMode()
        or GetEntitySubmergedLevel(ped) > 0.95
end

function AntiInvisible.initialize()
    if not ConfigLoader.get_protection_setting("Anti Invisible", "enabled") then return end

    Citizen.CreateThread(function()
        local detections = 0
        local lastDetectionAt = 0

        while true do
            Citizen.Wait(2000)

            local ped = Cache.Get("ped")
            if not ped or not DoesEntityExist(ped) then
                detections = 0
            elseif isExempt() then
                detections = 0
            elseif not shouldIgnore(ped) then
                local visible = IsEntityVisible(ped)
                local alpha = GetEntityAlpha(ped)

                if not visible or alpha < AntiInvisible.alphaThreshold then
                    SetEntityVisible(ped, true, false)
                    ResetEntityAlpha(ped)

                    if (GetGameTimer() - lastDetectionAt) > AntiInvisible.resetTime then
                        detections = 0
                    end

                    detections = detections + 1
                    lastDetectionAt = GetGameTimer()

                    if detections > AntiInvisible.maxDetections then
                        detections = 0
                        ProtectionHelper.punish(
                            "Anti Invisible",
                            ("Anti Invisible (Alpha: %s)"):format(tostring(alpha))
                        )
                    end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("invisible", AntiInvisible.initialize)

return AntiInvisible
