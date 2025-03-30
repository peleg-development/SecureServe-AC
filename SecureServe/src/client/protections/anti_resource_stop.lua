local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")

---@class AntiResourceStopModule
local AntiResourceStop = {}

---@description Initialize Anti Resource Stop protection
function AntiResourceStop.initialize()
   if ConfigLoader.get_protection_setting("Anti Resource Stop", "enabled") then
      AddEventHandler('onClientResourceStart', function(resource_name)
         TriggerServerCallback {
            eventName = 'SecureServe:Server_Callbacks:Protections:GetResourceStatus',
            args = {},
            callback = function(stopped_by_server, started_resources, restarted)
               if not stopped_by_server and not started_resources and not restarted then
                  TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil,
                     "Anti Start Resource " .. resource_name, webhook, time)
               end
            end
         }
      end)
   end

   if ConfigLoader.get_protection_setting("Anti Resource Stop", "enabled") then
      AddEventHandler('onClientResourceStop', function(resource_name)
         TriggerServerCallback {
            eventName = 'SecureServe:Server_Callbacks:Protections:GetResourceStatus',
            args = {},
            callback = function(stopped_by_server, started_resources, restarted)
               if not stopped_by_server and not restarted and not started_resources then
                  TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil,
                     "Anti Stop Resource " .. resource_name, webhook, time)
               end
            end
         }
      end)
   end
end

ProtectionManager.register_protection("resource_stop", AntiResourceStop.initialize)

return AntiResourceStop
