local ProtectionManager = require("client/protections/protection_manager")

local BlacklistedCommands = {}

function BlacklistedCommands.initialize()
    Citizen.CreateThread(function()
        local strikes = 0
        local STRIKE_LIMIT = 2

        while true do
            Citizen.Wait(7600)

            local registered_commands = GetRegisteredCommands()
            local detected_command = nil
            local detected_webhook = nil
            local detected_time    = nil

            for _, k in pairs(SecureServe.Protection.BlacklistedCommands or {}) do
                for _, v in pairs(registered_commands) do
                    if k.command == v.name then
                        if v.resource and (v.resource == GetCurrentResourceName() or v.resource == "_cfx_internal") then
                            
                        else
                            detected_command = k.command
                            detected_webhook = k.webhook
                            detected_time    = k.time
                            break
                        end
                    end
                end
                if detected_command then break end
            end

            if detected_command then
                strikes = strikes + 1
                if strikes >= STRIKE_LIMIT then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer",
                        nil,
                        "Blacklisted Command (" .. detected_command .. ")",
                        detected_webhook,
                        detected_time)
                    strikes = 0
                end
            else
                if strikes > 0 then strikes = strikes - 1 end
            end
        end
    end)
end

ProtectionManager.register_protection("blacklisted_commands", BlacklistedCommands.initialize)

return BlacklistedCommands
