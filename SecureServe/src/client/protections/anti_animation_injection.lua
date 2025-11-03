local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiAnimationInjectionModule
local AntiAnimationInjection = {}

local detectionCount = 0
local animSpamCount = 0
local lastAnimTime = 0

---@description Check for animation spam
local function checkAnimationSpam()
    local spamLimit = ConfigLoader.get_protection_setting("Anti Animation Injection", "limit") or 10
    local spamWindow = 5000
    local currentTime = GetGameTimer()
    
    if currentTime - lastAnimTime < spamWindow then
        animSpamCount = animSpamCount + 1
        
        if animSpamCount >= spamLimit then
            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                "Anti Animation Injection", webhook, time,
                string.format("Animation spam detected: %d animations in %d seconds", 
                animSpamCount, spamWindow / 1000))
            animSpamCount = 0
            return true
        end
    else
        animSpamCount = 1
    end
    
    lastAnimTime = currentTime
    return false
end

---@description Main protection loop
function AntiAnimationInjection.initialize()
    if not ConfigLoader.get_protection_setting("Anti Animation Injection", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
            
            if Cache.Get("hasPermission", "animations") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end
            
            -- Check animation spam
            checkAnimationSpam()
            
            ::continue::
        end
    end)
    
    -- Reset counters periodically
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(30000)
            detectionCount = 0
            animSpamCount = 0
        end
    end)
end

ProtectionManager.register_protection("animation_injection", AntiAnimationInjection.initialize)
return AntiAnimationInjection
