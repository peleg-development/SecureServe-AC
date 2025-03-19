local Require = require("shared/lib/require")

---@class ClientInit
local ClientInit = {}

---@description Initialize all client components
function ClientInit.initialize()
    print("^8==============================================^7")
    print("^2SecureServe Client v1.2.0 initializing...^7")
    
    local ConfigLoader = require("client/core/config_loader")
    ConfigLoader.initialize()
    print("^5[SUCCESS] ^3Config Loader^7 initialized")

    local Cache = require("client/core/cache")
    Cache.initialize()
    print("^5[SUCCESS] ^3Cache^7 initialized")
    
    local ProtectionManager = require("client/protections/protection_manager")
    print("^5[LOADING] ^3Protection Manager^7")
    ProtectionManager.initialize()
    print("^5[SUCCESS] ^3Protection Manager^7 initialized")
    
    print("^5[LOADING] ^3Entity Monitor^7")
    local EntityMonitor = require("client/core/entity_monitor")
    EntityMonitor.initialize()
    print("^5[SUCCESS] ^3Entity Monitor^7 initialized")
    
    RegisterNetEvent("checkalive", function()
        TriggerServerEvent("addalive")
    end)
    
    if SecureServeErrorHandler then
        print("^5[SUCCESS] ^3Global Error Handler^7 initialized")
    end
    
    print("^5[SUCCESS] ^3Client-side components^7 initialized")
    print("^8==============================================^7")
end

CreateThread(function()
    Wait(1000) 
    ClientInit.initialize()
end)

return ClientInit 