---@class AntiExplosiveDamageModule
local AntiExplosiveDamage = {}
---@todo remove this

local ban_manager = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")
local player_manager = require("server/core/player_manager")

---@description Initialize anti-explosive damage protection
function AntiExplosiveDamage.initialize()
    return
end

return AntiExplosiveDamage 