local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiVehicleModifierModule
local AntiVehicleModifier = {}

local detectionCount = 0
local lastCheck = 0

---@description Check for illegal vehicle modifications
local function checkVehicleModifications()
    local ped = Cache.Get("ped")
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then return end
    
    -- Get config values
    local maxEngine = ConfigLoader.get_protection_setting("Anti Vehicle Modifier", "default") or 1.5
    local maxTorque = ConfigLoader.get_protection_setting("Anti Vehicle Modifier", "defaultr") or 1.5
    local minMass = ConfigLoader.get_protection_setting("Anti Vehicle Modifier", "defaults") or 50.0
    local maxGrip = ConfigLoader.get_protection_setting("Anti Vehicle Modifier", "tolerance") or 5.0
    
    -- Check engine power multiplier
    local enginePower = GetVehicleEnginePowerMultiplier(vehicle)
    if enginePower > maxEngine then
        detectionCount = detectionCount + 1
        SetVehicleEnginePowerMultiplier(vehicle, 1.0)
        
        if detectionCount >= 3 then
            detectionCount = 0
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                "Anti Vehicle Modifier", webhook, time, 
                string.format("Illegal engine power: %.2f (Max: %.2f)", enginePower, maxEngine))
        end
        return
    end
    
    -- Check torque multiplier
    local torque = GetVehicleEngineTorqueMultiplier(vehicle)
    if torque > maxTorque then
        detectionCount = detectionCount + 1
        SetVehicleEngineTorqueMultiplier(vehicle, 1.0)
        
        if detectionCount >= 3 then
            detectionCount = 0
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                "Anti Vehicle Modifier", webhook, time,
                string.format("Illegal torque: %.2f (Max: %.2f)", torque, maxTorque))
        end
        return
    end
    
    -- Check vehicle mass (detecting weight modification)
    local mass = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass')
    if mass < minMass then
        detectionCount = detectionCount + 1
        
        if detectionCount >= 3 then
            detectionCount = 0
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                "Anti Vehicle Modifier", webhook, time,
                string.format("Illegal vehicle mass: %.2f (Min: %.2f)", mass, minMass))
        end
        return
    end
    
    -- Check traction/grip modifications
    local tractionCurveMax = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax')
    if tractionCurveMax > maxGrip then
        detectionCount = detectionCount + 1
        
        if detectionCount >= 3 then
            detectionCount = 0
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                "Anti Vehicle Modifier", webhook, time,
                string.format("Illegal traction: %.2f (Max: %.2f)", tractionCurveMax, maxGrip))
        end
        return
    end
    
    -- Check for gravity modifications on vehicle
    local velocity = GetEntityVelocity(vehicle)
    local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
    
    -- If vehicle is moving upward without jumping (possible gravity modification)
    if not IsEntityInAir(vehicle) and velocity.z > 5.0 and speed > 10.0 then
        detectionCount = detectionCount + 1
        
        if detectionCount >= 2 then
            detectionCount = 0
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                "Anti Vehicle Modifier", webhook, time,
                "Detected vehicle gravity modification")
        end
    end
end

function AntiVehicleModifier.initialize()
    if not ConfigLoader.get_protection_setting("Anti Vehicle Modifier", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2000)
            
            if Cache.Get("hasPermission", "vehicle_modifier") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end
            
            local currentTime = GetGameTimer()
            if currentTime - lastCheck >= 2000 then
                lastCheck = currentTime
                checkVehicleModifications()
            end
            
            ::continue::
        end
    end)
    
    -- Reset detection count periodically
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(30000)
            detectionCount = 0
        end
    end)
end

ProtectionManager.register_protection("vehicle_modifier", AntiVehicleModifier.initialize)
return AntiVehicleModifier
