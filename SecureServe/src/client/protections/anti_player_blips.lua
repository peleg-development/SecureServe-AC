local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper = require("client/core/protection_helper")
local Cache = require("client/core/cache")

local AntiPlayerBlips = {}

local WHITELISTED_SPRITES = {
    [1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,
    [9]=true,[10]=true,[11]=true,[12]=true,[13]=true,[14]=true,[15]=true,
    [42]=true,[43]=true,[51]=true,[56]=true,[57]=true,[58]=true,[60]=true,
    [66]=true,[67]=true,[68]=true,[69]=true,[71]=true,[73]=true,[74]=true,
    [80]=true,[82]=true,[83]=true,[84]=true,[85]=true,[126]=true,[143]=true,
    [161]=true,[162]=true,[163]=true,[184]=true,[225]=true,[227]=true,
    [251]=true,[252]=true,[253]=true,[254]=true,[280]=true,[303]=true,
    [318]=true,[357]=true,[369]=true,[407]=true,[408]=true,[423]=true,
    [438]=true,[459]=true,[464]=true,[470]=true,[473]=true,[480]=true,
    [521]=true,[526]=true,[535]=true,[536]=true,[541]=true,[542]=true,
    [543]=true,[605]=true,[614]=true,
}

local function load_extra_sprites()
    if SecureServe and SecureServe.Protection and SecureServe.Protection.WhitelistedBlipSprites then
        for _, sprite in ipairs(SecureServe.Protection.WhitelistedBlipSprites) do
            WHITELISTED_SPRITES[tonumber(sprite) or -1] = true
        end
    end
end

function AntiPlayerBlips.initialize()
    if not ConfigLoader.get_protection_setting("Anti Player Blips", "enabled") then return end

    load_extra_sprites()

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
                goto continue
            end

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

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("player_blips", AntiPlayerBlips.initialize)

return AntiPlayerBlips
