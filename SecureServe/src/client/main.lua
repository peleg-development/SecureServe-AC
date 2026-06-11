RegisterNetEvent("SecureServe:ForceSocialClubUpdate", function()
    ForceSocialClubUpdate()
end)

RegisterNetEvent("SecureServe:ForceUpdate", function()
    ForceSocialClubUpdate()
    NetworkIsPlayerActive(PlayerId())
    NetworkIsPlayerConnected(PlayerId())
end)

-- Fix: we echo back the received nonce to prove the client is actually running; a cheater who removed SecureServe never receives the nonce and cannot guess it.
RegisterNetEvent("checkalive", function (nonce)
    TriggerServerEvent("addalive", nonce)
end)
