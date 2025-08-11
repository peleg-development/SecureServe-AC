local ProtectionManager = require("client/protections/protection_manager")

---@class AntiNoClipModule
local AntiNoClip = {
    is_busy = false
}

---@description Initialize Anti NoClip protection
function AntiNoClip.initialize()
    if not ConfigLoader.get_protection_setting("Anti NoClip", "enabled") then return end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(250)

            local ped = Cache.Get("ped")
            local pos = GetEntityCoords(ped)
            local still = IsPedStill(ped)
            local speed = GetEntitySpeed(ped)
            Citizen.Wait(1500)

            local newx, newy, newz = table.unpack(GetEntityCoords(ped, true))
            local newpos = GetEntityCoords(ped)
            if #(pos-newpos) > 10.0 and not IsPedInParachuteFreeFall(ped) and not still and not IsPedFalling(ped) and GetEntityHeightAboveGround(ped) > 5.0 and spawned and not IsPedInAnyVehicle(ped, false) and not IsPedStill(ped) and not IsPedInAnyBoat(ped) and speed < 1.0 and not IsPedSwimming(ped) and not IsPedSwimmingUnderWater(ped) and not IsEntityInWater(ped) then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti NoClip", webhook, time)
            end

            local newx, newy, newz = table.unpack(GetEntityCoords(Cache.Get("ped"), true))
            local newpos = GetEntityCoords(Cache.Get("ped"))
            if #(pos-newpos) > 10.0 and not IsPedInParachuteFreeFall(Cache.Get("ped")) and not still and not IsPedFalling(Cache.Get("ped")) and GetEntityHeightAboveGround(Cache.Get("ped")) > 5.0 and spawned and not IsPedInAnyVehicle(Cache.Get("ped"), false) and not IsPedStill(Cache.Get("ped")) and not IsPedInAnyBoat(Cache.Get("ped")) and speed < 1.0 and not IsPedSwimming(Cache.Get("ped")) and not IsPedSwimmingUnderWater(Cache.Get("ped")) and not IsEntityInWater(Cache.Get("ped")) then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti NoClip", webhook, time)
            end

        ::continue::
    end
end)