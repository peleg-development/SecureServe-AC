local ClientInit = {}
local initialized = false

function ClientInit.initialize()
    if initialized then return end
    initialized = true

    local logger = require("client/core/client_logger")
    logger.initialize({ Debug = false })

    local function run(name, fn)
        local ok, err = pcall(fn)
        if not ok then
            logger.error(name .. " init failed: " .. tostring(err))
            return false
        end
        logger.info(name .. " initialized")
        return true
    end

    run("Config Loader", function()
        if ConfigLoader and ConfigLoader.initialize then
            ConfigLoader.initialize()
        end
    end)

    run("Cache", function()
        require("client/core/cache").initialize()
    end)

    run("Protection Manager", function()
        require("client/protections/protection_manager").initialize()
    end)

    run("Blue Screen", function()
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
