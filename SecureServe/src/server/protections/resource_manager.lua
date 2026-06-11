local ResourceManager = {
    stopped_resources = {},
    started_resources = {},
    resource_states = {},
    resources_restarted = {},
    initialized = false,
}

local STATUS_WINDOW_MS = 5000

local function setPlayerFlag(store, src, value)
    local player = tonumber(src)
    if player then
        store[player] = value == true or nil
    end
end

local function setAllPlayersFlag(store, value)
    for _, playerId in ipairs(GetPlayers()) do
        setPlayerFlag(store, playerId, value)
    end
end

local function clearAllPlayersFlagLater(store)
    Citizen.SetTimeout(STATUS_WINDOW_MS, function()
        for playerId in pairs(store) do
            store[playerId] = nil
        end
    end)
end

local function sendStatus(src)
    local player = tonumber(src)
    if not player then return end

    TriggerClientEvent(
        "SecureServe:Client_Callbacks:Protections:GetResourceStatus",
        player,
        ResourceManager.stopped_resources[player] == true,
        ResourceManager.started_resources[player] == true,
        ResourceManager.resources_restarted[player] == true
    )
end

local function markResourceStopped(resourceName)
    ResourceManager.resource_states[resourceName] = false
    setAllPlayersFlag(ResourceManager.stopped_resources, true)
    clearAllPlayersFlagLater(ResourceManager.stopped_resources)
end

local function markResourceStarted(resourceName)
    ResourceManager.resource_states[resourceName] = true
    setAllPlayersFlag(ResourceManager.started_resources, true)
    clearAllPlayersFlagLater(ResourceManager.started_resources)
end

local function markResourceListRefreshed()
    ResourceManager.resources_restarted = {}
    setAllPlayersFlag(ResourceManager.resources_restarted, true)
    clearAllPlayersFlagLater(ResourceManager.resources_restarted)
end

function ResourceManager.initialize()
    if ResourceManager.initialized then return end
    ResourceManager.initialized = true

    RegisterNetEvent("SecureServe:Server_Callbacks:Protections:GetResourceStatus", function()
        sendStatus(source)
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        markResourceStopped(resourceName)
    end)

    AddEventHandler("onResourceStart", function(resourceName)
        markResourceStarted(resourceName)
    end)

    AddEventHandler("onResourceListRefresh", markResourceListRefreshed)

    AddEventHandler("playerDropped", function()
        local src = tonumber(source)
        if not src then return end

        ResourceManager.stopped_resources[src] = nil
        ResourceManager.started_resources[src] = nil
        ResourceManager.resources_restarted[src] = nil
    end)
end

function ResourceManager.is_resource_started(resourceName)
    return ResourceManager.resource_states[resourceName] == true
end

function ResourceManager.were_resources_stopped(src)
    return ResourceManager.stopped_resources[tonumber(src)] == true
end

function ResourceManager.were_resources_started(src)
    return ResourceManager.started_resources[tonumber(src)] == true
end

function ResourceManager.were_resources_restarted(src)
    return ResourceManager.resources_restarted[tonumber(src)] == true
end

return ResourceManager
