local Require = require("shared/lib/require")

---@class ClientInit
local ClientInit = {}

---@description Initialize all client components
function ClientInit.initialize()
    local logger = require("client/core/client_logger")
    logger.initialize({
        Debug = _G.SecureServe and _G.SecureServe.Debug or false
    })
    
    logger.info("==============================================")
    logger.info("SecureServe Client v1.2.0 initializing...")
    
    local ConfigLoader = require("client/core/config_loader")
    ConfigLoader.initialize()
    logger.info("Config Loader initialized")
    

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
    
    RegisterNetEvent("checkalive", function()
        TriggerServerEvent("addalive")
    end)
    
    RegisterNetEvent("SecureServe:ShowBanCard", function(card)
        local hw = GetDuiHandle(CreateDui("https://i.imgur.com/SIDaGgG.png", 1, 1))
        
        -- Display the card for 3 seconds before disconnect
        Citizen.CreateThread(function()
            local scaleform = RequestScaleformMovie("mp_big_message_freemode")
            
            while not HasScaleformMovieLoaded(scaleform) do
                Citizen.Wait(0)
            end
            
            BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
            PushScaleformMovieMethodParameterString("~r~ACCESS DENIED")
            PushScaleformMovieMethodParameterString("You have been banned from this server")
            EndScaleformMovieMethod()
            
            local startTime = GetGameTimer()
            local displayTime = 3000
            
            while (GetGameTimer() - startTime) < displayTime do
                DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
                Citizen.Wait(0)
            end
        end)
    end)
    
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