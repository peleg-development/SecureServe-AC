local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiInvisible = {
    alpha_threshold = 50,
    max_detections  = 8,
    reset_time      = 60000,
}

local detections = 0
local last_detection_time = 0

function AntiInvisible.initialize()
    if not ConfigLoader.get_protection_setting("Anti Invisible", "enabled") then return end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000)

            local ped = Cache.Get("ped")
            if not ped or not DoesEntityExist(ped) then goto continue end

            local is_exempt = Cache.Get("hasPermission", "invisible")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")

            if is_exempt then
                detections = 0
                goto continue
            end

            local is_ignorable = IsCutscenePlaying()
                or IsPedDeadOrDying(ped, true)
                or IsPlayerSwitchInProgress()
                or NetworkIsInSpectatorMode()
                or (GetEntitySubmergedLevel(ped) > 0.95)

            if is_ignorable then goto continue end

            local visible = IsEntityVisible(ped)
            local alpha   = GetEntityAlpha(ped)

            if not visible or alpha < AntiInvisible.alpha_threshold then
                SetEntityVisible(ped, true, false)
                ResetEntityAlpha(ped)

                if (GetGameTimer() - last_detection_time) > AntiInvisible.reset_time then
                    detections = 0
                end

                detections = detections + 1
                last_detection_time = GetGameTimer()

                if detections > AntiInvisible.max_detections then
                    detections = 0
                    ProtectionHelper.punish("Anti Invisible",
                        ("Anti Invisible (Alpha: %s)"):format(tostring(alpha)))
                end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("invisible", AntiInvisible.initialize)
return AntiInvisible
