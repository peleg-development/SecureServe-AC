---@class UtilsLib
local Utils = {}

---@param length number The length of the random string to generate
---@return string The generated random string
function Utils.random_key(length)
    local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local random_string = ""

    for i = 1, length do
        local random_index = math.random(1, #characters)
        random_string = random_string .. characters:sub(random_index, random_index)
    end

    return random_string
end

local entity_enumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
        enum.destructor = nil
        enum.handle = nil
    end
}

---@param init_func function Function to initialize enumeration
---@param move_func function Function to move to next entity
---@param dispose_func function Function to dispose enumeration
---@return function Iterator function
function Utils.enumerate_entities(init_func, move_func, dispose_func)
    return coroutine.wrap(function()
        local iter, id = init_func()
        if not id or id == 0 then
            dispose_func(iter)
            return
        end

        local enum = { handle = iter, destructor = dispose_func }
        setmetatable(enum, entity_enumerator)

        local next = true
        repeat
            coroutine.yield(id)
            next, id = move_func(iter)
        until not next

        enum.destructor, enum.handle = nil, nil
        dispose_func(iter)
    end)
end

---@return function Iterator function to enumerate objects
function Utils.enumerate_objects()
    return Utils.enumerate_entities(FindFirstObject, FindNextObject, EndFindObject)
end

---@return function Iterator function to enumerate peds
function Utils.enumerate_peds()
    return Utils.enumerate_entities(FindFirstPed, FindNextPed, EndFindPed)
end

---@return function Iterator function to enumerate vehicles
function Utils.enumerate_vehicles()
    return Utils.enumerate_entities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

---@return function Iterator function to enumerate pickups
function Utils.enumerate_pickups()
    return Utils.enumerate_entities(FindFirstPickup, FindNextPickup, EndFindPickup)
end

---@return table Table of entity enumeration functions
function Utils.get_all_enumerators()
    return {
        vehicles = Utils.enumerate_vehicles,
        objects = Utils.enumerate_objects,
        peds = Utils.enumerate_peds,
        pickups = Utils.enumerate_pickups
    }
end

Utils.RandomKey = Utils.random_key
Utils.EnumerateEntities = Utils.enumerate_entities
Utils.EnumerateObjects = Utils.enumerate_objects
Utils.EnumeratePeds = Utils.enumerate_peds
Utils.EnumerateVehicles = Utils.enumerate_vehicles
Utils.EnumeratePickups = Utils.enumerate_pickups
Utils.GetAllEnumerators = Utils.get_all_enumerators


return Utils 