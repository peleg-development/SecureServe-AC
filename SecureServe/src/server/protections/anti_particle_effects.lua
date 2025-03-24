---@class AntiParticleEffectsModule
local AntiParticleEffects = {
    particle_tracking = {},
    last_particle_reset = {}
}

local ban_manager = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")


---@description Initialize anti-particle effects protection
function AntiParticleEffects.initialize()
    AddEventHandler("ptFxEvent", function(sender, data)
        if not config_manager.is_particle_protection_enabled() then
            return
        end
        
        if sender <= 0 then
            return
        end
        
        local current_time = os.time()
        
        if not AntiParticleEffects.particle_tracking[sender] then
            AntiParticleEffects.particle_tracking[sender] = 0
            AntiParticleEffects.last_particle_reset[sender] = current_time
        end
        
        if current_time - AntiParticleEffects.last_particle_reset[sender] >= 5 then
            AntiParticleEffects.particle_tracking[sender] = 0
            AntiParticleEffects.last_particle_reset[sender] = current_time
        end
        
        AntiParticleEffects.particle_tracking[sender] = AntiParticleEffects.particle_tracking[sender] + 1
        
        if AntiParticleEffects.particle_tracking[sender] > config_manager.get_max_particles_per_second() * 5 then
            ban_manager.ban_player(sender, "Particle Effect Spam", "Too many particle effects: " .. AntiParticleEffects.particle_tracking[sender])
            CancelEvent()
            return
        end
        
        if config_manager.is_blacklisted_particle(data.effectHash) then
            ban_manager.ban_player(sender, "Blacklisted Particle", "Used blacklisted particle effect: " .. data.effectHash)
            CancelEvent()
            return
        end
    end)
    
    AddEventHandler("playerDropped", function()
        local src = source
        
        AntiParticleEffects.particle_tracking[src] = nil
        AntiParticleEffects.last_particle_reset[src] = nil
    end)
end

---@param player_id number The player ID to clear tracking for
function AntiParticleEffects.clear_player_tracking(player_id)
    AntiParticleEffects.particle_tracking[player_id] = nil
    AntiParticleEffects.last_particle_reset[player_id] = nil
end

return AntiParticleEffects 