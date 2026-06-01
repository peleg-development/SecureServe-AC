local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

---@class AntiBiggerHitboxModule
local AntiBiggerHitbox = {}

local FREEMODE_HASHES = {
    [GetHashKey('mp_m_freemode_01')] = true,
    [GetHashKey('mp_f_freemode_01')] = true,
}

---@description Initialize Anti Bigger Hitbox protection
function AntiBiggerHitbox.initialize()
    if not ConfigLoader.get_protection_setting("Anti Bigger Hitbox", "enabled") then return end

    Citizen.CreateThread(function()
        local strikes = 0
        local STRIKE_LIMIT = tonumber(ConfigLoader.get_protection_setting("Anti Bigger Hitbox", "strike_limit")) or 3
        local INTERVAL     = tonumber(ConfigLoader.get_protection_setting("Anti Bigger Hitbox", "check_interval_ms")) or 15000

        while true do
            Citizen.Wait(INTERVAL)

            if Cache.Get("hasPermission", "biggerhitbox")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                strikes = 0
                goto continue
            end

            local id = Cache.Get("ped")
            if not id or not DoesEntityExist(id) then
                goto continue
            end

            local model_hash = GetEntityModel(id)
            if not FREEMODE_HASHES[model_hash] then
                strikes = 0
                goto continue
            end

            local min, max = GetModelDimensions(model_hash)
            -- Tolerance window: vanilla freemode is roughly
            --   min ≈ (-0.60, -0.27, -1.04)
            --   max ≈ ( 0.60,  0.27,  0.93)
            -- We give a generous tolerance so harmless animations don't flag.
            local out_of_bounds =
                min.x > -0.58 or min.x < -0.62
                or min.y > -0.252 or min.y < -0.29
                or max.z > 0.98

            if out_of_bounds then
                strikes = strikes + 1
                if strikes >= STRIKE_LIMIT then
                    strikes = 0
                    ProtectionHelper.punish('Anti Bigger Hitbox',
                        ("Anti Bigger Hitbox (min=%.3f,%.3f,%.3f max.z=%.3f)")
                            :format(min.x, min.y, min.z, max.z))
                end
            else
                if strikes > 0 then strikes = strikes - 1 end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("bigger_hitbox", AntiBiggerHitbox.initialize)

return AntiBiggerHitbox
