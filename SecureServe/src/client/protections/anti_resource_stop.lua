local ProtectionManager = require("client/protections/protection_manager")

---@class AntiResourceStopModule
local AntiResourceStop = {}
local playerLoaded = false

CreateThread(function()
    while GetIsLoadingScreenActive() or not DoesEntityExist(PlayerPedId()) do
        Wait(500)
    end
    
    Wait(3000) 
    playerLoaded = true
end)

local function checkResource(action, resourceName)
    if not playerLoaded or resourceName == GetCurrentResourceName() then return end

    TriggerServerCallback {
        eventName = 'SecureServe:Server_Callbacks:Protections:GetResourceStatus',
        args = {},
        callback = function(stopped_by_server, started_resources, restarted)
            local authorized = false
            
            -- Validar lógica según la acción (Start/Stop)
            if action == "Start" and (started_resources or restarted) then authorized = true end
            if action == "Stop" and (stopped_by_server or restarted) then authorized = true end

            if not authorized then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                    "Anti Resource " .. action .. ": " .. resourceName, webhook, time)
            end
        end
    }
end

---@description Initialize Anti Resource Stop protection
function AntiResourceStop.initialize()
    if ConfigLoader.get_protection_setting("Anti Resource Stop", "enabled") then
        AddEventHandler('onClientResourceStart', function(resource_name)
            checkResource("Start", resource_name)
        end)

        AddEventHandler('onClientResourceStop', function(resource_name)
            checkResource("Stop", resource_name)
        end)
    end
end

ProtectionManager.register_protection("resource_stop", AntiResourceStop.initialize)

return AntiResourceStop