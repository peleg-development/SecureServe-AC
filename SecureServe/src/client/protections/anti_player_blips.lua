local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiPlayerBlips = {}

local WHITELISTED_SPRITES = {
    [1]   = true,
    [2]   = true,
    [3]   = true,
    [4]   = true,
    [5]   = true,
    [6]   = true,
    [7]   = true,
    [8]   = true,
    [56]  = true,
    [57]  = true,
    [58]  = true,
    [60]  = true,
    [82]  = true,
    [83]  = true,
    [84]  = true,
    [161] = true,
    [162] = true,
    [163] = true,
    [184] = true,
    [280] = true,
    [407] = true,
    [408] = true,
    [480] = true,
    [521] = true,
    [526] = true,
}

function AntiPlayerBlips.initialize()
    if not ConfigLoader.get_protection_setting("Anti Player Blips", "enabled") then return end

    Citizen.CreateThread(function()
        local strikes = 0
        local STRIKE_LIMIT = 5

        while true do
            Citizen.Wait(15000)

            if Cache.Get("hasPermission", "playerblips")
                or Cache.Get("hasPermission", "all")
                or Cache.Get("isAdmin")
            then
                strikes = 0
            else
                local pid = PlayerId()
                local active_players = GetActivePlayers()
                local detected_blip_sprite = nil

                for i = 1, #active_players do
                    local player_idx = active_players[i]
                    if player_idx ~= pid then
                        local player_ped = GetPlayerPed(player_idx)
                        local blip = GetBlipFromEntity(player_ped)

                        if DoesBlipExist(blip) then
                            local sprite = GetBlipSprite(blip)
                            if not WHITELISTED_SPRITES[sprite] then
                                detected_blip_sprite = sprite
                                break
                            end
                        end
                    end
                end

                if detected_blip_sprite then
                    strikes = strikes + 1
                    if strikes >= STRIKE_LIMIT then
                        ProtectionHelper.punish('Anti Player Blips',
                            ("Anti Player Blips (sprite: %s)"):format(tostring(detected_blip_sprite)))
                        strikes = 0
                    end
                else
                    if strikes > 0 then strikes = strikes - 1 end
                end
            end
        end
    end)
end

ProtectionManager.register_protection("player_blips", AntiPlayerBlips.initialize)

return AntiPlayerBlips
