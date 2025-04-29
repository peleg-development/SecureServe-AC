local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiNoclipModule
local AntiNoclip = {}

---@description Initialize Anti Noclip protection
function AntiNoclip.initialize()
    if not ConfigLoader.get_protection_setting("Anti Noclip", "enabled") then return end
    
    local lastPos = vector3(0, 0, 0)
    local teleport_threshold = 16.0
    local clip_flags = 0
    local lastCheckTime = 0
    local CHECK_INTERVAL = 1500 
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(CHECK_INTERVAL)

            if Cache.Get("hasPermission", "noclip") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end
            
            ---@todo v1.3.0: Implement Anti Noclip protection

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("noclip", AntiNoclip.initialize)

return AntiNoclip 