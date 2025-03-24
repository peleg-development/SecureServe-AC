---@class AntiExplosions
local AntiExplosions = {}

local config_manager = require("server/core/config_manager")
local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")
local debug_module = require("server/core/debug_module")

---@description Initialize anti-explosions protection
function AntiExplosions.initialize()
    if not SecureServe.Module.Explosions.ModuleEnabled then
        return
    end
    
    local whitelist = {}
    local explosions = {}
    local detected = {}
    local false_explosions = {
        [11] = true,
        [12] = true,
        [13] = true,
        [24] = true,
        [30] = true,
    }
    
    RegisterNetEvent("SecureServe:Explosions:Whitelist", function(data)
        if (data.source == nil) then return end
        whitelist[data.source] = true
        logger.debug("Whitelisted explosion for player ID: " .. data.source)
    end)
    
    AddEventHandler('explosionEvent', function(sender, ev)
        explosions[sender] = explosions[sender] or {}
        
        if ev.ownerNetId == 0 then
            CancelEvent()
            return
        end

        local explosionType = ev.explosionType
        local explosionPos = ev.posX and ev.posY and ev.posZ and vector3(ev.posX, ev.posY, ev.posZ) or "Unknown"
        local explosionDamage = ev.damageScale or "Unknown"
        local explosionOwner = GetPlayerName(sender) or "Unknown"
    
        logger.debug(string.format("Explosion detected! Type: %s | Position: %s | Damage Scale: %s | Owner: %s", 
            explosionType, explosionPos, explosionDamage, explosionOwner))

        local resourceName = GetInvokingResource()
        if GetPlayerPing(sender) > 0 and SecureServe.ExplosionsModule then
            if whitelist[sender] or SecureServe.ExplosionsWhitelist[resourceName] then
                whitelist[sender] = false
            else
                ban_manager.ban_player(sender, "Explosions", string.format("Explosion Details: Type: %s, Position: %s, Damage Scale: %s", 
                    explosionType, explosionPos, explosionDamage))
                CancelEvent()
                return
            end
        end
    
        for k, v in pairs(SecureServe.Protection.BlacklistedExplosions) do
            if ev.explosionType == v.id then
                local explosionInfo = string.format("Explosion Type: %d, Position: (%.2f, %.2f, %.2f)", ev.explosionType, ev.posX, ev.posY, ev.posZ)

                if v.limit and explosions[sender][v.id] and explosions[sender][v.id] >= v.limit then
                    ban_manager.ban_player(sender, "Explosions", "Exceeded explosion limit at explosion: " .. v.id .. ". " .. explosionInfo)
                    CancelEvent()
                    return
                end

                explosions[sender][v.id] = (explosions[sender][v.id] or 0) + 1

                if v.limit and explosions[sender][v.id] > v.limit then
                    ban_manager.ban_player(sender, "Explosions", "Exceeded explosion limit at explosion: " .. v.id .. ". " .. explosionInfo)
                    CancelEvent()
                    return
                end

                if v.limit then
                    if explosions[sender][v.id] > v.limit then
                        if false_explosions[ev.explosionType] then return end
                        if not detected[sender] then
                            detected[sender] = true
                            CancelEvent()
                            ban_manager.ban_player(sender, "Explosions", "Exceeded explosion limit at explosion: " .. v.id .. ". " .. explosionInfo)
                        end
                    end
                end

                if v.audio and ev.isAudible == false then
                    ban_manager.ban_player(sender, "Explosions", "Used inaudible explosion. " .. explosionInfo)
                    CancelEvent()
                    return
                end

                if v.invisible and ev.isInvisible == true then
                    ban_manager.ban_player(sender, "Explosions", "Used invisible explosion. " .. explosionInfo)
                    CancelEvent()
                    return
                end

                if v.damageScale and ev.damageScale > 1.0 then
                    ban_manager.ban_player(sender, "Explosions", "Used boosted explosion. " .. explosionInfo)
                    return
                end

                if SecureServe.Protection.CancelOtherExplosions then
                    for k, v in pairs(SecureServe.Protection.BlacklistedExplosions) do
                        if ev.explosionType ~= v.id then
                            CancelEvent()
                        end
                    end
                end
            end
        end
    end)
    
    logger.info("Anti-Explosions protection initialized")
end

return AntiExplosions