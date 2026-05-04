local ClientLogger = {
    levels = {
        DEBUG = 0,
        INFO  = 1,
        WARN  = 2,
        ERROR = 3,
        FATAL = 4,
    },
    level         = 1,
    debug_enabled = false,
    initialized   = false,
}

function ClientLogger.initialize(config)
    if ClientLogger.initialized then
        return
    end
    ClientLogger.initialized = true

    if config then
        ClientLogger.level         = config.LogLevel or ClientLogger.level
        ClientLogger.debug_enabled = config.Debug or false
    end

    AddEventHandler("SecureServe:UpdateDebugMode", function(enabled)
        ClientLogger.set_debug_mode(enabled == true)
    end)
end

function ClientLogger.format(level, message, ...)
    local base = ("[%s] %s"):format(level, tostring(message))
    local args = { ... }
    if #args == 0 then
        return base
    end
    local parts = { base }
    for i = 1, #args do
        parts[#parts + 1] = tostring(args[i])
    end
    return table.concat(parts, " ")
end

function ClientLogger.set_debug_mode(enabled)
    ClientLogger.debug_enabled = enabled == true
end

local function should_log(level)
    if not ClientLogger.initialized then
        return level == "ERROR" or level == "FATAL"
    end

    if level == "DEBUG" then
        return ClientLogger.debug_enabled
    end

    local lvl = ClientLogger.levels[level] or ClientLogger.levels.INFO
    return lvl >= ClientLogger.level
end

local function emit(level, message, ...)
    if not should_log(level) then return end

    local formatted = ClientLogger.format(level, message, ...)
    print(formatted)

    if level == "ERROR" or level == "FATAL" then
        local payload = formatted
        if #payload > 500 then
            payload = payload:sub(1, 500) .. "..."
        end
        TriggerServerEvent("SecureServe:ClientLog", level, payload)
    end
end

function ClientLogger.debug(m, ...) emit("DEBUG", m, ...) end
function ClientLogger.info(m, ...)  emit("INFO",  m, ...) end
function ClientLogger.warn(m, ...)  emit("WARN",  m, ...) end
function ClientLogger.error(m, ...) emit("ERROR", m, ...) end
function ClientLogger.fatal(m, ...) emit("FATAL", m, ...) end

return ClientLogger
