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
    max_history = 4,
    history = {},
    debug_enabled = false,
    cleanup_thread = nil,
    last_cleanup = 0
}

---@description Initialize the client logger
---@param config table Configuration options
function ClientLogger.initialize(config)
    if ClientLogger.cleanup_thread then
        TerminateThread(ClientLogger.cleanup_thread)
        ClientLogger.cleanup_thread = nil
    end
    
    ClientLogger.history = {}
    ClientLogger.last_cleanup = GetGameTimer()
    
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
    
    ClientLogger.cleanup_thread = Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) 
            
            local current_time = GetGameTimer()
            if (current_time - ClientLogger.last_cleanup) < 60000 then
                goto continue 
            end
            
            if #ClientLogger.history > (ClientLogger.max_history * 1.5) then
                local target_size = ClientLogger.max_history
                local history_copy = {}
                
                for i = #ClientLogger.history - target_size + 1, #ClientLogger.history do
                    if ClientLogger.history[i] then
                        table.insert(history_copy, ClientLogger.history[i])
                    end
                end
                
                ClientLogger.history = history_copy
                ClientLogger.last_cleanup = current_time
                
                collectgarbage("step", 50)
            end
            
            ::continue::
        end
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
    
    local final_message = string.format("[%s%s%s] %s", 
        color, 
        level, 
        reset,
        message
    )
    
    local args = {...}
    if #args > 0 then
        for i, v in ipairs(args) do
            if type(v) == "table" then
                final_message = final_message .. " " .. ClientLogger.simple_table_format(v)
            else
                final_message = final_message .. " " .. tostring(v)
            end
        end
    end
    
    return final_message
end

function ClientLogger.simple_table_format(t)
    if type(t) ~= "table" then return tostring(t) end
    
    local count = 0
    local max_entries = 5
    local result = "{"
    
    for k, v in pairs(t) do
        count = count + 1
        if count > max_entries then
            result = result .. ",...}"
            return result
        end
        
        local val
        if type(v) == "table" then
            val = "{...}"
        elseif type(v) == "string" and #v > 20 then
            val = string.sub(v, 1, 20) .. "..."
        else
            val = tostring(v)
        end
        
        result = result .. tostring(k) .. "=" .. val
        
        if count < max_entries then
            result = result .. ","
        end
    end
    
    return result .. "}"
end

---@description Add a log entry to the history
---@param level string The log level
---@param message string The message to log
function ClientLogger.add_to_history(level, message)
    if level == "DEBUG" and not ClientLogger.debug_enabled then
        return
    end
    
    if #message > 200 then 
        message = string.sub(message, 1, 200) .. "..."
    end
    
    table.insert(ClientLogger.history, {
        level = level,
        message = message,
        time = GetGameTimer()
    })
    
    if #ClientLogger.history > (ClientLogger.max_history * 1.5) then
        local current_time = GetGameTimer()
        
        if (current_time - ClientLogger.last_cleanup) < 30000 then
            return
        end
        
        local target_size = ClientLogger.max_history
        local history_copy = {}
        
        for i = #ClientLogger.history - target_size + 1, #ClientLogger.history do
            if ClientLogger.history[i] then
                table.insert(history_copy, ClientLogger.history[i])
            end
        end
        
        ClientLogger.history = history_copy
        ClientLogger.last_cleanup = current_time
    end
end

---@description Send a log to the server for potential Discord logging
---@param level string The log level
---@param message string The message to log
function ClientLogger.send_to_server(level, message)
    if level == "ERROR" or level == "FATAL" then
        if #message > 500 then 
            message = string.sub(message, 1, 500) .. "..."
        end
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
    
    if not ClientLogger.debug_enabled then
        return
    end
    
    local formatted = ClientLogger.format("DEBUG", message, ...)
    ClientLogger.add_to_history("DEBUG", formatted)
    
    print(formatted)
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
    
    if #message < 100 then 
        TriggerServerEvent("SecureServe:ForwardLog", "WARN", message)
    end
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
    local actual_count = math.min(count or #ClientLogger.history, #ClientLogger.history)
    local start_index = #ClientLogger.history - actual_count + 1
    start_index = math.max(1, start_index)
    
    for i = start_index, #ClientLogger.history do
        local entry = ClientLogger.history[i]
        if not level or entry.level == level then
            table.insert(result, entry)
        end
    end
    
    return result
end

---@description Set the debug mode
---@param enabled boolean The debug mode
function ClientLogger.set_debug_mode(enabled)
    ClientLogger.debug_enabled = enabled
end

function ClientLogger.cleanup()
    if ClientLogger.cleanup_thread then
        TerminateThread(ClientLogger.cleanup_thread)
        ClientLogger.cleanup_thread = nil
    end
    
    ClientLogger.history = {}
    collectgarbage("step", 50)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    ClientLogger.cleanup()
end)

return ClientLogger 