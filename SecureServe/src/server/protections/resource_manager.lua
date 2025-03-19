---@class ResourceManagerModule
local ResourceManager = {}

local stopped_resources = {}
local started_resources = {}
local resource_states = {}
local resources_restarted = {}

---@description Initialize the resource manager
function ResourceManager.initialize()
    RegisterNetEvent("SecureServe:Server_Callbacks:Protections:GetResourceStatus", function()
        local src = source
        local stopped = stopped_resources[src] and true or false
        local started = started_resources[src] and true or false
        local restarted = resources_restarted[src] and true or false
        
        TriggerClientEvent("SecureServe:Client_Callbacks:Protections:GetResourceStatus", src, stopped, started, restarted)
    end)
    
    AddEventHandler("onResourceStop", function(resource_name)
        for _, src in pairs(GetPlayers()) do
            stopped_resources[tonumber(src)] = true
        end
        
        resource_states[resource_name] = false
        
        Citizen.SetTimeout(5000, function()
            for _, src in pairs(GetPlayers()) do
                stopped_resources[tonumber(src)] = false
            end
        end)
    end)
    
    AddEventHandler("onResourceStart", function(resource_name)
        for _, src in pairs(GetPlayers()) do
            started_resources[tonumber(src)] = true
        end
        
        resource_states[resource_name] = true
        
        Citizen.SetTimeout(5000, function()
            for _, src in pairs(GetPlayers()) do
                started_resources[tonumber(src)] = false
            end
        end)
    end)
    
    AddEventHandler("onResourceListRefresh", function()
        resources_restarted = {}
        for _, src in pairs(GetPlayers()) do
            resources_restarted[tonumber(src)] = true
        end
        
        Citizen.SetTimeout(5000, function()
            for _, src in pairs(GetPlayers()) do
                resources_restarted[tonumber(src)] = false
            end
        end)
    end)
    
    AddEventHandler("onResourceStop", function(resource_name)
        if resource_name == GetCurrentResourceName() then
            for _, player in pairs(GetPlayers()) do
                -- DropPlayer(player, "SecureServe anticheat was stopped.")
            end
        end
    end)
end

---@param resource_name string Resource name to check
---@return boolean is_started Whether the resource is started
function ResourceManager.is_resource_started(resource_name)
    return resource_states[resource_name] == true
end

---@param src number Source ID to check
---@return boolean resources_stopped Whether resources were stopped recently for this player
function ResourceManager.were_resources_stopped(src)
    return stopped_resources[src] == true
end

---@param src number Source ID to check
---@return boolean resources_started Whether resources were started recently for this player
function ResourceManager.were_resources_started(src)
    return started_resources[src] == true
end

---@param src number Source ID to check
---@return boolean resources_restarted Whether resources were restarted recently for this player
function ResourceManager.were_resources_restarted(src)
    return resources_restarted[src] == true
end

return ResourceManager 