local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiMagicBullet = {}

function AntiMagicBullet.initialize()
    if not ConfigLoader.get_protection_setting("Anti Magic Bullet", "enabled") then
        return
    end

    local function check_killer_has_los(attacker, victim)
        if Cache.Get("hasPermission", "magicbullet")
            or Cache.Get("hasPermission", "all")
            or Cache.Get("isAdmin")
        then
            return
        end

        Citizen.CreateThread(function()
            local missed_los = 0
            for i = 1, 6 do
                if not DoesEntityExist(attacker) or not DoesEntityExist(victim) then
                    return
                end
                local los_front = HasEntityClearLosToEntityInFront(attacker, victim)
                local los_any   = HasEntityClearLosToEntity(attacker, victim, 287)
                if not los_front and not los_any then
                    missed_los = missed_los + 1
                end
                Wait(800)
            end

            if missed_los >= 6 then
                ProtectionHelper.punish("Anti Magic Bullet", "Magic Bullet Detected")
            end
        end)
    end

    AddEventHandler('gameEventTriggered', function(event, data)
        if event ~= 'CEventNetworkEntityDamage' then return end
        local victim, victim_died = data[1], data[4]
        if not IsPedAPlayer(victim) then return end

        local local_player = PlayerId()
        if NetworkGetPlayerIndexFromPed(victim) ~= local_player then return end
        if not victim_died then return end

        local player_ped = Cache.Get("ped")
        if not IsPedDeadOrDying(victim, true) and not IsPedFatallyInjured(victim) then
            return
        end

        local killer_entity = GetPedSourceOfDeath(player_ped)
        if killer_entity == player_ped or killer_entity == 0 then return end

        local killer_client_id = NetworkGetPlayerIndexFromPed(killer_entity)
        if killer_client_id and NetworkIsPlayerActive(killer_client_id) then
            local attacker = GetPlayerPed(killer_client_id)
            check_killer_has_los(attacker, victim)
        end
    end)
end

ProtectionManager.register_protection("magic_bullet", AntiMagicBullet.initialize)
return AntiMagicBullet
