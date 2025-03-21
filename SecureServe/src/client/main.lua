RegisterNetEvent("SecureServe:ForceSocialClubUpdate", function()
    ForceSocialClubUpdate()
end)

RegisterNetEvent("SecureServe:ForceUpdate", function()
    ForceSocialClubUpdate()
    NetworkIsPlayerActive(PlayerId())
    NetworkIsPlayerConnected(PlayerId())
end)

RegisterNetEvent("SecureServe:ShowBanCard", function(cardData)
    local isBanned = true
    
    ForceSocialClubUpdate()
    
    if cardData then
        SendNUIMessage({
            type = "ban_card",
            card = cardData
        })
    end
end)

RegisterNetEvent("SecureServe:ShowPermaBanCard", function(cardData)
    
    ForceSocialClubUpdate()
    
end) 