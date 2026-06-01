-- forensic_log.lua
--
-- Buffer forense rodante por jugador.
--
-- FILOSOFIA: NO es una proteccion que detecte ni castigue NADA. Solo graba en
-- memoria las ultimas N acciones de cada jugador (logs de cliente, detecciones,
-- eventos relevantes). Cuando otra proteccion banea, este modulo adjunta ese
-- historial al log, dando contexto para revisar el ban. No puede dar falsos
-- positivos porque no toma ninguna decision.
--
-- Beneficio: reduce los falsos baneos del resto del sistema, porque te permite
-- ver que paso realmente justo antes de un ban dudoso.

local ForensicLog = {}

local logger = require("server/core/logger")

-- buffers[src] = { ring de entradas { t = epoch, tag = str, msg = str } }
local buffers = {}
local MAX_ENTRIES = 25   -- ultimas N acciones por jugador

---@param src number
---@param tag string categoria corta (ej: "client_log", "detection", "spawn")
---@param msg string descripcion
function ForensicLog.record(src, tag, msg)
    if not src or src <= 0 then return end
    buffers[src] = buffers[src] or {}
    local buf = buffers[src]

    buf[#buf + 1] = {
        t   = os.time(),
        tag = tostring(tag or "?"),
        msg = tostring(msg or ""):sub(1, 200),
    }

    -- mantener solo las ultimas MAX_ENTRIES
    if #buf > MAX_ENTRIES then
        table.remove(buf, 1)
    end
end

---@param src number
---@return string history texto formateado de las ultimas acciones (o "")
function ForensicLog.get_history(src)
    local buf = buffers[src]
    if not buf or #buf == 0 then return "" end

    local lines = {}
    for _, e in ipairs(buf) do
        lines[#lines + 1] = ("[%s] %s: %s"):format(os.date("%H:%M:%S", e.t), e.tag, e.msg)
    end
    return table.concat(lines, "\n")
end

---@param src number
function ForensicLog.clear(src)
    if src then buffers[src] = nil end
end

function ForensicLog.initialize()
    AddEventHandler("playerDropped", function()
        local src = source
        -- pequeno retardo por si un ban en curso quiere leer el historial
        if src then
            local s = src
            Citizen.SetTimeout(5000, function() buffers[s] = nil end)
        end
    end)

    logger.info("Forensic Log initialized (evidence buffer, no detection).")
end

return ForensicLog
