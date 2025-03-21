---@class ClientLoggerModule
local ClientLogger = {
    levels = {
        DEBUG = 0,
        INFO = 1,
        WARN = 2,
        ERROR = 3,
        FATAL = 4
    },
    colors = {
        DEBUG = "^5",
        INFO = "^2",
        WARN = "^3",
        ERROR = "^1",
        FATAL = "^1",
        RESET = "^7"
    },
    level = 1,
    max_history = 100,
    history = {},
    debug_enabled = false
}

---@description Initialize the client logger
---@param config table Configuration options
function ClientLogger.initialize(config)
    if config then
        ClientLogger.level = config.LogLevel or ClientLogger.level
        ClientLogger.max_history = config.MaxLogHistory or ClientLogger.max_history
        ClientLogger.debug_enabled = config.Debug or false
    end
    
    ClientLogger.info("Client logger initialized with debug mode: " .. tostring(ClientLogger.debug_enabled))
    
    RegisterNetEvent("SecureServe:UpdateDebugMode")
    AddEventHandler("SecureServe:UpdateDebugMode", function(enabled)
        ClientLogger.debug_enabled = enabled
        ClientLogger.info("Debug mode " .. (enabled and "enabled" or "disabled"))
    end)
end

---@description Format a log message
---@param level string The log level
---@param message string The message to log
---@param ... any Additional values to include in the log
---@return string formatted_message The formatted log message
function ClientLogger.format(level, message, ...)
    local color = ClientLogger.colors[level] or ClientLogger.colors.INFO
    local reset = ClientLogger.colors.RESET
    
    local final_message = string.format(" %s[CLIENT %s]%s %s", 
        color, 
        level, 
        reset,
        message
    )
    
    local args = {...}
    if #args > 0 then
        for i, v in ipairs(args) do
            if type(v) == "table" then
                final_message = final_message .. " " .. ClientLogger.table_to_string(v)
            else
                final_message = final_message .. " " .. tostring(v)
            end
        end
    end
    
    return final_message
end

---@description Convert a table to a string for logging
---@param t table The table to convert
---@param indent number The indentation level
---@return string result The string representation of the table
function ClientLogger.table_to_string(t, indent)
    if not t or type(t) ~= "table" then
        return tostring(t)
    end
    
    indent = indent or 0
    local result = "{\n"
    
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys)
    
    for _, k in ipairs(keys) do
        local v = t[k]
        local indent_str = string.rep("  ", indent + 1)
        
        result = result .. indent_str
        
        if type(k) == "number" then
            result = result .. "[" .. k .. "] = "
        else
            result = result .. '["' .. tostring(k) .. '"] = '
        end
        
        if type(v) == "table" then
            result = result .. ClientLogger.table_to_string(v, indent + 1) .. ",\n"
        elseif type(v) == "string" then
            result = result .. '"' .. v .. '",\n'
        else
            result = result .. tostring(v) .. ",\n"
        end
    end
    
    result = result .. string.rep("  ", indent) .. "}"
    return result
end

---@description Add a log entry to the history
---@param level string The log level
---@param message string The message to log
function ClientLogger.add_to_history(level, message)
    table.insert(ClientLogger.history, {
        level = level,
        message = message,
    })
    
    while #ClientLogger.history > ClientLogger.max_history do
        table.remove(ClientLogger.history, 1)
    end
end

---@description Send a log to the server for potential Discord logging
---@param level string The log level
---@param message string The message to log
function ClientLogger.send_to_server(level, message)
    if level == "ERROR" or level == "FATAL" then
        TriggerServerEvent("SecureServe:ClientLog", level, message)
    end
end

---@description Log a debug message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.debug(message, ...)
    if ClientLogger.levels.DEBUG < ClientLogger.level then
        return
    end
    
    local formatted = ClientLogger.format("DEBUG", message, ...)
    ClientLogger.add_to_history("DEBUG", formatted)
    
    if ClientLogger.debug_enabled then
        print(formatted)
    end
end

---@description Log an info message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.info(message, ...)
    if ClientLogger.levels.INFO < ClientLogger.level then
        return
    end
    
    local formatted = ClientLogger.format("INFO", message, ...)
    ClientLogger.add_to_history("INFO", formatted)
    
    if ClientLogger.debug_enabled then
        print(formatted)
    end
end

---@description Log a warning message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.warn(message, ...)
    if ClientLogger.levels.WARN < ClientLogger.level then
        return
    end
    
    local formatted = ClientLogger.format("WARN", message, ...)
    ClientLogger.add_to_history("WARN", formatted)
    
    if ClientLogger.debug_enabled then
        print(formatted)
    end
    
    TriggerServerEvent("SecureServe:ForwardLog", "WARN", message)
end

---@description Log an error message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.error(message, ...)
    if ClientLogger.levels.ERROR < ClientLogger.level then
        return
    end
    
    local formatted = ClientLogger.format("ERROR", message, ...)
    ClientLogger.add_to_history("ERROR", formatted)
    
    print(formatted)
    
    TriggerServerEvent("SecureServe:ForwardLog", "ERROR", message)
end

---@description Log a fatal error message
---@param message string The message to log
---@param ... any Additional values to include in the log
function ClientLogger.fatal(message, ...)
    if ClientLogger.levels.FATAL < ClientLogger.level then
        return
    end
    
    local formatted = ClientLogger.format("FATAL", message, ...)
    ClientLogger.add_to_history("FATAL", formatted)
    
    print(formatted)
    
    TriggerServerEvent("SecureServe:ForwardLog", "FATAL", message)
end

---@description Get the log history
---@param count number The number of entries to retrieve (default: all)
---@param level string Optional filter by log level
---@return table log_entries The log entries
function ClientLogger.get_history(count, level)
    local result = {}
    local start_index = count and (#ClientLogger.history - count + 1) or 1
    start_index = math.max(1, start_index)
    
    for i = start_index, #ClientLogger.history do
        local entry = ClientLogger.history[i]
        if not level or entry.level == level then
            table.insert(result, entry)
        end
    end
    
    return result
end

return ClientLogger 