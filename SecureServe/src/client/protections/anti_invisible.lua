local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiInvisible = {
    alpha_threshold = 50,
    max_detections  = 8,
    reset_time      = 60000,
    spawn_grace     = 10000,
}

local detections = 0
local last_detection_time = 0
local last_spawn_time = 0
local last_damage_time = 0

AddEventHandler("playerSpawned", function()
    last_spawn_time = GetGameTimer()
    detections = 0
end)

AddEventHandler('gameEventTriggered', function(event, data)
    if event == 'CEventNetworkEntityDamage' then
        local victim = data and data[1]
        if victim and victim == PlayerPedId() then
            last_damage_time = GetGameTimer()
        end
    end
end)

function AntiInvisible.initialize()
    if not ConfigLoader.get_protection_setting("Anti Invisible", "enabled") then return end

    AntiInvisible.alpha_threshold = tonumber(ConfigLoader.get_protection_setting("Anti Invisible", "alpha_threshold")) or AntiInvisible.alpha_threshold
    AntiInvisible.max_detections  = tonumber(ConfigLoader.get_protection_setting("Anti Invisible", "strike_limit"))    or AntiInvisible.max_detections
    AntiInvisible.reset_time      = tonumber(ConfigLoader.get_protection_setting("Anti Invisible", "reset_ms"))        or AntiInvisible.reset_time
    AntiInvisible.spawn_grace     = tonumber(ConfigLoader.get_protection_setting("Anti Invisible", "spawn_grace_ms"))  or AntiInvisible.spawn_grace
    local damage_grace            = tonumber(ConfigLoader.get_protection_setting("Anti Invisible", "damage_grace_ms")) or 3000

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

            local now = GetGameTimer()

            -- Grace periods that legitimately fade the player out.
            if (now - last_spawn_time) < AntiInvisible.spawn_grace then
                goto continue
            end
            if (now - last_damage_time) < damage_grace then
                -- Brief invulnerability flicker after damage.
                goto continue
            end

            local is_ignorable = IsCutscenePlaying()
                or IsPedDeadOrDying(ped, true)
                or IsPlayerSwitchInProgress()
                or NetworkIsInSpectatorMode()
                or IsScreenFadedOut()
                or IsScreenFadingOut()
                or IsScreenFadingIn()
                or IsPlayerTeleportActive()
                or GetIsLoadingScreenActive()
                or (GetEntitySubmergedLevel(ped) > 0.95)
                or IsPedInAnyVehicle(ped, true)

            if is_ignorable then
                if detections > 0 then detections = detections - 1 end
                goto continue
            end

            local visible = IsEntityVisible(ped)
            local alpha   = GetEntityAlpha(ped)

            if not visible or alpha < AntiInvisible.alpha_threshold then
                if (GetGameTimer() - last_detection_time) > AntiInvisible.reset_time then
                    detections = 0
                end

                detections = detections + 1
                last_detection_time = GetGameTimer()

                if detections > AntiInvisible.max_detections then
                    detections = 0
                    ProtectionHelper.punish("Anti Invisible",
                        ("Anti Invisible (Alpha: %s, Visible: %s)"):format(tostring(alpha), tostring(visible)))
                end
            else
                if detections > 0 then detections = detections - 1 end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("invisible", AntiInvisible.initialize)
return AntiInvisible
