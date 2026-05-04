local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiTeleport = {}

local last_spawn_time = 0
local last_death_time = 0

function AntiTeleport.initialize()
    if not ConfigLoader.get_protection_setting("Anti Teleport", "enabled") then
        return
    end

    AddEventHandler("playerSpawned", function()
        last_spawn_time = GetGameTimer()
    end)

    AddEventHandler('gameEventTriggered', function(event, data)
        if event == 'CEventNetworkEntityDamage' then
            local victim, victim_died = data[1], data[4]
            if victim == PlayerPedId() and victim_died then
                last_death_time = GetGameTimer()
            end
        end
    end)

    Citizen.CreateThread(function()
        local last_pos = nil
        local strikes = 0
        local STRIKE_LIMIT = 2
        local SPAWN_GRACE = 10000

        while true do
            Citizen.Wait(1000)

            if Cache.Get("hasPermission", "teleport")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                last_pos = nil
                strikes = 0
                goto continue
            end

            local ped = Cache.Get("ped")
            if not ped or not DoesEntityExist(ped) then
                last_pos = nil
                goto continue
            end

            local now = GetGameTimer()
            if (now - last_spawn_time) < SPAWN_GRACE
                or (now - last_death_time) < SPAWN_GRACE
            then
                last_pos = Cache.Get("coords")
                goto continue
            end

            local current = Cache.Get("coords")

            if Cache.Get("isInVehicle")
                or Cache.Get("isSwimming")
                or Cache.Get("isSwimmingUnderWater")
                or IsPedFalling(ped)
                or IsPedRagdoll(ped)
                or IsPedDeadOrDying(ped, true)
                or NetworkIsInSpectatorMode()
            then
                last_pos = current
                goto continue
            end

            if last_pos and #(current - last_pos) > 150.0 then
                strikes = strikes + 1
                if strikes >= STRIKE_LIMIT then
                    strikes = 0
                    ProtectionHelper.punish("Anti Teleport")
                end
            else
                if strikes > 0 then strikes = strikes - 1 end
            end

            last_pos = current
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("teleport", AntiTeleport.initialize)
return AntiTeleport
