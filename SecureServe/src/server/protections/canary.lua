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

local token_seed_initialized = false

local function init_token_seed()
    if token_seed_initialized then return end
    token_seed_initialized = true
    local t = os.time()
    local extra = 0
    if GetGameTimer then extra = GetGameTimer() end
    math.randomseed((t * 1009 + extra * 31 + (tonumber(tostring({}):match("0x(%x+)") or "0", 16) or 0)) % 2147483647)
    for _ = 1, 8 do math.random() end
end

local function generate_token()
    init_token_seed()
    local n = #TOKEN_CHARS
    local t = {}
    for i = 1, TOKEN_LEN do
        local idx = math.random(n)
        t[i] = TOKEN_CHARS:sub(idx, idx)
    end
    return table.concat(t)
end

local pending_bans = {}

local function ban(src, reason)
    if pending_bans[src] then return end
    pending_bans[src] = true

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

    -- Integrity check del cliente keep-alive.
    --
    -- Computamos el hash del client.lua de keep-alive en disco y lo
    -- almacenamos. Si en runtime el archivo cambia (modificacion manual,
    -- compromiso, etc.) detectamos la inconsistencia y avisamos en logs y a
    -- Discord. NO baneamos a jugadores por esto: es un evento server-side.
    Citizen.CreateThread(function()
        local function sha256(s)
            if type(s) ~= "string" then return nil end
            -- LoadResourceFile da string. CitizenFX expone glm.sha256 en
            -- algunos builds; si no, hacemos checksum simple sumando bytes.
            -- Para el proposito de detectar modificaciones esto es
            -- suficiente: una modificacion real cambia el size + suma de
            -- bytes con altisima probabilidad.
            local sum = 0
            local len = #s
            for i = 1, len do
                sum = (sum * 31 + string.byte(s, i)) % 0xFFFFFFFF
            end
            return ("%08x:%d"):format(sum, len)
        end

        local initial = LoadResourceFile("keep-alive", "client.lua")
        if not initial then
            logger.warn("Canary integrity: keep-alive/client.lua no se puede leer")
            return
        end
        local initial_hash = sha256(initial)
        logger.info("Canary integrity baseline (keep-alive/client.lua): " .. tostring(initial_hash))

        while true do
            Citizen.Wait(300000) -- cada 5 minutos
            local current = LoadResourceFile("keep-alive", "client.lua")
            local current_hash = current and sha256(current) or nil
            if current_hash and current_hash ~= initial_hash then
                logger.warn(("Canary integrity: keep-alive/client.lua cambio (%s -> %s). Investiga."):format(
                    tostring(initial_hash), tostring(current_hash)))
                local DiscordLogger = require("server/core/discord_logger")
                if DiscordLogger and type(DiscordLogger.log_system) == "function" then
                    pcall(DiscordLogger.log_system,
                        "Keep-alive integrity changed",
                        ("`keep-alive/client.lua` ha cambiado en runtime. Hash baseline: `%s`. Hash actual: `%s`."):format(
                            tostring(initial_hash), tostring(current_hash)),
                        { color = 15158332 })
                end
                initial_hash = current_hash
            end
        end
    end)

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
            pending_bans[src] = nil
        end
    end)

    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if src then
            Canary.expected_hello[src] = os.time()
            TriggerClientEvent("keepalive:request_hello", src)
        end
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
                        -- Misma proteccion contra conexiones moribundas: si la
                        -- conexion del jugador esta muerta, NO sumar strikes.
                        local lastMsg = 999999
                        if GetPlayerLastMsg then lastMsg = GetPlayerLastMsg(src) or 999999 end

                        if lastMsg < 10000 then
                            s.silent_strikes = (s.silent_strikes or 0) + 1
                            if s.silent_strikes >= Canary.silence_strikes then
                                ban(src, ("Canary silent for %ds"):format(since_tick))
                                Canary.sessions[src] = nil
                            end
                        else
                            -- Lag/desconexion: resetear strikes para no acumular.
                            s.silent_strikes = 0
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
                    -- No banear a conexiones moribundas / con lag fuerte. Si el
                    -- ultimo mensaje de red del jugador es muy viejo, es lag/
                    -- desconexion, NO ausencia de keep-alive. Lo mismo que
                    -- hacemos en heartbeat.lua para evitar falsos baneos a
                    -- jugadores con mala conexion o cargas lentas.
                    local lastMsg = 999999
                    if GetPlayerLastMsg then lastMsg = GetPlayerLastMsg(src) or 999999 end

                    if lastMsg < 10000 then
                        ban(src, "keep-alive resource never started on client")
                    else
                        logger.warn(("Canary: skipping ban for %s (id %s) — last msg %dms ago, treating as lag/disconnect"):format(
                            GetPlayerName(src) or "?", tostring(src), lastMsg))
                    end
                    Canary.expected_hello[src] = nil
                end
            end
        end
    end)

    logger.info("^5[SUCCESS] ^3Canary^7 system initialized")
end

return Canary
