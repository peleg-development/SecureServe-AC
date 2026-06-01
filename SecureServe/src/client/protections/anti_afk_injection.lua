local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

---@class AntiAfkInjectionModule
local AntiAfkInjection = {}

-- AFK-injection task ids (forced animations / sit-on-chair / use scenarios) that
-- some menus trigger remotely to lock a player into a long animation.
local AFK_TASKS = { 100, 101, 151, 221, 222 }

---@description Initialize Anti AFK Injection protection
function AntiAfkInjection.initialize()
    if not ConfigLoader.get_protection_setting("Anti AFK Injection", "enabled") then return end

    Citizen.CreateThread(function()
        local strikes = 0
        local STRIKE_LIMIT = tonumber(ConfigLoader.get_protection_setting("Anti AFK Injection", "strike_limit")) or 3
        local INTERVAL     = tonumber(ConfigLoader.get_protection_setting("Anti AFK Injection", "check_interval_ms")) or 5000

        while true do
            Citizen.Wait(INTERVAL)

            if Cache.Get("hasPermission", "afkinjection")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                strikes = 0
                goto continue
            end

            local ped = Cache.Get("ped")
            if not ped or not DoesEntityExist(ped) then goto continue end

            -- Ignore legitimate cases: scripted scenarios the user voluntarily
            -- triggered (sit, lean), being in a vehicle, in cutscene, etc.
            if Cache.Get("isInVehicle")
                or IsPedUsingAnyScenario(ped)
                or IsPedInCover(ped, false)
                or IsCutscenePlaying()
                or IsPedRagdoll(ped)
            then
                strikes = 0
                goto continue
            end

            local detected = false
            for i = 1, #AFK_TASKS do
                if GetIsTaskActive(ped, AFK_TASKS[i]) then
                    detected = true
                    break
                end
            end

            if detected then
                strikes = strikes + 1
                if strikes >= STRIKE_LIMIT then
                    strikes = 0
                    ProtectionHelper.punish('Anti AFK Injection', "Anti AFK Injection")
                end
            else
                if strikes > 0 then strikes = strikes - 1 end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("afk_injection", AntiAfkInjection.initialize)

return AntiAfkInjection
