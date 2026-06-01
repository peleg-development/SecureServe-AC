RegisterNetEvent("SecureServe:ForceSocialClubUpdate", function()
    ForceSocialClubUpdate()
end)

RegisterNetEvent("SecureServe:ForceUpdate", function()
    ForceSocialClubUpdate()
    NetworkIsPlayerActive(PlayerId())
    NetworkIsPlayerConnected(PlayerId())
end)

RegisterNetEvent("SecureServe:Heartbeat:Check", function ()
    TriggerServerEvent("SecureServe:Heartbeat:AddAlive")
end)

-- //[SecureFreeze]\\ --
-- El server manda este evento (via /securefreeze id) para congelar al player.
local _freeze_active = false
RegisterNetEvent("SecureServe:Freeze", function(state)
    _freeze_active = state == true
    if _freeze_active then
        CreateThread(function()
            while _freeze_active do
                local ped = PlayerPedId()
                if ped and DoesEntityExist(ped) then
                    FreezeEntityPosition(ped, true)
                end
                Wait(500)
            end
            local ped = PlayerPedId()
            if ped and DoesEntityExist(ped) then
                FreezeEntityPosition(ped, false)
            end
        end)
    end
end)
