local Encryption = require("shared/lib/encryption")

---@class PlayerManagerModule
local PlayerManager = {
    connected_players = {},
    whitelisted_explosions = {},
    alive_players = {}
}

---@description Initialize player manager functionality
function PlayerManager.initialize()
    AddEventHandler("playerConnecting", function(name, setCallback, deferrals)
        local src = source
        local identifiers = GetPlayerIdentifiers(src)
        
        PlayerManager.connected_players[src] = {
            name = GetPlayerName(src),
            identifiers = identifiers,
            connected_at = os.time()
        }
    end)
    
    AddEventHandler("playerDropped", function(reason)
        local src = source
        PlayerManager.connected_players[src] = nil
        PlayerManager.alive_players[src] = nil
        PlayerManager.whitelisted_explosions[src] = nil
    end)
end

---@param src number Source ID to validate
---@return boolean is_valid Whether the source is valid
function PlayerManager.validate_source(src)
    if not src or src <= 0 then
        return false
    end
    
    return GetPlayerPing(src) > 0
end

---@param player_id number The player ID to check permissions for
---@param permission string The permission to check
---@return boolean has_permission Whether the player has the permission
function PlayerManager.has_permission(player_id, permission)
    local identifiers = GetPlayerIdentifiers(player_id)
    local found = false
    
    for _, id in pairs(identifiers) do
        for _, admin in pairs(SecureServe.Admins) do
            if id == admin.identifier and permission == admin.permission then
                found = true
                break
            end
        end
        
        if found then break end
    end
    
    return found
end

---@param src number Source ID to get identifiers for
---@return table identifiers Table of player identifiers
function PlayerManager.get_identifiers(src)
    if not PlayerManager.validate_source(src) then
        return {}
    end
    
    return GetPlayerIdentifiers(src) or {}
end

---@param src number Source ID to check
---@return boolean is_explosion_whitelisted Whether the player's explosion is whitelisted
function PlayerManager.is_whitelisted_explosion(src, explosion_type)
    return PlayerManager.whitelisted_explosions[src] ~= nil
end

---@param src number Source ID to get explosion data for
---@return table|nil explosion_data The explosion data or nil if not found
function PlayerManager.get_explosion_data(src)
    return PlayerManager.whitelisted_explosions[src]
end

---@param src number Source ID to whitelist explosion for
---@param explosion_type number The explosion type to whitelist
---@return boolean success Whether the explosion was successfully whitelisted
function PlayerManager.whitelist_explosion(src, explosion_type)
    if not src or not explosion_type then
        return false
    end
    
    PlayerManager.whitelisted_explosions[src] = {
        type = explosion_type,
        timestamp = os.time()
    }
    
    return true
end

---@param src number Source ID to clear explosion whitelist for
---@param explosion_type number|nil Optional explosion type to clear
function PlayerManager.clear_whitelisted_explosion(src, explosion_type)
    if explosion_type then
        if PlayerManager.whitelisted_explosions[src] and PlayerManager.whitelisted_explosions[src].type == explosion_type then
            PlayerManager.whitelisted_explosions[src] = nil
        end
    else
        PlayerManager.whitelisted_explosions[src] = nil
    end
end

---@param src number Source to mark as alive
function PlayerManager.mark_alive(src)
    PlayerManager.alive_players[src] = true
end

---@description Get the count of currently connected players
---@return number count The number of players currently connected
function PlayerManager.get_player_count()
    local count = 0
    for _ in pairs(PlayerManager.connected_players) do
        count = count + 1
    end
    return count
end

return PlayerManager 