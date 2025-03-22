---@class Cache
local Cache = {}

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
    selectedWeapon = nil
}

Cache.LastUpdated = {}

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
end

local UPDATE_INTERVAL = 2000

function Cache.UpdateAll()
    local currentTime = GetGameTimer()
    Cache.Values.lastUpdate = currentTime
    
    Cache.Values.ped = PlayerPedId()
    Cache.Values.health = GetEntityHealth(Cache.Values.ped)
    Cache.Values.armor = GetPedArmour(Cache.Values.ped)
    Cache.Values.coords = GetEntityCoords(Cache.Values.ped)
    Cache.Values.selectedWeapon = GetSelectedPedWeapon(Cache.Values.ped)
    Cache.Values.isInVehicle = IsPedInAnyVehicle(Cache.Values.ped, false)
    if Cache.Values.isInVehicle then
        Cache.Values.vehicle = GetVehiclePedIsIn(Cache.Values.ped, false)
    else
        Cache.Values.vehicle = nil
    end
    
    Cache.Values.isSwimming = IsPedSwimming(Cache.Values.ped)
    Cache.Values.isSwimmingUnderWater = IsPedSwimmingUnderWater(Cache.Values.ped)
    Cache.Values.isFalling = IsPedFalling(Cache.Values.ped)
    Cache.Values.isInvisible = IsEntityVisible(Cache.Values.ped) == 0
    
    for k in pairs(Cache.Values) do
        Cache.LastUpdated[k] = currentTime
    end
end

function Cache.Get(key)
    local currentTime = GetGameTimer()
    local keyUpdateInterval = key == "coords" and 800 or UPDATE_INTERVAL
    
    if not Cache.LastUpdated[key] or (currentTime - Cache.LastUpdated[key]) > keyUpdateInterval then
        Cache.ForceUpdate(key)
    end
    
    return Cache.Values[key]
end

function Cache.ForceUpdate(key)
    local currentTime = GetGameTimer()
    local ped = PlayerPedId()
    
    if key == "ped" then
        Cache.Values.ped = ped
    elseif key == "vehicle" then
        Cache.Values.vehicle = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or nil
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
    end
    
    Cache.LastUpdated[key] = currentTime
end

-- Use a single consolidated thread to reduce overhead
function Cache.StartUpdateThreads()
    updateThreads.main = Citizen.CreateThread(function()
        local gc_counter = 0
        local gc_interval = 10 
        
        while true do
            Cache.ForceUpdate("coords")
            Citizen.Wait(200) 
            
            Cache.ForceUpdate("ped")
            Cache.ForceUpdate("isInVehicle")
            Citizen.Wait(200) 
            
            Cache.ForceUpdate("health")
            Cache.ForceUpdate("armor")
            Citizen.Wait(200) 
            
            if Cache.Values.isInVehicle then
                Cache.ForceUpdate("vehicle")
            end
            Citizen.Wait(200) 
            
            Cache.ForceUpdate("selectedWeapon")
            Citizen.Wait(200) 
            
            Cache.ForceUpdate("isSwimming")
            Cache.ForceUpdate("isSwimmingUnderWater")
            Cache.ForceUpdate("isFalling")
            Cache.ForceUpdate("isInvisible")
            
            gc_counter = gc_counter + 1
            if gc_counter >= gc_interval then
                collectgarbage("step", 100) 
                gc_counter = 0
            end
            
            Citizen.Wait(800) 
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, threadId in pairs(updateThreads) do
        if threadId then
            TerminateThread(threadId)
        end
    end
    
    Cache.Values = {}
    Cache.LastUpdated = {}
    updateThreads = {}
    
    collectgarbage("collect")
end)

return Cache 