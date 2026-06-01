-- rate_limiter.lua
--
-- Rate limiting de eventos de red por jugador.
--
-- FILOSOFIA: NO banea. Cuando un jugador supera el limite de un evento, el
-- evento extra se DESCARTA (no se procesa). Asi, incluso con una calibracion
-- mala, nunca se echa a un jugador legitimo: solo se ignoran llamadas de mas.
--
-- LIMITACION de FiveM: no existe un hook universal para todos los eventos de
-- red entrantes. Por eso este modulo:
--   1. Protege automaticamente los eventos del PROPIO SecureServe (los que un
--      exploiter spamearia para intentar tumbar el AC o forzar acciones).
--   2. Expone RateLimiter.guard(event_name, handler, opts) y
--      RateLimiter.check(src, event_name) para que registres tus propios
--      eventos criticos.
--
-- Telemetria opcional: si un jugador supera mucho el limite de forma
-- sostenida, se loguea un aviso (sin banear) para que el staff lo revise.

local RateLimiter = {}

local logger = require("server/core/logger")

-- buckets[src][event_name] = { window_start_ms, count }
local buckets = {}

-- Limites por defecto (llamadas permitidas por ventana).
local DEFAULT_LIMIT  = 30      -- llamadas
local DEFAULT_WINDOW = 1000    -- ms

-- Limites especificos por evento. Pon aqui los eventos sensibles del AC.
-- Valores MUY por encima del uso legitimo real para no falsear nunca.
local EVENT_LIMITS = {
    ["SecureServe:ClientLog"]                         = { limit = 20, window = 1000 },
    ["SecureServe:Server:Methods:PunishPlayer"]       = { limit = 10, window = 1000 },
    ["SecureServe:Heartbeat:AddAlive"]                = { limit = 10, window = 1000 },
    ["SecureServe:Config:Request"]                    = { limit = 5,  window = 5000 },
    ["SecureServe:RequestAdminList"]                  = { limit = 5,  window = 5000 },
    ["mMkHcvct3uIg04STT16I:cbnF2cR9ZTt8NmNx2jQS"]     = { limit = 5,  window = 1000 },
}

-- Para detectar abuso sostenido (solo aviso, no ban).
local abuse = {}  -- src -> { count, window_start }
local ABUSE_WINDOW   = 10000
local ABUSE_THRESHOLD = 200   -- descartes en 10s antes de avisar al staff

local function now_ms()
    return GetGameTimer()
end

---@param src number
---@param event_name string
---@return boolean allowed true si se permite, false si hay que descartar
function RateLimiter.check(src, event_name)
    if not src or src <= 0 then return true end

    local cfg = EVENT_LIMITS[event_name]
    local limit  = cfg and cfg.limit  or DEFAULT_LIMIT
    local window = cfg and cfg.window or DEFAULT_WINDOW

    buckets[src] = buckets[src] or {}
    local b = buckets[src][event_name]
    local t = now_ms()

    if not b or (t - b.window_start) > window then
        buckets[src][event_name] = { window_start = t, count = 1 }
        return true
    end

    b.count = b.count + 1
    if b.count > limit then
        -- Telemetria de abuso (sin banear).
        local a = abuse[src]
        if not a or (t - a.window_start) > ABUSE_WINDOW then
            abuse[src] = { count = 1, window_start = t }
        else
            a.count = a.count + 1
            if a.count == ABUSE_THRESHOLD then
                local name = GetPlayerName(src) or "unknown"
                logger.warn(("Rate limiter: %s (id %s) is flooding events (last offender: '%s'). Events are being dropped, NOT banning."):format(name, tostring(src), tostring(event_name)))
            end
        end
        return false
    end

    return true
end

---@description Envuelve un handler de evento con rate limiting. Si se supera
--- el limite, el handler NO se ejecuta (el evento se descarta silenciosamente).
---@param event_name string
---@param handler function el handler original (recibe los mismos args)
---@param opts table|nil { limit = n, window = ms }
function RateLimiter.guard(event_name, handler, opts)
    if opts and type(opts) == "table" then
        EVENT_LIMITS[event_name] = { limit = opts.limit or DEFAULT_LIMIT, window = opts.window or DEFAULT_WINDOW }
    end

    RegisterNetEvent(event_name, function(...)
        local src = source
        if not RateLimiter.check(src, event_name) then
            return  -- descartar, sin procesar ni banear
        end
        return handler(...)
    end)
end

function RateLimiter.initialize()
    AddEventHandler("playerDropped", function()
        local src = source
        if src then
            buckets[src] = nil
            abuse[src]   = nil
        end
    end)

    logger.info("Rate Limiter initialized (drop-on-exceed, no bans).")
end

---@return table snapshot de telemetria interna
function RateLimiter.get_stats()
    local tracked = 0
    for _ in pairs(buckets) do tracked = tracked + 1 end
    return { tracked_players = tracked }
end

return RateLimiter
