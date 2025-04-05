local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiMagicBulletModule
local AntiMagicBullet = {}

---@description Initialize Anti Magic Bullet protection
function AntiMagicBullet.initialize()
    if not ConfigLoader.get_protection_setting("Anti Magic Bullet", "enabled") then return end
    
    local tolerance = ConfigLoader.get_protection_setting("Anti Magic Bullet", "tolerance") or 3
    
    local function check_killer_has_los(attacker, victim, killer_client_id)
        if Cache.Get("hasPermission", "magicbullet") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
            return
        end
        
        local attempt = 0
        for i = 0, 3, 1 do
            if not HasEntityClearLosToEntityInFront(attacker, victim) and not HasEntityClearLosToEntity(attacker, victim, 17) and HasEntityClearLosToEntity_2(attacker, victim, 17) == 0 then
                attempt = attempt + 1
            end
            Wait(1500)
        end
        
        if (attempt >= tolerance) then
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Magic Bullet Detected", webhook, time)
        end
    end

    AddEventHandler('gameEventTriggered', function(event, data)
        if event ~= 'CEventNetworkEntityDamage' then return end
        local victim, victim_died = data[1], data[4]
        if not IsPedAPlayer(victim) then return end
        
        local player = PlayerId()
        local player_ped = Cache.Get("ped")
        
        if victim_died and NetworkGetPlayerIndexFromPed(victim) == player and (IsPedDeadOrDying(victim, true) or IsPedFatallyInjured(victim)) then
            local killer_entity, death_cause = GetPedSourceOfDeath(player_ped), GetPedCauseOfDeath(player_ped)
            local killer_client_id = NetworkGetPlayerIndexFromPed(killer_entity)
            
            if killer_entity ~= player_ped and killer_client_id and NetworkIsPlayerActive(killer_client_id) then
                local attacker = GetPlayerPed(killer_client_id)
                check_killer_has_los(attacker, victim, killer_client_id)
            end
        end
    end)
end

ProtectionManager.register_protection("magic_bullet", AntiMagicBullet.initialize)

return AntiMagicBullet