---@class ResourceManagerModule
local ResourceManager = {
    stopped_resources = {},
    started_resources = {},
    resource_states = {},
    resources_restarted = {},
}

---@description Initialize the resource manager
function ResourceManager.initialize()
    local seen_starts = {}
    local seen_stops = {}

    RegisterNetEvent("SecureServe:Server_Callbacks:Protections:GetResourceStatus", function()
        local src = source
        local stopped = ResourceManager.stopped_resources[src] and true or false
        local started = ResourceManager.started_resources[src] and true or false
        local restarted = ResourceManager.resources_restarted[src] and true or false

        TriggerClientEvent("SecureServe:Client_Callbacks:Protections:GetResourceStatus", src, stopped, started, restarted)
    end)

    AddEventHandler("onResourceStop", function(resource_name)
        if not resource_name or resource_name == GetCurrentResourceName() then return end

        seen_stops[resource_name] = true
        ResourceManager.resource_states[resource_name] = false

        local players = GetPlayers()
        for _, src in pairs(players) do
            local pid = tonumber(src)
            if pid then ResourceManager.stopped_resources[pid] = resource_name end
        end

        Citizen.SetTimeout(5000, function()
            for _, src in pairs(GetPlayers()) do
                local pid = tonumber(src)
                if pid and ResourceManager.stopped_resources[pid] == resource_name then
                    ResourceManager.stopped_resources[pid] = nil
                end
            end
            seen_stops[resource_name] = nil
        end)
    end)

    AddEventHandler("onResourceStart", function(resource_name)
        if not resource_name then return end

        seen_starts[resource_name] = true
        ResourceManager.resource_states[resource_name] = true

        for _, src in pairs(GetPlayers()) do
            local pid = tonumber(src)
            if pid then ResourceManager.started_resources[pid] = resource_name end
        end

        Citizen.SetTimeout(5000, function()
            for _, src in pairs(GetPlayers()) do
                local pid = tonumber(src)
                if pid and ResourceManager.started_resources[pid] == resource_name then
                    ResourceManager.started_resources[pid] = nil
                end
            end
            seen_starts[resource_name] = nil
        end)
    end)

    AddEventHandler("onResourceListRefresh", function()
        ResourceManager.resources_restarted = {}
        for _, src in pairs(GetPlayers()) do
            local pid = tonumber(src)
            if pid then ResourceManager.resources_restarted[pid] = true end
        end

        Citizen.SetTimeout(5000, function()
            ResourceManager.resources_restarted = {}
        end)
    end)
end

---@param resource_name string Resource name to check
---@return boolean is_started Whether the resource is started
function ResourceManager.is_resource_started(resource_name)
    return ResourceManager.resource_states[resource_name] == true
end

---@param src number Source ID to check
---@return boolean resources_stopped Whether resources were stopped recently for this player
function ResourceManager.were_resources_stopped(src)
    return ResourceManager.stopped_resources[src] == true
end

---@param src number Source ID to check
---@return boolean resources_started Whether resources were started recently for this player
function ResourceManager.were_resources_started(src)
    return ResourceManager.started_resources[src] == true
end

---@param src number Source ID to check
---@return boolean resources_restarted Whether resources were restarted recently for this player
function ResourceManager.were_resources_restarted(src)
    return ResourceManager.resources_restarted[src] == true
end

return ResourceManager 