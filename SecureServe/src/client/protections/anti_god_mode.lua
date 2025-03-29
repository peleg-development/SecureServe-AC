local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiGodModeModule
local AntiGodMode = {}

---@description Initialize Anti God Mode protection
function AntiGodMode.initialize()
    local enabled = ConfigLoader.get_protection_setting("Anti God Mode", "enabled")
    if not enabled then return end

end

ProtectionManager.register_protection("god_mode", AntiGodMode.initialize)

return AntiGodMode