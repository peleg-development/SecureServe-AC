local ProtectionManager = require("client/protections/protection_manager")

---@class BlacklistedCommandsModule
local BlacklistedCommands = {}

---@description Initialize Blacklisted Commands check
function BlacklistedCommands.initialize()
    Citizen.CreateThread(function()
        while true do
            local registered_commands = GetRegisteredCommands()
            for _, k in pairs(SecureServe.Protection.BlacklistedCommands) do
                for _, v in pairs(registered_commands) do
                    if k.command == v.name then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Blacklisted Command (" .. k.command .. ")", k.webhook, k.time)
                    end
                end
            end
            
            Citizen.Wait(7600)
        end
    end)
end

ProtectionManager.register_protection("blacklisted_commands", BlacklistedCommands.initialize)

return BlacklistedCommands 