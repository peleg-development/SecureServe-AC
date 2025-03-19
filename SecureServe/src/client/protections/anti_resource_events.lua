local ProtectionManager = require("client/protections/protection_manager")

---@class AntiResourceEventsModule
local AntiResourceEvents = {}

---@description Initialize Anti Resource Events protection
function AntiResourceEvents.initialize()
    if Anti_Resource_Starter_enabled then
        AddEventHandler('onClientResourceStart', function(resource_name)
            TriggerServerCallback {
                eventName = 'SecureServe:Server_Callbacks:Protections:GetResourceStatus',
                args = {},
                callback = function(stopped_by_server, started_resources, restarted)
                    if not stopped_by_server and not started_resources and not restarted then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Start Resource " .. resource_name, Anti_Resource_Starter_webhook, Anti_Resource_Starter_time)
                    end
                end
            }
        end)
    end

    if Anti_Resource_Stopper_enabled then
        AddEventHandler('onClientResourceStop', function(resource_name)
            TriggerServerCallback {
                eventName = 'SecureServe:Server_Callbacks:Protections:GetResourceStatus',
                args = {},
                callback = function(stopped_by_server, started_resources, restarted)
                    if not stopped_by_server and not restarted and not started_resources then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti Stop Resource " .. resource_name, Anti_Resource_Stopper_webhook, Anti_Resource_Stopper_time)
                    end
                end
            }
        end)
    end
end

ProtectionManager.register_protection("resource_events", AntiResourceEvents.initialize)

return AntiResourceEvents 