local AntiResourceInjection = {
    whitelisted_server_resources = {},
}

local logger = require("server/core/logger")

function AntiResourceInjection.initialize()
    local n = GetNumResources()
    for i = 0, n - 1 do
        local name = GetResourceByFindIndex(i)
        if name then
            AntiResourceInjection.whitelisted_server_resources[name] = true
        end
    end

    AddEventHandler("onResourceStart", function(resourceName)
        if resourceName then
            AntiResourceInjection.whitelisted_server_resources[resourceName] = true
            logger.debug("Resource added to whitelist: " .. resourceName)
        end
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName and resourceName ~= GetCurrentResourceName() then
            AntiResourceInjection.whitelisted_server_resources[resourceName] = nil
        end
    end)

    logger.info("Anti Resource Injection initialized with " ..
        tostring(n) .. " whitelisted resources")
end

function AntiResourceInjection.whitelist_resource(name)
    if not name or name == "" then return false end
    AntiResourceInjection.whitelisted_server_resources[name] = true
    return true
end

function AntiResourceInjection.unwhitelist_resource(name)
    if not name or name == "" then return false end
    if not AntiResourceInjection.whitelisted_server_resources[name] then return false end
    AntiResourceInjection.whitelisted_server_resources[name] = nil
    return true
end

function AntiResourceInjection.is_resource_whitelisted(name)
    return AntiResourceInjection.whitelisted_server_resources[name] == true
end

return AntiResourceInjection
