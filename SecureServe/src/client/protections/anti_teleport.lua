local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiTeleportModule
local AntiTeleport = {}

---@description Initialize Anti Teleport protection
function AntiTeleport.initialize()
    if not ConfigLoader.get_protection_setting("Anti Teleport", "enabled") then return end
    
    ---@todo v1.3.0: Implement Anti Teleport protection
end

ProtectionManager.register_protection("teleport", AntiTeleport.initialize)

return AntiTeleport 