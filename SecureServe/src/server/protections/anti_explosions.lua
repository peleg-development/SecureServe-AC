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
        if not data or not data.source then return end
        
        local src = source
        if src > 0 then
            whitelist[tostring(src)] = true
            logger.debug("Whitelisted explosion for player ID: " .. src)
        end
    end)
    
    AddEventHandler("explosionEvent", function(sender, ev)
        local canceled = AntiExplosions.handle_explosion(sender, ev.explosionType, ev.posX, ev.posY, ev.posZ, ev.damageScale)
        
        if canceled then
            CancelEvent()
        end
    end)
    
    logger.info("Anti-Explosions protection initialized")
end

---@description Whitelist an explosion for a player
---@param source number The player source
---@param explosion_type number The explosion type
---@return boolean success Whether the whitelist was successful
function AntiExplosions.whitelist_explosion(source, explosion_type)
    if not source or source <= 0 then
        return false
    end
    
    local sender_id = tostring(source)
    whitelist[sender_id] = true
    logger.debug("Manually whitelisted explosion type " .. explosion_type .. " for player ID: " .. source)
    return true
end

---@param explosion_type number The explosion type ID
---@return boolean is_blacklisted Whether the explosion type is blacklisted
function AntiExplosions.is_blacklisted_explosion(explosion_type)
    local blacklisted_explosions = SecureServe.Protection.BlacklistedExplosions or {}
    
    for _, blacklisted in pairs(blacklisted_explosions) do
        if tonumber(blacklisted.id) == tonumber(explosion_type) then
            return true, blacklisted
        end
    end
    
    return false, nil
end

function AntiExplosions.handle_explosion(sender, explosionType, posX, posY, posZ, damageScale)
    if not config_manager.get("ExplosionProtection") then
        return false
    end
    
    local sender_id = tostring(sender)
    explosions[sender_id] = explosions[sender_id] or {}
    
    if posX == nil or posY == nil or posZ == nil then
        return false
    end

    local explosionPos = vector3(posX, posY, posZ)
    local playerName = GetPlayerName(sender) or "Unknown"
    
    if debug_module and debug_module.is_debug_enabled() then
        logger.debug(string.format("Explosion detected! Type: %s | Position: %s | Damage Scale: %s | Player: %s", 
            explosionType, explosionPos, damageScale, playerName))
    end

    local resourceName = GetInvokingResource()
    if GetPlayerPing(sender) > 0 then
        local config = SecureServe
        local explosion_whitelist = config and config.ExplosionsWhitelist or {}
        
        if whitelist[sender_id] then
            whitelist[sender_id] = nil
            return false
        elseif explosion_whitelist[resourceName] then
            return false
        elseif false_explosions[explosionType] then
            return false
        end
    end

    local blacklisted_explosions = config_manager.get("BlacklistedExplosions") or {}
    for _, blacklisted in ipairs(blacklisted_explosions) do
        if explosionType == blacklisted.id then
            local explosionInfo = string.format("Explosion Type: %d, Position: (%.2f, %.2f, %.2f)", 
                explosionType, posX, posY, posZ)

            if blacklisted.limit then
                explosions[sender_id][explosionType] = (explosions[sender_id][explosionType] or 0) + 1
                
                if explosions[sender_id][explosionType] > blacklisted.limit then
                    if not detected[sender_id] then
                        detected[sender_id] = true
                        CancelEvent()
                        
                        exports[GetCurrentResourceName()].module_punish(sender, 
                            "Exceeded explosion limit for type: " .. explosionType .. ". " .. explosionInfo, 
                            blacklisted.webhook or config_manager.get("Webhooks.BlacklistedExplosions"), 
                            blacklisted.time or 0)
                        
                        return true
                    end
                end
            end

            if blacklisted.audio and ev.isAudible == false then
                CancelEvent()
                exports[GetCurrentResourceName()].module_punish(sender, 
                    "Used inaudible explosion. " .. explosionInfo, 
                    blacklisted.webhook or config_manager.get("Webhooks.BlacklistedExplosions"), 
                    blacklisted.time or 0)
                return true
            end

            if blacklisted.invisible and ev.isInvisible == true then
                CancelEvent()
                exports[GetCurrentResourceName()].module_punish(sender, 
                    "Used invisible explosion. " .. explosionInfo, 
                    blacklisted.webhook or config_manager.get("Webhooks.BlacklistedExplosions"), 
                    blacklisted.time or 0)
                return true
            end

            if blacklisted.damageScale and damageScale > 1.0 then
                CancelEvent()
                exports[GetCurrentResourceName()].module_punish(sender, 
                    "Used boosted explosion damage. " .. explosionInfo, 
                    blacklisted.webhook or config_manager.get("Webhooks.BlacklistedExplosions"), 
                    blacklisted.time or 0)
                return true
            end
        end
    end
    
    if config_manager.get("CancelOtherExplosions") then
        CancelEvent()
        return true
    end
    
    return false
end

return AntiExplosions
