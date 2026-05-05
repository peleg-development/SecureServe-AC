local AntiExplosions = {}

local config_manager = require("server/core/config_manager")
local ban_manager    = require("server/core/ban_manager")
local logger         = require("server/core/logger")

local explosions = {}
local detected   = {}

local function cleanup_player(sender)
    explosions[sender] = nil
    detected[sender] = nil
end

function AntiExplosions.initialize()
    AddEventHandler('playerDropped', function()
        local src = source
        if src then cleanup_player(src) end
    end)

    AddEventHandler('explosionEvent', function(sender, ev)
        if not sender then return end

        if ev.ownerNetId == 0 then
            local blacklist = SecureServe.Protection.BlacklistedExplosions or {}
            for _, v in ipairs(blacklist) do
                if ev.explosionType == v.id then
                    CancelEvent()
                    return
                end
            end
            return
        end

        if detected[sender] then
            CancelEvent()
            return
        end

        explosions[sender] = explosions[sender] or {}

        local explosion_info = string.format(
            "Explosion Type: %s, Position: (%.2f, %.2f, %.2f)",
            tostring(ev.explosionType), ev.posX or 0, ev.posY or 0, ev.posZ or 0
        )

        local blacklist = SecureServe.Protection.BlacklistedExplosions or {}
        for _, v in ipairs(blacklist) do
            if ev.explosionType == v.id then
                explosions[sender][v.id] = (explosions[sender][v.id] or 0) + 1

                local function ban(detection)
                    if detected[sender] then return end
                    detected[sender] = true
                    CancelEvent()
                    ban_manager.ban_player(sender, "Blacklisted Explosion", {
                        admin     = "Anti-Cheat System",
                        time      = tonumber(v.time) or 2147483647,
                        detection = detection,
                    })
                end

                if v.limit and explosions[sender][v.id] > v.limit then
                    ban("Exceeded explosion limit at type " .. v.id .. ". " .. explosion_info)
                    return
                end

                if v.audio and ev.isAudible == false then
                    ban("Used inaudible explosion. " .. explosion_info)
                    return
                end

                if v.invisible and ev.isInvisible == true then
                    ban("Used invisible explosion. " .. explosion_info)
                    return
                end

                if v.damageScale and ev.damageScale and ev.damageScale > 1.0 then
                    ban("Used boosted explosion. " .. explosion_info)
                    return
                end

                if SecureServe.Protection.CancelOtherExplosions then
                    CancelEvent()
                end

                return
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000)
            for sender_id in pairs(explosions) do
                if not GetPlayerName(sender_id) then
                    cleanup_player(sender_id)
                end
            end
        end
    end)

    logger.info("Anti-Explosions protection initialized")
end

return AntiExplosions
