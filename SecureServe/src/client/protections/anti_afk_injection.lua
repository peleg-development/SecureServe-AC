local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiAfkInjectionModule
local AntiAfkInjection = {}

---@description Initialize Anti AFK Injection protection
function AntiAfkInjection.initialize()
    if not ConfigLoader.get_protection_setting("Anti AFK Injection", "enabled") then return end
    
    Citizen.CreateThread(function()
        while true do
            local pid = Cache.Get("ped")
            if (GetIsTaskActive(pid, 100))
                or (GetIsTaskActive(pid, 101))
                or (GetIsTaskActive(pid, 151))
                or (GetIsTaskActive(pid, 221))
                or (GetIsTaskActive(pid, 222)) then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Anti AFK Injection", webhook, time)
            end
            Citizen.Wait(5000)
        end
    end)
end

ProtectionManager.register_protection("afk_injection", AntiAfkInjection.initialize)

return AntiAfkInjection