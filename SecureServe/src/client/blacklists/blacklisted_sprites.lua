local ProtectionManager = require("client/protections/protection_manager")

---@class BlacklistedSpritesModule
local BlacklistedSprites = {}

---@description Initialize Blacklisted Sprites check
function BlacklistedSprites.initialize()
    Citizen.CreateThread(function()
        while true do
            for k, v in pairs(SecureServe.Protection.BlacklistedSprites) do
                if HasStreamedTextureDictLoaded(v.sprite) then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Blacklisted Sprite (" .. v.name .. ")", v.webhook, v.time)
                end
            end

            Citizen.Wait(5700)
        end
    end)
end

ProtectionManager.register_protection("blacklisted_sprites", BlacklistedSprites.initialize)

return BlacklistedSprites 