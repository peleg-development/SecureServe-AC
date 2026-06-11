local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")

local AntiResourceStop = {}
local playerLoaded = false

CreateThread(function()
    while GetIsLoadingScreenActive() or not DoesEntityExist(PlayerPedId()) do
        Wait(500)
    end
    Wait(3000)
    playerLoaded = true
end)

local function checkResource(action, resourceName)
    if not playerLoaded or resourceName == GetCurrentResourceName() then return end

    TriggerServerCallback {
        eventName = 'SecureServe:Server_Callbacks:Protections:GetResourceStatus',
        args = {},
        callback = function(stopped_by_server, started_resources, restarted)
            local authorized = false

            if action == "Start" and (started_resources or restarted) then authorized = true end
            if action == "Stop"  and (stopped_by_server or restarted) then authorized = true end

            if not authorized then
                ProtectionHelper.punish('Anti Resource Stop',
                    "Anti Resource " .. action .. ": " .. resourceName)
            end
        end,
    }
end

function AntiResourceStop.initialize()
    if not ConfigLoader.get_protection_setting("Anti Resource Stop", "enabled") then
        return
    end

    AddEventHandler('onClientResourceStart', function(resource_name)
        checkResource("Start", resource_name)
    end)

    AddEventHandler('onClientResourceStop', function(resource_name)
        checkResource("Stop", resource_name)
    end)

    CreateThread(function()
        Wait(20000)

        local strikes = 0
        local THRESHOLD = 6

        while true do
            Wait(5000)
            if playerLoaded then
                local state = GetResourceState("keep-alive")

                if state == "stopped" or state == "missing" then
                    strikes = strikes + 1
                    if strikes >= THRESHOLD then
                        ProtectionHelper.punish('Anti Resource Stop',
                            "keep-alive missing or stopped (state=" .. tostring(state) .. ")")
                        return
                    end
                elseif state == "started" then
                    strikes = 0
                end
            end
        end
    end)
end

ProtectionManager.register_protection("resource_stop", AntiResourceStop.initialize)

return AntiResourceStop
