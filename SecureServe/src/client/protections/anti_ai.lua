local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiAI = {}

function AntiAI.initialize()
    if not ConfigLoader.get_protection_setting("Anti AI", "enabled") then return end
    local default = ConfigLoader.get_protection_setting("Anti AI", "default") or 1.5

    local weapons = {
        GetHashKey("COMPONENT_COMBATPISTOL_CLIP_01"),
        GetHashKey("COMPONENT_COMBATPISTOL_CLIP_02"),
        GetHashKey("COMPONENT_APPISTOL_CLIP_01"),
        GetHashKey("COMPONENT_APPISTOL_CLIP_02"),
        GetHashKey("COMPONENT_MICROSMG_CLIP_01"),
        GetHashKey("COMPONENT_MICROSMG_CLIP_02"),
        GetHashKey("COMPONENT_SMG_CLIP_01"),
        GetHashKey("COMPONENT_SMG_CLIP_02"),
        GetHashKey("COMPONENT_ASSAULTRIFLE_CLIP_01"),
        GetHashKey("COMPONENT_ASSAULTRIFLE_CLIP_02"),
        GetHashKey("COMPONENT_CARBINERIFLE_CLIP_01"),
        GetHashKey("COMPONENT_CARBINERIFLE_CLIP_02"),
        GetHashKey("COMPONENT_ADVANCEDRIFLE_CLIP_01"),
        GetHashKey("COMPONENT_ADVANCEDRIFLE_CLIP_02"),
        GetHashKey("COMPONENT_MG_CLIP_01"),
        GetHashKey("COMPONENT_MG_CLIP_02"),
        GetHashKey("COMPONENT_COMBATMG_CLIP_01"),
        GetHashKey("COMPONENT_COMBATMG_CLIP_02"),
        GetHashKey("COMPONENT_PUMPSHOTGUN_CLIP_01"),
        GetHashKey("COMPONENT_SAWNOFFSHOTGUN_CLIP_01"),
        GetHashKey("COMPONENT_ASSAULTSHOTGUN_CLIP_01"),
        GetHashKey("COMPONENT_ASSAULTSHOTGUN_CLIP_02"),
        GetHashKey("COMPONENT_PISTOL50_CLIP_01"),
        GetHashKey("COMPONENT_PISTOL50_CLIP_02"),
        GetHashKey("COMPONENT_ASSAULTSMG_CLIP_01"),
        GetHashKey("COMPONENT_ASSAULTSMG_CLIP_02"),
        GetHashKey("COMPONENT_AT_RAILCOVER_01"),
        GetHashKey("COMPONENT_AT_AR_AFGRIP"),
        GetHashKey("COMPONENT_AT_PI_FLSH"),
        GetHashKey("COMPONENT_AT_AR_FLSH"),
        GetHashKey("COMPONENT_AT_SCOPE_MACRO"),
        GetHashKey("COMPONENT_AT_SCOPE_SMALL"),
        GetHashKey("COMPONENT_AT_SCOPE_MEDIUM"),
        GetHashKey("COMPONENT_AT_SCOPE_LARGE"),
        GetHashKey("COMPONENT_AT_SCOPE_MAX"),
        GetHashKey("COMPONENT_AT_PI_SUPP"),
    }

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(15000)

            if Cache.Get("hasPermission", "weaponcomponent")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                goto continue
            end

            for i = 1, #weapons do
                local dmg_mod = GetWeaponComponentDamageModifier(weapons[i])
                local accuracy_mod = GetWeaponComponentAccuracyModifier(weapons[i])
                local range_mod = GetWeaponComponentRangeModifier(weapons[i])

                if dmg_mod > default or accuracy_mod > default or range_mod > default then
                    ProtectionHelper.punish('Anti AI', "Anti AI (Component Modifier)")
                    break
                end
            end

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("ai", AntiAI.initialize)

return AntiAI
