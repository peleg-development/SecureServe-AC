---@class ServerPermsModule
local ServerPerms = {}

local AdminWhitelist = require("server/core/admin_whitelist")

---@description Respond to client requests for admin status (menu access)
RegisterNetEvent("SecureServe:RequestMenuAdminStatus", function(target, request_id)
    local src = tonumber(source)
    local check_id = tonumber(target) or tonumber(src)
    local is_admin = false
    if check_id then
        is_admin = AdminWhitelist.isWhitelisted(check_id) == true
    end
    TriggerClientEvent("SecureServe:ReturnMenuAdminStatus", src, request_id, is_admin)
end)

---@description Check if a server player has admin access for the in-game menu
---@param source number The server ID of the player
---@return boolean is_admin True if the player is whitelisted/admin
function ServerPerms.IsMenuAdmin(source)
    local src = tonumber(source)
    if not src then return false end
    return AdminWhitelist.isWhitelisted(src) == true
end

_G.IsMenuAdmin = ServerPerms.IsMenuAdmin

return ServerPerms


