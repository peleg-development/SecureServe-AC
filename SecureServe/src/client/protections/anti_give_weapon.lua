local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiGiveWeaponModule
local AntiGiveWeapon = {}
local current_weapon = GetHashKey("WEAPON_UNARMED")
local flag = 0

---@description Initialize Anti Give Weapon protection
function AntiGiveWeapon.initialize()
    if not ConfigLoader.get_protection_setting("Anti Give Weapon", "enabled") then return end

    RegisterNetEvent("SecureServe:Weapons:Whitelist", function(data)
        local source = source
        local weapon = data.weapon
        local resource = data.resource

        if not weapon or not resource then return end

        current_weapon = weapon
    end)

    Citizen.CreateThread(function()
        while true do
            Wait(2500)
            if current_weapon ~= Cache.Get("selectedWeapon") then
                flag = flag + 1

                if flag == 2 then
                    RemoveWeaponFromPed(PlayerPedId(), current_weapon)
                    flag = 0
                end
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Wait(15000)
            flag = 0
        end
    end)
end

ProtectionManager.register_protection("give_weapon", AntiGiveWeapon.initialize)

return AntiGiveWeapon
