local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

local AntiVisions = {}

function AntiVisions.initialize()
    local enabled = ConfigLoader.get_protection_setting("Anti Thermal Vision", "enabled")
                 or ConfigLoader.get_protection_setting("Anti Night Vision", "enabled")
    if not enabled then return end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(6500)

            if Cache.Get("hasPermission", "visions")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
            else
                if GetUsingseethrough() then
                    ProtectionHelper.punish("Anti Thermal Vision", "Anti Thermal Vision")
                end

                if GetUsingnightvision() then
                    ProtectionHelper.punish("Anti Night Vision", "Anti Night Vision")
                end
            end
        end
    end)
end

ProtectionManager.register_protection("visions", AntiVisions.initialize)
return AntiVisions
