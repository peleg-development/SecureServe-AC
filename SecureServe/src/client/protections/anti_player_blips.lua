local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")

---@class AntiPlayerBlipsModule
local AntiPlayerBlips = {}

---@description Initialize Anti Player Blips protection
function AntiPlayerBlips.initialize()
    if not Anti_Player_Blips_enabled then return end
    
    Citizen.CreateThread(function()
        while true do
            local pid = PlayerId()
            local active_players = GetActivePlayers()

            for i = 1, #active_players do
                if i ~= pid then
                    local player_ped = GetPlayerPed(i)
                    local blip = GetBlipFromEntity(player_ped)

                    if DoesBlipExist(blip) then
                        if not ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) then
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Player Blips", Anti_Player_Blips_webhook, Anti_Player_Blips_time)
                        end
                    end
                end
            end

            Citizen.Wait(15000)
        end
    end)
end

ProtectionManager.register_protection("player_blips", AntiPlayerBlips.initialize)

return AntiPlayerBlips 