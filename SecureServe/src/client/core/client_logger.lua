---@class ClientLoggerModule
local ClientLogger = {
    levels = {
        DEBUG = 0,
        INFO = 1,
        WARN = 2,
        ERROR = 3,
        FATAL = 4
    },
    level = 1,
    debug_enabled = false,
    initialized = false
}

---@description Initialize the client logger
---@param config table Configuration options
function ClientLogger.initialize(config)
    if ClientLogger.initialized then
        return
    end
    
    ClientLogger.initialized = true
    
    if config then
        ClientLogger.level = config.LogLevel or ClientLogger.level
        ClientLogger.debug_enabled = config.Debug or false
    end
    
    RegisterNetEvent("SecureServe:UpdateDebugMode")
    AddEventHandler("SecureServe:UpdateDebugMode", function(enabled)
        ClientLogger.set_debug_mode(enabled == true)
    end)
end

---@description Format a log message
---@param level string The log level
---@param message string The message to log
---@param ... any Additional values to include in the log
---@return string formatted_message The formatted log message
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

---@description Set the debug mode
---@param enabled boolean The debug mode
function ClientLogger.set_debug_mode(enabled)
    ClientLogger.debug_enabled = enabled == true
end

---@param level string The log level
---@return boolean should_log Whether the log should be printed
local function should_log(level)
    if not ClientLogger.initialized or not ClientLogger.debug_enabled then
        return false
    end
    
    local log_level = ClientLogger.levels[level] or ClientLogger.levels.INFO
    if log_level == ClientLogger.levels.DEBUG and not ClientLogger.debug_enabled then
        return false
    end
    return log_level >= ClientLogger.level
end

---@param level string The log level
---@param message string The message to log
---@param ... any Additional values to include in the log
local function emit(level, message, ...)
    if not should_log(level) then
        return
    end
    
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

---@description Log a debug message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.debug(message, ...)
    emit("DEBUG", message, ...)
end

---@description Log an info message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.info(message, ...)
    emit("INFO", message, ...)
end

---@description Log a warning message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.warn(message, ...)
    emit("WARN", message, ...)
end

---@description Log an error message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.error(message, ...)
    emit("ERROR", message, ...)
end

---@description Log a fatal error message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.fatal(message, ...)
    emit("FATAL", message, ...)
end

return ClientLogger