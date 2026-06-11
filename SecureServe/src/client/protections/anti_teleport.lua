local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiTeleport = {}

local DISTANCE_LIMIT = 150.0
local SPAWN_GRACE = 10000
local STRIKE_LIMIT = 2

local lastSpawnAt = 0
local lastDeathAt = 0

local function isExempt()
    return Cache.Get("hasPermission", "teleport")
        or Cache.Get("hasPermission", "all")
        or Cache.Get("isAdmin")
end

local function isInGraceWindow()
    local now = GetGameTimer()
    return (now - lastSpawnAt) < SPAWN_GRACE
        or (now - lastDeathAt) < SPAWN_GRACE
end

local function shouldIgnorePedState(ped)
    return Cache.Get("isInVehicle")
        or Cache.Get("isSwimming")
        or Cache.Get("isSwimmingUnderWater")
        or IsPedFalling(ped)
        or IsPedRagdoll(ped)
        or IsPedDeadOrDying(ped, true)
        or NetworkIsInSpectatorMode()
end

function AntiTeleport.initialize()
    if not ConfigLoader.get_protection_setting("Anti Teleport", "enabled") then return end

    AddEventHandler("playerSpawned", function()
        lastSpawnAt = GetGameTimer()
    end)

    AddEventHandler("gameEventTriggered", function(event, data)
        if event ~= "CEventNetworkEntityDamage" then return end
        local victim, victimDied = data[1], data[4]
        if victim == PlayerPedId() and victimDied then
            lastDeathAt = GetGameTimer()
        end
    end)

    Citizen.CreateThread(function()
        local lastPosition = nil
        local strikes = 0

        while true do
            Citizen.Wait(1000)

            if isExempt() then
                lastPosition = nil
                strikes = 0
            else
                local ped = Cache.Get("ped")
                local current = Cache.Get("coords")

                if not ped or not DoesEntityExist(ped) then
                    lastPosition = nil
                elseif isInGraceWindow() or shouldIgnorePedState(ped) then
                    lastPosition = current
                elseif lastPosition and #(current - lastPosition) > DISTANCE_LIMIT then
                    strikes = strikes + 1
                    if strikes >= STRIKE_LIMIT then
                        strikes = 0
                        ProtectionHelper.punish("Anti Teleport")
                    end
                    lastPosition = current
                else
                    if strikes > 0 then strikes = strikes - 1 end
                    lastPosition = current
                end
            end
        end
    end)
end

ProtectionManager.register_protection("teleport", AntiTeleport.initialize)

return AntiTeleport
