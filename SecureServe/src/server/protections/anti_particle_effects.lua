---@class AntiParticleEffectsModule
local AntiParticleEffects = {}

local ban_manager = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

local particle_tracking = {}
local last_particle_reset = {}

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
        
        if not particle_tracking[sender] then
            particle_tracking[sender] = 0
            last_particle_reset[sender] = current_time
        end
        
        if current_time - last_particle_reset[sender] >= 5 then
            particle_tracking[sender] = 0
            last_particle_reset[sender] = current_time
        end
        
        particle_tracking[sender] = particle_tracking[sender] + 1
        
        if particle_tracking[sender] > config_manager.get_max_particles_per_second() * 5 then
            ban_manager.ban_player(sender, "Particle Effect Spam", "Too many particle effects: " .. particle_tracking[sender])
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
        
        particle_tracking[src] = nil
        last_particle_reset[src] = nil
    end)
end

---@param player_id number The player ID to clear tracking for
function AntiParticleEffects.clear_player_tracking(player_id)
    particle_tracking[player_id] = nil
    last_particle_reset[player_id] = nil
end

return AntiParticleEffects 