local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiGodModeModule
local AntiGodMode = {
    detection_flags = 0,
    last_flag_time = 0,
    in_green_zone = false,
    last_zone_check = 0,
    suspicious_health_count = 0,
    whitelist_zones = {},
    flag_reset_time = 60000 
}

---@description Initialize Anti God Mode protection
function AntiGodMode.initialize()
    if not Anti_God_Mode_enabled then return end

    local previous_health = 0
    local fire_loop_time = 0
    local health_loop_time = 0
    
    if SecureServe and SecureServe.GreenZones then
        AntiGodMode.whitelist_zones = SecureServe.GreenZones
    else
        AntiGodMode.whitelist_zones = {
            {0, 0, 0, 50}
        }
    end
    
    local function isInGreenZone()
        local ped_coords = Cache.Get("coords")
        
        local current_time = GetGameTimer()
        if current_time - AntiGodMode.last_zone_check < 5000 and AntiGodMode.in_green_zone then
            return true
        end
        
        AntiGodMode.last_zone_check = current_time
        
        for _, zone in ipairs(AntiGodMode.whitelist_zones) do
            local zone_center = vector3(zone[1], zone[2], zone[3])
            local distance = #(ped_coords - zone_center)
            
            if distance <= zone[4] then
                AntiGodMode.in_green_zone = true
                return true
            end
        end
        
        AntiGodMode.in_green_zone = false
        return false
    end
    
    local function hasLegitimateInvincibility()
        local ped = Cache.Get("ped")
        
        if Cache.Get("isInVehicle") and Cache.Get("vehicle") and GetEntityInvincible(Cache.Get("vehicle")) then
            return true
        end
        
        if IsCutsceneActive() or IsPlayerSwitchInProgress() then
            return true
        end
        
        if not CanPedRagdoll(ped) and GetPedMaxHealth(ped) <= 200 then
            return true
        end
        
        if GetEntityHealth(ped) == GetEntityMaxHealth(ped) then
            return true
        end
        
        if GetPlayerInvincible_2(PlayerId()) then
            if GetPedMaxHealth(ped) <= 200 then
                return true
            end
        end
        
        return isInGreenZone()
    end
    
    local function flagSuspiciousActivity(reason)
        local current_time = GetGameTimer()
        if current_time - AntiGodMode.last_flag_time > AntiGodMode.flag_reset_time then
            AntiGodMode.detection_flags = 0
        end
        
        AntiGodMode.last_flag_time = current_time
        AntiGodMode.detection_flags = AntiGodMode.detection_flags + 1
        
        if AntiGodMode.detection_flags >= 3 and not ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) and not hasLegitimateInvincibility() then
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti God Mode - " .. reason, Anti_God_Mode_webhook, 2147483647)
            AntiGodMode.detection_flags = 0
        end
    end

    AddEventHandler('gameEventTriggered', function(eventName, args)
        if eventName == 'CEventNetworkEntityDamage' then
            local victim = args[1]
            local attacker = args[2]
            local victim_died = args[4]
            local weapon_hash = args[5]
            local is_melee_weapon = args[10]
            
            local victim_health = GetEntityHealth(victim)
            
            if hasLegitimateInvincibility() then
                return
            end
            
            if attacker == -1 and (victim_health == 199 or victim_health == 0 and not IsPedDeadOrDying(victim)) and victim == Cache.Get("ped") then
                if IsEntityOnFire(victim) or IsPedFalling(victim) then
                    flagSuspiciousActivity("Environment Damage Immunity")
                end
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000)
            
            local cur_time = GetGameTimer()
            local cur_health = Cache.Get("health")
            
            if hasLegitimateInvincibility() then
                previous_health = cur_health
                goto continue
            end
            
            if (cur_time - health_loop_time) > 5000 then
                health_loop_time = cur_time
                
                if cur_health > 200 then
                    AntiGodMode.suspicious_health_count = AntiGodMode.suspicious_health_count + 1
                    
                    if AntiGodMode.suspicious_health_count >= 3 then
                        flagSuspiciousActivity("Health Above Normal Maximum")
                        AntiGodMode.suspicious_health_count = 0
                    end
                else
                    AntiGodMode.suspicious_health_count = 0
                end
                
                if previous_health > 0 and previous_health < 150 and cur_health > previous_health + 20 then
                    if not IsPedInVehicle(Cache.Get("ped"), GetVehiclePedIsIn(Cache.Get("ped"), false), false) and not IsPedRagdoll(Cache.Get("ped")) then
                        flagSuspiciousActivity("Suspicious Health Regeneration")
                    end
                end
            end
            
            previous_health = cur_health
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("god_mode", AntiGodMode.initialize)

return AntiGodMode 