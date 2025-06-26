local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiTeleportModule
local AntiTeleport = {}

---@description Initialize Anti Teleport protection
function AntiTeleport.initialize()
    if not ConfigLoader.get_protection_setting("Anti Teleport", "enabled") then return end
    
    ---@todo v1.3.0: Implement Anti Teleport whitelisting
    -- This will allow certain coordinates to be exempt from teleport detection.

    if Cache.Get("hasPermission", "teleport") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
        return
    end

    local whitelisted = ConfigLoader.get_protection_setting("Anti Teleport", "whitelisted_coords") or {}

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)

            local ped = Cache.Get("ped")
            local current_pos = Cache.Get("coords")

            if Cache.Get("isInVehicle") or Cache.Get("isSwimming") or Cache.Get("isSwimmingUnderWater") then
                goto continue
            end

            if IsPedFalling(ped) then
                local last_pos = Cache.Get("lastCoords")
                if last_pos and #(current_pos - last_pos) > 150.0 and not whitelisted[current_pos] then
                    local webhook = ConfigLoader.get_protection_setting("Anti Teleport", "webhook") or ""
                    local time = ConfigLoader.get_protection_setting("Anti Teleport", "time") or 0
                    
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Teleport", webhook, time)
                end
            end

            ::continue::
        end
    end)

end

ProtectionManager.register_protection("teleport", AntiTeleport.initialize)

return AntiTeleport 