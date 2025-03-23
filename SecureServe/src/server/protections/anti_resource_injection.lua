---@class AntiResourceInjectionModule
local AntiResourceInjection = {
    whitelisted_server_resources = {},
    initial_resources_loaded = false
}

local ban_manager = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")



---@description Initialize the resource injection protection
function AntiResourceInjection.initialize()
    local resourceCount = GetNumResources()
    for i = 0, resourceCount - 1 do
        local resource_name = GetResourceByFindIndex(i)
        if resource_name then
            AntiResourceInjection.whitelisted_server_resources[resource_name] = true
        end
    end
    
    AntiResourceInjection.initial_resources_loaded = true
end

---@param resource_name string The resource name to whitelist
---@return boolean success Whether the resource was successfully whitelisted
function AntiResourceInjection.whitelist_resource(resource_name)
    if not resource_name or resource_name == "" then
        return false
    end
    
    AntiResourceInjection.whitelisted_server_resources[resource_name] = true
    return true
end

---@param resource_name string The resource name to unwhitelist
---@return boolean success Whether the resource was successfully unwhitelisted
function AntiResourceInjection.unwhitelist_resource(resource_name)
    if not resource_name or resource_name == "" or not AntiResourceInjection.whitelisted_server_resources[resource_name] then
        return false
    end
    
    AntiResourceInjection.whitelisted_server_resources[resource_name] = nil
    return true
end

---@param resource_name string The resource name to check
---@return boolean is_whitelisted Whether the resource is whitelisted
function AntiResourceInjection.is_resource_whitelisted(resource_name)
    return AntiResourceInjection.whitelisted_server_resources[resource_name] == true
end

return AntiResourceInjection 