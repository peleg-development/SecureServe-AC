---@class Cache
local Cache = {}
local config_loader = require("client/core/config_loader")

Cache.Values = {
    ped = nil,
    vehicle = nil,
    isInVehicle = false,
    isSwimming = false,
    isSwimmingUnderWater = false,
    isFalling = false,
    isInvisible = false,
    health = 0,
    armor = 0,
    coords = vector3(0,0,0),
    lastUpdate = 0,
    selectedWeapon = nil,
    damageTaken = false,
    isAdmin = false,
    permissions = {},
    permissionsLastUpdate = 0
}

Cache.UpdateIntervals = {
    coords = 1000,       
    selectedWeapon = 2500, 
    ped = 5000,
    permissions = 30000,  -- Check permissions every 30 seconds    
    default = 3000    
}

Cache.LastUpdated = {}
Cache.LastValues = {}   

local updateThreads = {}

---@description Initialize the cache
function Cache.initialize()
    for _, threadId in pairs(updateThreads) do
        if threadId then
            TerminateThread(threadId)
        end
    end
    updateThreads = {}
    
    Cache.UpdateAll()
    Cache.StartUpdateThreads()
    
    -- Request permission check on initialization
    Cache.RequestPermissionCheck()
end

function Cache.UpdateAll()
    local currentTime = GetGameTimer()
    Cache.Values.lastUpdate = currentTime
    
    local ped = PlayerPedId()
    Cache.Values.ped = ped
    
    for k, v in pairs(Cache.Values) do
        Cache.LastValues[k] = v
        Cache.LastUpdated[k] = currentTime
    end
    
    Cache.Values.health = GetEntityHealth(ped)
    Cache.Values.armor = GetPedArmour(ped)
    Cache.Values.coords = GetEntityCoords(ped)
    Cache.Values.selectedWeapon = GetSelectedPedWeapon(ped)
    Cache.Values.isInVehicle = IsPedInAnyVehicle(ped, false)
    if Cache.Values.isInVehicle then
        Cache.Values.vehicle = GetVehiclePedIsIn(ped, false)
    else
        Cache.Values.vehicle = nil
    end
    
    Cache.Values.isSwimming = IsPedSwimming(ped)
    Cache.Values.isSwimmingUnderWater = IsPedSwimmingUnderWater(ped)
    Cache.Values.isFalling = IsPedFalling(ped)
    Cache.Values.isInvisible = IsEntityVisible(ped) == 0
    Cache.Values.isAdmin = config_loader.is_whitelisted(GetPlayerServerId(PlayerId())) 
end

function Cache.Get(key, subKey)
    local currentTime = GetGameTimer()
    local updateInterval = Cache.UpdateIntervals[key] or Cache.UpdateIntervals.default
    
    -- Handle special case for permission check
    if key == "hasPermission" and subKey then
        Cache.CheckPermission(subKey)
        return Cache.Values.permissions[subKey] or false
    end
    
    if not Cache.LastUpdated[key] or (currentTime - Cache.LastUpdated[key]) > updateInterval then
        Cache.ForceUpdate(key)
    end
    
    return Cache.Values[key]
end

function Cache.ForceUpdate(key)
    local currentTime = GetGameTimer()
    local ped = Cache.Values.ped
    
    if currentTime - (Cache.LastUpdated["ped"] or 0) > Cache.UpdateIntervals.ped then
        ped = PlayerPedId()
        Cache.Values.ped = ped
        Cache.LastUpdated["ped"] = currentTime
    end
    
    if key == "ped" then
    elseif key == "vehicle" then
        if Cache.Values.isInVehicle then
            Cache.Values.vehicle = GetVehiclePedIsIn(ped, false)
        else
            Cache.Values.vehicle = nil
        end
    elseif key == "isInVehicle" then
        Cache.Values.isInVehicle = IsPedInAnyVehicle(ped, false)
    elseif key == "isSwimming" then
        Cache.Values.isSwimming = IsPedSwimming(ped)
    elseif key == "isSwimmingUnderWater" then
        Cache.Values.isSwimmingUnderWater = IsPedSwimmingUnderWater(ped)
    elseif key == "isFalling" then
        Cache.Values.isFalling = IsPedFalling(ped)
    elseif key == "isInvisible" then
        Cache.Values.isInvisible = IsEntityVisible(ped) == 0
    elseif key == "health" then
        Cache.Values.health = GetEntityHealth(ped)
    elseif key == "armor" then
        Cache.Values.armor = GetPedArmour(ped)
    elseif key == "coords" then
        Cache.Values.coords = GetEntityCoords(ped)
    elseif key == "selectedWeapon" then
        Cache.Values.selectedWeapon = GetSelectedPedWeapon(ped)
    elseif key == "isAdmin" then
        Cache.Values.isAdmin = config_loader.is_whitelisted(GetPlayerServerId(PlayerId()))
    elseif key == "permissions" then
        Cache.RequestPermissionCheck()
    end
    
    Cache.LastUpdated[key] = currentTime
    
    Cache.LastValues[key] = Cache.Values[key]
end

function Cache.StartUpdateThreads()
    local updateGroups = {
        fast = {
            interval = 1000,
            keys = {"coords", "selectedWeapon"}
        },
        medium = {
            interval = 2500,
            keys = {"isInVehicle", "vehicle", "health", "armor", "isFalling"}
        },
        slow = {
            interval = 5000,
            keys = {"isSwimming", "isSwimmingUnderWater", "isInvisible", "isAdmin"}
        },
        permission = {
            interval = 30000, -- Every 30 seconds
            keys = {"permissions"}
        }
    }
    
    for groupName, groupData in pairs(updateGroups) do
        updateThreads[groupName] = Citizen.CreateThread(function()
            while true do
                Citizen.Wait(groupData.interval)
                
                if groupName == "slow" then
                    local ped = PlayerPedId()
                    Cache.Values.ped = ped
                    Cache.LastUpdated["ped"] = GetGameTimer()
                end
                
                for _, key in ipairs(groupData.keys) do
                    Cache.ForceUpdate(key)
                end
            end
        end)
    end
end

---@description Request permission check from server
function Cache.RequestPermissionCheck()
    TriggerServerEvent("SecureServe:RequestPermissions")
    Cache.Values.permissionsLastUpdate = GetGameTimer()
    Cache.LastUpdated["permissions"] = GetGameTimer()
end

---@description Check if player has specific permission
---@param permission string The permission to check
function Cache.CheckPermission(permission)
    local currentTime = GetGameTimer()
    -- If permissions haven't been checked recently, request an update
    if currentTime - Cache.Values.permissionsLastUpdate > Cache.UpdateIntervals.permissions then
        Cache.RequestPermissionCheck()
    end
end

-- Event handler for receiving permissions from server
RegisterNetEvent("SecureServe:ReceivePermissions", function(permissions)
    Cache.Values.permissions = permissions or {}
    Cache.Values.permissionsLastUpdate = GetGameTimer()
    Cache.LastUpdated["permissions"] = GetGameTimer()
end)

AddEventHandler("gameEventTriggered", function(name, args)
    if name == "CEventNetworkEntityDamage" then
        local victim = args[1]
        if victim == Cache.Values.ped then
            Cache.Values.damageTaken = true
            Cache.ForceUpdate("health")
            Cache.ForceUpdate("armor")
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, threadId in pairs(updateThreads) do
        if threadId then
            TerminateThread(threadId)
        end
    end
    
    updateThreads = {}
    Cache.Values = {}
    Cache.LastUpdated = {}
    Cache.LastValues = {}
end)

return Cache