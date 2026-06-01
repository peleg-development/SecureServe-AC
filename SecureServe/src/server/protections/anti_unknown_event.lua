-- anti_unknown_event: deteccion de eventos triggereados por clientes sin
-- registrar.
--
-- LIMITACION IMPORTANTE:
-- En FiveM, los eventos de red que un cliente envia con TriggerServerEvent
-- solo llegan al servidor si algun recurso los ha registrado con
-- RegisterNetEvent. Los que no estan registrados se descartan en la capa de
-- red antes de que ningun handler los vea. No existe un hook publico para
-- observarlos.
--
-- Por ese motivo este modulo NO puede banear "eventos desconocidos enviados
-- por clientes" como sugiere su nombre. Lo que si hace ahora:
--
--   * Mantiene una lista actualizada de eventos conocidos via wrap de
--     RegisterNetEvent (el wrap se instala solo si DetectUnknownEvents=true
--     en config).
--   * Expone `report(src, event_name)` como sumidero observacional: si algo
--     externo invoca esta funcion (por ejemplo un futuro hook custom, o el
--     export module_punish), se contabiliza y se loguea. NO se banea por
--     defecto.
--   * Si se activa explicitamente `BanOnUnknownEvent = true` en
--     SecureServe.Protection, entonces `report` si banea tras el threshold;
--     esto queda como opt-in para integraciones avanzadas que sepan que
--     hacen.
--
-- Si quieres detectar abuso de eventos legitimos por parte de clientes,
-- valida la identidad del `source` dentro del handler concreto. No hay
-- atajo generico.

local AntiUnknownEvent = {}

local ban_manager    = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")
local logger         = require("server/core/logger")

local known_events       = {}
local fired_unknown      = {}
local fired_unknown_count = 0
local strikes            = {}

local STRIKE_THRESHOLD = 3
local STRIKE_WINDOW    = 30

local SYSTEM_EVENTS = {
    ["playerConnecting"]              = true,
    ["playerJoining"]                 = true,
    ["playerDropped"]                 = true,
    ["playerSpawned"]                 = true,
    ["entityRemoved"]                 = true,
    ["weaponDamageEvent"]             = true,
    ["explosionEvent"]                = true,
    ["fireEvent"]                     = true,
    ["ptFxEvent"]                     = true,
    ["startProjectileEvent"]          = true,
    ["respawnPlayerPedEvent"]         = true,
    ["vehicleComponentControlEvent"]  = true,
    ["removeAllWeaponsEvent"]         = true,
    ["giveWeaponEvent"]               = true,
    ["removeWeaponEvent"]             = true,
    ["clearPedTasksEvent"]            = true,
    ["onResourceStart"]               = true,
    ["onResourceStarting"]            = true,
    ["onResourceStop"]                = true,
    ["onResourceListRefresh"]         = true,
    ["onServerResourceStart"]         = true,
    ["onServerResourceStop"]          = true,
    ["gameEventTriggered"]            = true,
    ["populationPedCreating"]         = true,
    ["rconCommand"]                   = true,
    ["__cfx_internal:commandFallback"] = true,
    ["playerEnteredScope"]            = true,
    ["playerLeftScope"]               = true,
    ["entityCreating"]                = true,
    ["entityCreated"]                 = true,
    ["baseevents:onPlayerDied"]       = true,
    ["baseevents:onPlayerKilled"]     = true,
}

---@param event_name string
---@return boolean
function AntiUnknownEvent.is_known(event_name)
    if type(event_name) ~= "string" then return true end
    if SYSTEM_EVENTS[event_name] then return true end
    if known_events[event_name] then return true end
    if event_name:find("^smp__") then return true end
    if event_name:find("^__cfx_") then return true end
    if event_name:find("^keepalive:") then return true end
    if config_manager.is_event_whitelisted(event_name) then return true end
    return false
end

---@param event_name string
function AntiUnknownEvent.register_known(event_name)
    if type(event_name) == "string" then
        known_events[event_name] = true
    end
end

---@description Carga eventos "system" extra desde config si los hay.
local function load_user_system_events()
    if SecureServe and SecureServe.Protection and type(SecureServe.Protection.SystemEvents) == "table" then
        for _, name in ipairs(SecureServe.Protection.SystemEvents) do
            if type(name) == "string" then
                SYSTEM_EVENTS[name] = true
            end
        end
    end
end

function AntiUnknownEvent.initialize()
    if not (SecureServe and SecureServe.Protection and SecureServe.Protection.DetectUnknownEvents) then
        logger.info("Anti Unknown Event tracking is OFF (DetectUnknownEvents=false). Skipping wrap.")
        return
    end

    load_user_system_events()

    -- Instalamos el wrap solo si nadie lo hizo ya. Si module.lua del propio
    -- AC ya esta presente, su wrap envuelve RegisterNetEvent. Componer encima
    -- es seguro: nuestro wrap solo anota el nombre y delega.
    local _RegisterNetEvent = _G.RegisterNetEvent
    _G.RegisterNetEvent = function(event_name, ...)
        AntiUnknownEvent.register_known(event_name)
        return _RegisterNetEvent(event_name, ...)
    end

    -- Limpieza periodica de buckets de strikes caducados.
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(STRIKE_WINDOW * 1000)
            local now = os.time()
            for pid, data in pairs(strikes) do
                if now - data.window_start > STRIKE_WINDOW then
                    strikes[pid] = nil
                end
            end
        end
    end)

    AddEventHandler("playerDropped", function()
        local src = source
        if src then strikes[src] = nil end
    end)

    logger.info("Anti Unknown Event tracking initialized (observational mode).")
end

---@description Sumidero observacional. Por defecto solo registra y loguea.
--- Si SecureServe.Protection.BanOnUnknownEvent es true, banea tras pasar el
--- threshold. Tener en cuenta que esto solo se dispara si algo EXTERNO invoca
--- report() — el runtime de FiveM no nos da los eventos desconocidos.
---@param src number
---@param event_name string
function AntiUnknownEvent.report(src, event_name)
    if not src or src <= 0 then return end
    if AntiUnknownEvent.is_known(event_name) then return end

    fired_unknown[event_name] = (fired_unknown[event_name] or 0) + 1
    fired_unknown_count = fired_unknown_count + 1

    logger.warn(("Player %s triggered unknown event '%s'"):format(tostring(src), tostring(event_name)))

    local should_ban = SecureServe and SecureServe.Protection
        and SecureServe.Protection.BanOnUnknownEvent == true
    if not should_ban then
        return
    end

    local now = os.time()
    local bucket = strikes[src]
    if not bucket or now - bucket.window_start > STRIKE_WINDOW then
        strikes[src] = { window_start = now, count = 1, events = { event_name } }
        return
    end

    bucket.count = bucket.count + 1
    bucket.events[#bucket.events + 1] = event_name
    if bucket.count >= STRIKE_THRESHOLD then
        ban_manager.ban_player(src, "Unknown Event Trigger", {
            admin     = "Anti-Cheat System",
            time      = 2147483647,
            detection = "Triggered unregistered events: " .. table.concat(bucket.events, ", "),
        })
        strikes[src] = nil
    end
end

---@return table stats Snapshot de telemetria interna (para debug).
function AntiUnknownEvent.get_stats()
    return {
        known_events_count = (function()
            local n = 0
            for _ in pairs(known_events) do n = n + 1 end
            return n
        end)(),
        fired_unknown_total = fired_unknown_count,
        fired_unknown      = fired_unknown,
        active_strikes     = (function()
            local n = 0
            for _ in pairs(strikes) do n = n + 1 end
            return n
        end)(),
    }
end

return AntiUnknownEvent
