local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiFreecamModule
local AntiFreecam = {}

---@NOTE: AntiNoclip's job from now on...


function AntiFreecam.initialize()
    if not ConfigLoader.get_protection_setting("Anti Freecam", "enabled") then return end
end

ProtectionManager.register_protection("freecam", AntiFreecam.initialize)
return AntiFreecam