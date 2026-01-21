---@class ClientInit
local ClientInit = {}

---@description Initialize all client components
function ClientInit.initialize()
    local logger = require("client/core/client_logger")
    logger.initialize({ Debug = false })
    
    local function run_init(name, init_fn)
        local ok, err = pcall(init_fn)
        if not ok then
            logger.error(name .. " init failed: " .. tostring(err))
            return false
        end
        logger.info(name .. " initialized")
        return true
    end
    
    run_init("Config Loader", ConfigLoader.initialize)
    run_init("Cache", function()
        require("client/core/cache").initialize()
    end)
    run_init("Protection Manager", function()
        require("client/protections/protection_manager").initialize()
    end)
    run_init("Blue Screen", function()
        require("client/core/blue_screen").initialize()
    end)
    
    Citizen.CreateThread(function()
        Wait(2000)
        TriggerServerEvent("SecureServe:CheckWhitelist")
    end)
end

CreateThread(function()
    Wait(1000) 
    ClientInit.initialize()
end)

return ClientInit