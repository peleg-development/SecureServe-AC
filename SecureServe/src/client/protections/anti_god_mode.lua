local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiGodModeModule
local AntiGodMode = {}

---@description Initialize Anti God Mode protection
function AntiGodMode.initialize()
    if not Anti_God_Mode_enabled then return end

    local previous_health = 0
    local fire_loop_time = 0
    local health_loop_time = 0

    AddEventHandler('gameEventTriggered', function(eventName, args)
        if eventName == 'CEventNetworkEntityDamage' then
            local victim = args[1]
            local attacker = args[2]
            local victim_died = args[4]
            local weapon_hash = args[5]
            local is_melee_weapon = args[10]
            
            local victim_health = GetEntityHealth(victim)
            
            if attacker == -1 and (victim_health == 199 or victim_health == 0 and not IsPedDeadOrDying(victim)) and victim == Cache.Get("ped") and not ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti God Mode", Anti_God_Mode_webhook, Anti_God_Mode_time)
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000)
            
            local cur_time = GetGameTimer()
            local cur_health = Cache.Get("health")
            
            if (cur_time - health_loop_time) > 5000 then
                health_loop_time = cur_time
                
                if cur_health > 200 and not ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti God Mode", Anti_God_Mode_webhook, Anti_God_Mode_time)
                end
            end
            
            previous_health = cur_health
        end
    end)
end

ProtectionManager.register_protection("god_mode", AntiGodMode.initialize)

return AntiGodMode 