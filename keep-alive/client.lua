AddEventHandler("playerSpawned", function ()
    TriggerServerEvent('allowedStop')
end)

Citizen.CreateThread(function() 
    TriggerServerEvent('allowedStop')
end)