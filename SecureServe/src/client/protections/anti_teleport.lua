local ProtectionManager = require("client/protections/protection_manager")

local Cache = require("client/core/cache")

---@class AntiTeleportModule
local AntiTeleport = {}

---@description Initialize Anti Teleport protection
function AntiTeleport.initialize()
    if not ConfigLoader.get_protection_setting("Anti Teleport", "enabled") then return end
    
    ---@description Resolve Anti Teleport whitelisting with radius support

    if Cache.Get("hasPermission", "teleport") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
        return
    end

    local function get_whitelist()
        local cfg = ConfigLoader.get_secureserve()
        if not cfg or not cfg.Protection or not cfg.Protection.Simple then return {} end
        for _, v in pairs(cfg.Protection.Simple) do
            if v.protection == "Anti Teleport" then
                return v.whitelisted_coords or {}
            end
        end
        return {}
    end

    local function is_whitelisted(coords)
        local list = get_whitelist()
        for _, entry in ipairs(list) do
            local ex, ey, ez = entry.x, entry.y, entry.z
            local radius = tonumber(entry.radius) or 0.0
            if ex and ey and ez and radius > 0 then
                local dist = #(coords - vector3(ex, ey, ez))
                if dist <= radius then
                    return true
                end
            end
        end
        return false
    end

    Citizen.CreateThread(function()
        local last_pos = nil
        while true do
            Citizen.Wait(1000)

            local ped = Cache.Get("ped")
            local current_pos = Cache.Get("coords")

            if Cache.Get("isInVehicle") or Cache.Get("isSwimming") or Cache.Get("isSwimmingUnderWater") then
                goto continue
            end

            if not IsPedFalling(ped) then
                if last_pos and #(current_pos - last_pos) > 150.0 and not is_whitelisted(current_pos) then
                    local webhook = ConfigLoader.get_protection_setting("Anti Teleport", "webhook") or ""
                    local time = ConfigLoader.get_protection_setting("Anti Teleport", "time") or 0
                    
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Teleport", webhook, time)
                end
            end

            last_pos = current_pos
            ::continue::
        end
    end)

end

ProtectionManager.register_protection("teleport", AntiTeleport.initialize)

return AntiTeleport 