RegisterNetEvent("SecureServe:ForceSocialClubUpdate", function()
    ForceSocialClubUpdate()
end)

RegisterNetEvent("SecureServe:ForceUpdate", function()
    ForceSocialClubUpdate()
    NetworkIsPlayerActive(PlayerId())
    NetworkIsPlayerConnected(PlayerId())
end)

RegisterNetEvent("checkalive", function ()
    TriggerServerEvent("addalive")
end)
