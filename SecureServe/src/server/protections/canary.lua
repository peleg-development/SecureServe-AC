-- Canary: contraparte servidor del recurso keep-alive.
-- Valida los ticks que manda keep-alive (token + counter monotono) y banea
-- si el cliente deja de pingear, manda un token incorrecto, intenta replay
-- o avisa de que SecureServe se ha parado en su lado.
--
-- Tres mecanismos en paralelo:
--
--   1. Si un jugador conectado lleva mas de hello_window segundos sin haber
--      mandado un primer hello, asumimos que keep-alive no esta arrancando
--      en su cliente y baneamos.
--   2. Si una sesion establecida lleva mas de timeout segundos sin tick,
--      se acumula un strike. Tras silence_strikes consecutivos, ban.
--   3. Si un tick llega con token incorrecto, counter retrocedido o salto
--      sospechoso, baneamos (con tolerancia para hot-restart reciente).
--
-- Si el recurso se reinicia en caliente, las sesiones se pierden pero los
-- clientes ya conectados siguen mandando ticks con el viejo token. En ese
-- caso re-emitimos un token nuevo y damos un margen de gracia para evitar
-- baneos falsos durante la resincronizacion.

local Canary = {
    sessions       = {},
    expected_hello = {},
    grace_period   = 60,    -- segundos tras los que ya cuenta el timeout
    timeout        = 60,    -- silencio tolerado antes de empezar a sumar strikes
    hello_window   = 240,   -- margen para que el cliente termine de cargar resources
    check_interval = 5000,
    max_skip       = 100,
    silence_strikes = 2,    -- nº de comprobaciones consecutivas en silencio antes de banear
    rotation_grace = 30,    -- ventana tras crear una sesion en la que toleramos
                            -- token-mismatch y counter-skip (hot-restart, late assign)
    initialized    = false,
}

local ban_manager    = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")
local logger         = require("server/core/logger")

local TOKEN_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local TOKEN_LEN   = 32

local function generate_token()
    local n = #TOKEN_CHARS
    local t = {}
    for i = 1, TOKEN_LEN do
        t[i] = TOKEN_CHARS:sub(math.random(n), math.random(n))
    end
    return table.concat(t)
end

local function ban(src, reason)
    local cfg = config_manager.get_config()
    local should_ban = true
    if cfg and cfg.Module and cfg.Module.Heartbeat then
        should_ban = cfg.Module.Heartbeat.BanOnViolation ~= false
    end

    logger.warn(("Canary violation by %s (id %s): %s"):format(
        GetPlayerName(src) or "?", tostring(src), reason))

    if should_ban and ban_manager and ban_manager.ban_player then
        ban_manager.ban_player(src, "Anticheat violation: " .. reason, {
            admin     = "Anti-Cheat System",
            time      = 2147483647,
            detection = reason,
        })
    else
        DropPlayer(tostring(src), "Anticheat violation: " .. reason)
    end
end

local function open_session(src)
    local token = generate_token()
    Canary.sessions[src] = {
        token          = token,
        last_tick      = os.time(),
        counter        = 0,
        established_at = os.time(),
        silent_strikes = 0,
    }
    Canary.expected_hello[src] = nil
    return token
end

function Canary.initialize()
    if Canary.initialized then return end
    Canary.initialized = true

    math.randomseed(os.time() + math.floor((os.clock() * 1e6) % 1e9))

    AddEventHandler("playerJoining", function()
        local src = source
        if src and src > 0 then
            Canary.expected_hello[src] = os.time()
        end
    end)

    AddEventHandler("playerDropped", function()
        local src = source
        if src then
            Canary.sessions[src] = nil
            Canary.expected_hello[src] = nil
        end
    end)

    -- Inicializar a los jugadores que ya estaban conectados cuando el recurso
    -- arranca (caso restart en caliente del SecureServe).
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if src then Canary.expected_hello[src] = os.time() end
    end

    RegisterNetEvent("keepalive:hello", function()
        local src = source
        if not src or src <= 0 then return end

        local token = open_session(src)
        TriggerClientEvent("keepalive:assign", src, token)
    end)

    RegisterNetEvent("keepalive:tick", function(token, counter)
        local src = source
        if not src or src <= 0 then return end

        if type(token) ~= "string" or type(counter) ~= "number" then
            ban(src, "Malformed canary tick")
            Canary.sessions[src] = nil
            return
        end

        local s = Canary.sessions[src]

        -- Tick sin sesion en el servidor: probablemente restart en caliente
        -- del recurso. Re-emitimos token para resincronizar al cliente.
        if not s then
            local new_token = open_session(src)
            TriggerClientEvent("keepalive:assign", src, new_token)
            return
        end

        local age = os.time() - s.established_at

        if s.token ~= token then
            -- Si la sesion es muy reciente, el cliente puede tener todavia
            -- en vuelo un tick con el token antiguo (caso hot-restart).
            -- Re-enviamos el token actual y esperamos en lugar de banear.
            if age < Canary.rotation_grace then
                TriggerClientEvent("keepalive:assign", src, s.token)
                return
            end
            ban(src, "Invalid canary token")
            Canary.sessions[src] = nil
            return
        end

        if counter <= s.counter then
            -- Replay tras token recien rotado: el cliente puede haber
            -- reseteado su contador pero un tick anterior con counter alto
            -- llega tarde. Ignorar en lugar de banear.
            if age < Canary.rotation_grace then
                return
            end
            ban(src, ("Canary replay (counter %d <= %d)"):format(counter, s.counter))
            Canary.sessions[src] = nil
            return
        end

        if (counter - s.counter) > Canary.max_skip then
            -- Salto grande tras una sesion recien creada: el cliente puede
            -- llevar el contador alto desde antes del restart. Re-baselineamos
            -- en vez de banear.
            if age < Canary.rotation_grace then
                s.counter        = counter
                s.last_tick      = os.time()
                s.silent_strikes = 0
                return
            end
            ban(src, ("Canary counter skip suspicious (jump of %d)"):format(counter - s.counter))
            Canary.sessions[src] = nil
            return
        end

        s.counter        = counter
        s.last_tick      = os.time()
        s.silent_strikes = 0
    end)

    RegisterNetEvent("keepalive:ssMissing", function()
        local src = source
        if not src or src <= 0 then return end
        ban(src, "SecureServe stopped on client side")
        Canary.sessions[src] = nil
        Canary.expected_hello[src] = nil
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Canary.check_interval)
            local now = os.time()

            for src, s in pairs(Canary.sessions) do
                if not GetPlayerName(src) then
                    Canary.sessions[src] = nil
                else
                    local since_join = now - s.established_at
                    local since_tick = now - s.last_tick

                    if since_join > Canary.grace_period and since_tick > Canary.timeout then
                        s.silent_strikes = (s.silent_strikes or 0) + 1
                        if s.silent_strikes >= Canary.silence_strikes then
                            ban(src, ("Canary silent for %ds"):format(since_tick))
                            Canary.sessions[src] = nil
                        end
                    else
                        s.silent_strikes = 0
                    end
                end
            end

            for src, joined_at in pairs(Canary.expected_hello) do
                if not GetPlayerName(src) then
                    Canary.expected_hello[src] = nil
                elseif (now - joined_at) > Canary.hello_window then
                    ban(src, "keep-alive resource never started on client")
                    Canary.expected_hello[src] = nil
                end
            end
        end
    end)

    logger.info("^5[SUCCESS] ^3Canary^7 system initialized")
end

return Canary
