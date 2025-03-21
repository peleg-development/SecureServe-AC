---@class LoggerModule
local Logger = {
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
    use_webhook = false,
    log_webhook = "",
    history = {},
    max_history = 100,
    debug_enabled = false
}

local config_manager

---@description Initialize the logger
---@param config table The configuration table
function Logger.initialize(config)
    config_manager = require("server/core/config_manager")
    
    if config then
        Logger.level = config.LogLevel or Logger.level
        Logger.use_webhook = config.UseWebhook or Logger.use_webhook
        Logger.log_webhook = config.LogWebhook or Logger.log_webhook
        Logger.max_history = config.MaxLogHistory or Logger.max_history
        Logger.debug_enabled = config.Debug or false
    end
    
    Logger.info("Logger initialized with debug mode: " .. tostring(Logger.debug_enabled))
end

---@description Set debug mode
---@param enabled boolean Whether debug mode is enabled
function Logger.set_debug_mode(enabled)
    Logger.debug_enabled = enabled
    Logger.info("Debug mode " .. (enabled and "enabled" or "disabled"))
    
    TriggerClientEvent("SecureServe:UpdateDebugMode", -1, enabled)
end

---@description Format a log message
---@param level string The log level
---@param message string The message to log
---@param ... any Additional values to include in the log
---@return string formatted_message The formatted log message
function Logger.format(level, message, ...)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local color = Logger.colors[level] or Logger.colors.INFO
    local reset = Logger.colors.RESET
    
    local final_message = string.format("[%s] %s[%s]%s %s", 
        timestamp, 
        color, 
        level, 
        reset,
        message
    )
    
    local args = {...}
    if #args > 0 then
        for i, v in ipairs(args) do
            if type(v) == "table" then
                final_message = final_message .. " " .. Logger.table_to_string(v)
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
function Logger.table_to_string(t, indent)
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
            result = result .. Logger.table_to_string(v, indent + 1) .. ",\n"
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
function Logger.add_to_history(level, message)
    table.insert(Logger.history, {
        level = level,
        message = message,
        timestamp = os.time()
    })
    
    while #Logger.history > Logger.max_history do
        table.remove(Logger.history, 1)
    end
end

---@description Send a log to Discord webhook
---@param level string The log level
---@param message string The message to log
function Logger.send_to_webhook(level, message)
    if not Logger.use_webhook or Logger.log_webhook == "" then
        return
    end
    
    local color
    if level == "ERROR" or level == "FATAL" then
        color = 16711680 -- Red
    elseif level == "WARN" then
        color = 16776960 -- Yellow
    elseif level == "INFO" then
        color = 65280 -- Green
    else
        color = 255 -- Blue
    end
    
    local embeds = {
        {
            title = "SecureServe Log",
            description = message,
            color = color,
            footer = {
                text = "SecureServe Anti-Cheat"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(Logger.log_webhook, function() end, "POST", json.encode({
        username = "SecureServe Logger",
        embeds = embeds
    }), {["Content-Type"] = "application/json"})
end

---@description Log a debug message
---@param message string The message to log
---@param ... any Additional values to include in the log
function Logger.debug(message, ...)
    if Logger.levels.DEBUG < Logger.level then
        return
    end
    
    local formatted = Logger.format("DEBUG", message, ...)
    Logger.add_to_history("DEBUG", formatted)
    
    if Logger.debug_enabled then
        print(formatted)
    end
end

---@description Log an info message
---@param message string The message to log
---@param ... any Additional values to include in the log
function Logger.info(message, ...)
    if Logger.levels.INFO < Logger.level then
        return
    end
    
    local formatted = Logger.format("INFO", message, ...)
    Logger.add_to_history("INFO", formatted)
    
    if Logger.debug_enabled then
        print(formatted)
    end
    
    Logger.send_to_webhook("INFO", message)
end

---@description Log a warning message
---@param message string The message to log
---@param ... any Additional values to include in the log
function Logger.warn(message, ...)
    if Logger.levels.WARN < Logger.level then
        return
    end
    
    local formatted = Logger.format("WARN", message, ...)
    Logger.add_to_history("WARN", formatted)
    
    if Logger.debug_enabled then
        print(formatted)
    end
    
    Logger.send_to_webhook("WARN", message)
end

---@description Log an error message
---@param message string The message to log
---@param ... any Additional values to include in the log
function Logger.error(message, ...)
    if Logger.levels.ERROR < Logger.level then
        return
    end
    
    local formatted = Logger.format("ERROR", message, ...)
    Logger.add_to_history("ERROR", formatted)
    
    print(formatted)
    
    Logger.send_to_webhook("ERROR", message)
end

---@description Log a fatal error message
---@param message string The message to log
---@param ... any Additional values to include in the log
function Logger.fatal(message, ...)
    if Logger.levels.FATAL < Logger.level then
        return
    end
    
    local formatted = Logger.format("FATAL", message, ...)
    Logger.add_to_history("FATAL", formatted)
    
    print(formatted)
    
    Logger.send_to_webhook("FATAL", message)
end

---@description Get the log history
---@param count number The number of entries to retrieve (default: all)
---@param level string Optional filter by log level
---@return table log_entries The log entries
function Logger.get_history(count, level)
    local result = {}
    local start_index = count and (#Logger.history - count + 1) or 1
    start_index = math.max(1, start_index)
    
    for i = start_index, #Logger.history do
        local entry = Logger.history[i]
        if not level or entry.level == level then
            table.insert(result, entry)
        end
    end
    
    return result
end

---@description Clear the log history
function Logger.clear_history()
    Logger.history = {}
    Logger.debug("Log history cleared")
end

return Logger 