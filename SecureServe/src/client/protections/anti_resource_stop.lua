local ProtectionManager = require("client/protections/protection_manager")

---@class AntiResourceStopModule
local AntiResourceStop = {}

---@description Initialize Anti Resource Stop protection
function AntiResourceStop.initialize()
   return
end

ProtectionManager.register_protection("resource_stop", AntiResourceStop.initialize)

return AntiResourceStop 