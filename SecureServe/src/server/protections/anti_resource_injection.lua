local AntiResourceInjection = {
    whitelisted_server_resources = {},
    startup_complete = false,
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
    -- Fix: monitoring/forensics only. A resource started after startup is logged once, then still auto-whitelisted below and left running; nothing is blocked or banned. This is not an anti-injection protection.
    AntiResourceInjection.startup_complete = true

    AddEventHandler("onResourceStart", function(resourceName)
        if resourceName then
            if AntiResourceInjection.startup_complete and not AntiResourceInjection.whitelisted_server_resources[resourceName] then
                logger.warn("Resource started at runtime (verify it is legitimate): " .. resourceName)
            end
            AntiResourceInjection.whitelisted_server_resources[resourceName] = true
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
