local Require = require("shared/lib/require")

---@class ClientInit
local ClientInit = {}

---@description Initialize all client components
function ClientInit.initialize()
    local logger = require("client/core/client_logger")
    local ConfigLoader = require("client/core/config_loader")
    
    logger.initialize({
        Debug = false
    })
    
    logger.info("==============================================")
    logger.info("SecureServe Client v1.2.1 initializing...")
    
    ConfigLoader.initialize()
    logger.info("Config Loader initialized")
    
    local secureServe = ConfigLoader.get_secureserve()
    
    local Cache = require("client/core/cache")
    Cache.initialize()
    logger.info("Cache initialized")
    
    Citizen.CreateThread(function()
        Wait(2000) 
        TriggerServerEvent("SecureServe:CheckWhitelist")
    end)
    
    logger.info("Loading Protection Manager...")
    local ProtectionManager = require("client/protections/protection_manager")
    ProtectionManager.initialize()
    logger.info("Protection Manager initialized")
    
    logger.info("Loading Entity Monitor...")
    local EntityMonitor = require("client/core/entity_monitor")
    EntityMonitor.initialize()
    logger.info("Entity Monitor initialized")
    
    logger.info("Loading Blue Screen...")
    local blue_screen = require("client/core/blue_screen")
    blue_screen.initialize()
    logger.info("Blue Screen initialized")

    RegisterNetEvent("SecureServe:UpdateDebugMode", function(enabled)
        local logger = require("client/core/client_logger")
        logger.set_debug_mode(enabled)
    end)
    
    if SecureServeErrorHandler then
        logger.info("Global Error Handler initialized")
    end
    
    logger.info("Client-side components initialized")
    logger.info("==============================================")
end

CreateThread(function()
    Wait(1000) 
    ClientInit.initialize()
end)

return ClientInit