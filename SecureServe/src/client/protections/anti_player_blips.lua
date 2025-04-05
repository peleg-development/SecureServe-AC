local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiPlayerBlipsModule
local AntiPlayerBlips = {}

---@description Initialize Anti Player Blips protection
function AntiPlayerBlips.initialize()
    if not ConfigLoader.get_protection_setting("Anti Player Blips", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do    
            Citizen.Wait(15000)
  
            if Cache.Get("hasPermission", "playerblips") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end

            local pid = PlayerId()
            local active_players = GetActivePlayers()

            for i = 1, #active_players do
                if i ~= pid then
                    local player_ped = GetPlayerPed(i)
                    local blip = GetBlipFromEntity(player_ped)

                    if DoesBlipExist(blip) then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Player Blips", webhook, time)
                    end
                end
            end
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("player_blips", AntiPlayerBlips.initialize)

return AntiPlayerBlips 