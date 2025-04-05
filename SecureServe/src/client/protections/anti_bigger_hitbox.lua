local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiBiggerHitboxModule
local AntiBiggerHitbox = {}

---@description Initialize Anti Bigger Hitbox protection
function AntiBiggerHitbox.initialize()
    if not ConfigLoader.get_protection_setting("Anti Bigger Hitbox", "enabled") then return end

    Citizen.CreateThread(function()
        while true do
            local id = Cache.Get("ped")
            local ped = GetEntityModel(id)

            if (ped == GetHashKey('mp_m_freemode_01') or ped == GetHashKey('mp_f_freemode_01')) then
                local min, max = GetModelDimensions(ped)
                if (min.x > -0.58)
                    or (min.x < -0.62)
                    or (min.y < -0.252)
                    or (min.y < -0.29)
                    or (max.z > 0.98) then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Bigger Hit Box", webhook, time)
                end
            end

            Citizen.Wait(15000)
        end
    end)
end

ProtectionManager.register_protection("bigger_hitbox", AntiBiggerHitbox.initialize)

return AntiBiggerHitbox