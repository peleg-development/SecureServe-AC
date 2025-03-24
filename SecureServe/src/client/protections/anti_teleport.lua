local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")

---@class AntiTeleportModule
local AntiTeleport = {}

---@description Initialize Anti Teleport protection
function AntiTeleport.initialize()
    return
end

ProtectionManager.register_protection("teleport", AntiTeleport.initialize)

return AntiTeleport 