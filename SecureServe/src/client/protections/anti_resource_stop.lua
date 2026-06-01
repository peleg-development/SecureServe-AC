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

local pendingStatusChecks = {}

local function checkResource(action, resourceName)
    if not playerLoaded or resourceName == GetCurrentResourceName() then return end

    pendingStatusChecks[#pendingStatusChecks + 1] = {
        action = action,
        resource = resourceName,
        timestamp = GetGameTimer(),
    }
    TriggerServerEvent('SecureServe:Server_Callbacks:Protections:GetResourceStatus')
end

RegisterNetEvent('SecureServe:Client_Callbacks:Protections:GetResourceStatus',
    function(stopped_by_server, started_resources, restarted)
        local pending = pendingStatusChecks
        pendingStatusChecks = {}

        for _, entry in ipairs(pending) do
            local authorized = false
            if entry.action == "Start" and (started_resources or restarted) then authorized = true end
            if entry.action == "Stop"  and (stopped_by_server or restarted) then authorized = true end

            if not authorized then
                ProtectionHelper.punish('Anti Resource Stop',
                    "Anti Resource " .. entry.action .. ": " .. entry.resource)
            end
        end
    end)

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

    -- Verificacion cruzada: keep-alive debe seguir cargado.
    -- Esto pilla al cheater que sobreescribe AddEventHandler para anular
    -- onClientResourceStop, porque GetResourceState lee directo del runtime.
    --
    -- Requerimos:
    --   1. Periodo de calma inicial generoso (30s) para que el orden de carga
    --      de recursos del server no nos haga falsos positivos en arranques
    --      lentos o cuando keep-alive aun no esta presente en la lista.
    --   2. Ver al menos una vez que keep-alive este "started" antes de
    --      empezar a contar strikes. Asi evitamos banear al jugador si su
    --      cliente entro al server justo antes de que keep-alive este
    --      disponible.
    --   3. Bypass admin/permission por si un admin debe parar todo el AC
    --      manualmente.
    CreateThread(function()
        Wait(30000)

        local strikes = 0
        local THRESHOLD = 6
        local has_seen_started = false

        while true do
            Wait(5000)
            if not playerLoaded then goto continue end

            -- Bypass admin/permission.
            local Cache = require("client/core/cache")
            if Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                strikes = 0
                goto continue
            end

            local state = GetResourceState("keep-alive")

            if state == "started" then
                has_seen_started = true
                strikes = 0
            elseif (state == "stopped" or state == "missing") and has_seen_started then
                strikes = strikes + 1
                if strikes >= THRESHOLD then
                    ProtectionHelper.punish('Anti Resource Stop',
                        "keep-alive missing or stopped (state=" .. tostring(state) .. ")")
                    return
                end
            end
            -- Otros estados (starting, stopping, unknown) los ignoramos.

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("resource_stop", AntiResourceStop.initialize)

return AntiResourceStop
