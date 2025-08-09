---@diagnostic disable: undefined-global
---@class PermsModule
local Perms = {}

local ConfigLoader = require("client/core/config_loader")

---@description Determine if a player is allowed to open the admin menu based on configured groups
---@param server_id number|nil Optional server ID; defaults to the local player's server ID
---@return boolean is_admin True if the player is considered admin/whitelisted
function Perms.IsMenuAdmin(server_id)
    if not ConfigLoader.is_loaded() then
        ConfigLoader.initialize()
        Citizen.Wait(50)
    end

    local target_id = server_id or GetPlayerServerId(PlayerId())
    if _G.SecureServeAdminList and _G.SecureServeAdminList[tostring(target_id)] then
        return true
    end
    return ConfigLoader.is_menu_admin(target_id) == true
end

_G.IsMenuAdmin = Perms.IsMenuAdmin

return Perms


