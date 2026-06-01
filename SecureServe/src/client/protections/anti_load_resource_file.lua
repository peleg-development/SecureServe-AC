local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

---@class AntiLoadResourceFileModule
local AntiLoadResourceFile = {}

local loaded_keys             = {}        -- resourceName -> bool
local pendingResourceChecks   = {}        -- resourceName -> bool
local last_lifecycle_event_at = {}        -- resourceName -> GetGameTimer()
local playerLoaded            = false

-- Si ha habido un start/stop/restart de ese resource en los ultimos N ms,
-- consideramos que un segundo intento de cargar la key es benigno (resource
-- recargado en caliente legitimo, p.ej. dev haciendo restart).
local LIFECYCLE_GRACE_MS = 8000

local function is_in_lifecycle_grace(resourceName)
    local t = last_lifecycle_event_at[resourceName]
    return t ~= nil and (GetGameTimer() - t) < LIFECYCLE_GRACE_MS
end

function AntiLoadResourceFile.initialize()
    Citizen.CreateThread(function()
        Citizen.Wait(10000)
        playerLoaded = true
    end)

    -- Cada lifecycle event que veamos en el cliente resetea la "race grace".
    AddEventHandler("onResourceStop", function(resourceName)
        loaded_keys[resourceName] = nil
        last_lifecycle_event_at[resourceName] = GetGameTimer()
    end)
    AddEventHandler("onResourceStart", function(resourceName)
        last_lifecycle_event_at[resourceName] = GetGameTimer()
    end)
    AddEventHandler("onClientResourceStart", function(resourceName)
        last_lifecycle_event_at[resourceName] = GetGameTimer()
    end)
    AddEventHandler("onClientResourceStop", function(resourceName)
        last_lifecycle_event_at[resourceName] = GetGameTimer()
    end)

    RegisterNetEvent("SecureServe:Client_Callbacks:Protections:GetResourceStatus",
        function(stopped, started, restarted)
            if not playerLoaded or stopped or started or restarted then
                for resourceName, _ in pairs(pendingResourceChecks) do
                    loaded_keys[resourceName] = true
                end
                pendingResourceChecks = {}
                return
            end

            Citizen.SetTimeout(5000, function()
                if not playerLoaded then
                    for resourceName, _ in pairs(pendingResourceChecks) do
                        loaded_keys[resourceName] = true
                    end
                    pendingResourceChecks = {}
                    return
                end

                -- Admins/permission bypass.
                if Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                    for resourceName, _ in pairs(pendingResourceChecks) do
                        loaded_keys[resourceName] = true
                    end
                    pendingResourceChecks = {}
                    return
                end

                for resourceName, _ in pairs(pendingResourceChecks) do
                    if loaded_keys[resourceName] then
                        if is_in_lifecycle_grace(resourceName) then
                            -- Suposicion: restart en caliente legitimo. No
                            -- baneamos. Refrescamos el flag.
                            loaded_keys[resourceName] = true
                        else
                            ProtectionHelper.punish('Anti Load Resource File',
                                "Resource " .. resourceName .. " attempted to load key multiple times without restart")
                        end
                    end
                    loaded_keys[resourceName] = true
                end
                pendingResourceChecks = {}
            end)
        end)

    RegisterNetEvent("SecureServe:Client:LoadedKey", function(resourceName)
        pendingResourceChecks[resourceName] = true
        TriggerServerEvent("SecureServe:Server_Callbacks:Protections:GetResourceStatus")
    end)
end

ProtectionManager.register_protection("load_resource_file", AntiLoadResourceFile.initialize)

return AntiLoadResourceFile
