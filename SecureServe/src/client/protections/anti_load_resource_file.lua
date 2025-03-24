local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiLoadResourceFileModule
local AntiLoadResourceFile = {}
local loaded_keys = {}
local pendingResourceChecks = {}
local playerLoaded = false

---@description Initialize Anti Load Resource File protection
function AntiLoadResourceFile.initialize()    
    Citizen.CreateThread(function()
        Citizen.Wait(10000)
        playerLoaded = true
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        loaded_keys[resourceName] = nil
    end)

    RegisterNetEvent("SecureServe:Client_Callbacks:Protections:GetResourceStatus", function(stopped, started, restarted)
        if not playerLoaded or stopped or started or restarted then
            for resourceName, _ in pairs(pendingResourceChecks) do
                loaded_keys[resourceName] = true
            end
            pendingResourceChecks = {}
            return
        end
        
        Citizen.SetTimeout(5000, function()
            if playerLoaded then
                for resourceName, _ in pairs(pendingResourceChecks) do
                    if loaded_keys[resourceName] then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                            {
                                reason = "Anti Load Resource File",
                                details = "Resource " .. resourceName .. " attempted to load key multiple times without restart"
                            }, 
                            webhook, 
                            2147483647)
                    end
                    loaded_keys[resourceName] = true
                end
            else
                for resourceName, _ in pairs(pendingResourceChecks) do
                    loaded_keys[resourceName] = true
                end
            end
            pendingResourceChecks = {}
        end)
    end)

    RegisterNetEvent("SecureServe:Client:LoadedKey", function(resourceName)
        pendingResourceChecks[resourceName] = true
        TriggerServerEvent("SecureServe:Server_Callbacks:Protections:GetResourceStatus")
    end)
end

ProtectionManager.register_protection("load_resource_file", AntiLoadResourceFile.initialize)

return AntiLoadResourceFile 