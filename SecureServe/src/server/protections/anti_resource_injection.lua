---@class AntiResourceInjectionModule
local AntiResourceInjection = {}

local ban_manager = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

local whitelisted_server_resources = {}
local initial_resources_loaded = false

---@description Initialize the resource injection protection
function AntiResourceInjection.initialize()
    local resourceCount = GetNumResources()
    for i = 0, resourceCount - 1 do
        local resource_name = GetResourceByFindIndex(i)
        if resource_name then
            whitelisted_server_resources[resource_name] = true
        end
    end
    
    initial_resources_loaded = true
    
    AddEventHandler("onResourceStart", function(resource_name)
        if initial_resources_loaded and not whitelisted_server_resources[resource_name] then
            if config_manager.is_resource_injection_protection_enabled() then
                for _, src in pairs(GetPlayers()) do
                    ban_manager.ban_player(src, "Resource Injection", "New resource injected: " .. resource_name)
                end
                
                StopResource(resource_name)
            end
        end
    end)
    
    AddEventHandler("onResourceListRefresh", function()
        if initial_resources_loaded then
            if config_manager.is_resource_injection_protection_enabled() then
                for _, src in pairs(GetPlayers()) do
                    ban_manager.ban_player(src, "Resource Injection", "Resource list was refreshed")
                end
            end
        end
    end)
end

---@param resource_name string The resource name to whitelist
---@return boolean success Whether the resource was successfully whitelisted
function AntiResourceInjection.whitelist_resource(resource_name)
    if not resource_name or resource_name == "" then
        return false
    end
    
    whitelisted_server_resources[resource_name] = true
    return true
end

---@param resource_name string The resource name to unwhitelist
---@return boolean success Whether the resource was successfully unwhitelisted
function AntiResourceInjection.unwhitelist_resource(resource_name)
    if not resource_name or resource_name == "" or not whitelisted_server_resources[resource_name] then
        return false
    end
    
    whitelisted_server_resources[resource_name] = nil
    return true
end

---@param resource_name string The resource name to check
---@return boolean is_whitelisted Whether the resource is whitelisted
function AntiResourceInjection.is_resource_whitelisted(resource_name)
    return whitelisted_server_resources[resource_name] == true
end

return AntiResourceInjection 