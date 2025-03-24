RegisterNetEvent("SecureServe:ForceSocialClubUpdate", function()
    ForceSocialClubUpdate()
end)

RegisterNetEvent("SecureServe:ForceUpdate", function()
    ForceSocialClubUpdate()
    NetworkIsPlayerActive(PlayerId())
    NetworkIsPlayerConnected(PlayerId())
end)

RegisterNetEvent("SecureServe:ShowPermaBanCard", function(cardData)
    ForceSocialClubUpdate()
end) 


RegisterNetEvent("checkalive", function ()
    TriggerServerEvent("addalive")
end)

RegisterNetEvent("SecureServe:Client:getEncryptionKey", function(key)
end)
