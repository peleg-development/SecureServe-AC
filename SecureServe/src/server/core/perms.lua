local ServerPerms = {}

local AdminWhitelist = require("server/core/admin_whitelist")

local function normalizeSource(value)
    local src = tonumber(value)
    if not src or src <= 0 then return nil end
    if not GetPlayerName(src) then return nil end
    return src
end

local function normalizeRequestId(value)
    if type(value) == "number" then return value end
    if type(value) == "string" and #value <= 64 then return value end
    return nil
end

function ServerPerms.IsMenuAdmin(source)
    local src = normalizeSource(source)
    if not src then return false end
    return AdminWhitelist.isWhitelisted(src) == true
end

RegisterNetEvent("SecureServe:RequestMenuAdminStatus", function(target, requestId)
    local src = normalizeSource(source)
    if not src then return end

    local targetId = normalizeSource(target) or src
    if targetId ~= src and not ServerPerms.IsMenuAdmin(src) then
        targetId = src
    end

    TriggerClientEvent(
        "SecureServe:ReturnMenuAdminStatus",
        src,
        normalizeRequestId(requestId),
        ServerPerms.IsMenuAdmin(targetId)
    )
end)

_G.IsMenuAdmin = ServerPerms.IsMenuAdmin

return ServerPerms
