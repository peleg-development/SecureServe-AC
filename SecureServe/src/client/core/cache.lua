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

---@description Initialize the cache
function Cache.initialize()
    Cache.UpdateAll()
end

local UPDATE_INTERVAL = 1000

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
end

function Cache.Get(key)
    local currentTime = GetGameTimer()
    if currentTime - Cache.Values.lastUpdate > UPDATE_INTERVAL then
        Cache.UpdateAll()
    end
    return Cache.Values[key]
end

function Cache.ForceUpdate(key)
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
end

Citizen.CreateThread(function()
    while true do
        Cache.UpdateAll()
        Citizen.Wait(UPDATE_INTERVAL)
    end
end)

return Cache 