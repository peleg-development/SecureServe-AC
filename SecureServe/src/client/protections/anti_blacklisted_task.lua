local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiBlacklistedTaskModule
local AntiBlacklistedTask = {}

local taskSpamCount = 0
local lastTaskTime = 0
local detectionCount = 0
local clearTasksCount = 0
local lastClearTaskTime = 0
local recentTasks = {}
local MAX_TASK_HISTORY = 10

---@description Check for ClearPedTasks spam
local function checkClearTasksSpam()
    local clearLimit = ConfigLoader.get_protection_setting("Anti Blacklisted Task", "limit") or 20
    local clearWindow = 5000
    local currentTime = GetGameTimer()
    
    if currentTime - lastClearTaskTime < clearWindow then
        clearTasksCount = clearTasksCount + 1
        
        if clearTasksCount >= clearLimit then
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                "Anti Blacklisted Task", webhook, time,
                string.format("ClearPedTasks spam detected: %d calls in %d seconds", 
                clearTasksCount, clearWindow / 1000))
            clearTasksCount = 0
            return true
        end
    else
        clearTasksCount = 1
    end
    
    lastClearTaskTime = currentTime
    return false
end

function AntiBlacklistedTask.initialize()
    if not ConfigLoader.get_protection_setting("Anti Blacklisted Task", "enabled") then return end
    
    -- Hook ClearPedTasks
    local originalClearPedTasks = ClearPedTasks
    ClearPedTasks = function(ped)
        if Cache.Get("hasPermission", "tasks") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
            return originalClearPedTasks(ped)
        end
        
        if checkClearTasksSpam() then
            return
        end
        
        return originalClearPedTasks(ped)
    end
    
    -- Hook ClearPedTasksImmediately
    local originalClearPedTasksImmediately = ClearPedTasksImmediately
    ClearPedTasksImmediately = function(ped)
        if Cache.Get("hasPermission", "tasks") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
            return originalClearPedTasksImmediately(ped)
        end
        
        if checkClearTasksSpam() then
            return
        end
        
        return originalClearPedTasksImmediately(ped)
    end
    
    -- Monitor task execution
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
            
            if Cache.Get("hasPermission", "tasks") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end
            
            local ped = Cache.Get("ped")
            
            -- Check for blocking of non-temporary events (godmode-like behavior)
            if GetBlockingOfNonTemporaryEvents(ped) then
                SetBlockingOfNonTemporaryEvents(ped, false)
                detectionCount = detectionCount + 1
                
                if detectionCount >= 3 then
                    detectionCount = 0
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                        "Anti Blacklisted Task", webhook, time,
                        "Detected blocking of non-temporary events")
                end
            end
            
            ::continue::
        end
    end)
    
    -- Reset counters periodically
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(30000)
            detectionCount = 0
            clearTasksCount = 0
        end
    end)
end

ProtectionManager.register_protection("blacklisted_task", AntiBlacklistedTask.initialize)
return AntiBlacklistedTask
