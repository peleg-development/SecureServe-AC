local ServerPerms = {}

local AdminWhitelist = require("server/core/admin_whitelist")

RegisterNetEvent("SecureServe:RequestMenuAdminStatus", function(target, request_id)
    local src = tonumber(source)
    local check_id = tonumber(target) or tonumber(src)
    local is_admin = false
    if check_id then
        is_admin = AdminWhitelist.isWhitelisted(check_id) == true
    end
    TriggerClientEvent("SecureServe:ReturnMenuAdminStatus", src, request_id, is_admin)
end)

function ServerPerms.IsMenuAdmin(source)
    local src = tonumber(source)
    if not src then return false end
    return AdminWhitelist.isWhitelisted(src) == true
end

_G.IsMenuAdmin = ServerPerms.IsMenuAdmin

return ServerPerms
