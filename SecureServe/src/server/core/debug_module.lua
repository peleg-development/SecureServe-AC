---@class DebugModule
local DebugModule = {
    enabled = false,
    error_count = 0,
    last_errors = {},
    max_error_history = 20,
    is_dev_mode = false,
    current_error_handler = nil
}

-- Dependencies
local logger = require("server/core/logger")

---@description Initialize the debug module
---@param config table Configuration options
function DebugModule.initialize(config)
    if config then
        DebugModule.enabled = config.DebugEnabled or false
        DebugModule.max_error_history = config.MaxErrorHistory or 20
        DebugModule.is_dev_mode = config.DevMode or false
    end
    
    DebugModule.setup_error_handler()
    
    logger.info("Debug module initialized. Debug mode: " .. tostring(DebugModule.enabled))
end

---@description Setup global error handling
function DebugModule.setup_error_handler()
    local original_error = error
    
    DebugModule.current_error_handler = function(err, level)
        DebugModule.handle_error(err, debug.traceback("", 2))
        return original_error(err, level or 1)
    end
    
    error = DebugModule.current_error_handler
    
    AddEventHandler("onResourceError", function(resourceName, err, file, line)
        if resourceName == GetCurrentResourceName() then
            local trace = "File: " .. (file or "unknown") .. ", Line: " .. (line or "?")
            DebugModule.handle_error(err, trace)
        end
    end)
    
    logger.debug("Error handler has been set up")
end

---@description Handle and log an error
---@param err string The error message
---@param trace string The stack trace
function DebugModule.handle_error(err, trace)
    DebugModule.error_count = DebugModule.error_count + 1
    
    local error_entry = {
        message = err,
        trace = trace,
        timestamp = os.time(),
        resource = GetCurrentResourceName()
    }
    
    table.insert(DebugModule.last_errors, 1, error_entry)
    
    while #DebugModule.last_errors > DebugModule.max_error_history do
        table.remove(DebugModule.last_errors)
    end
    
    logger.error("Error detected: " .. err)
    logger.debug("Error trace: " .. trace)
    
    if DebugModule.is_dev_mode then
        DebugModule.print_detailed_error(error_entry)
    end
end

---@description Print detailed error information
---@param error_entry table The error entry to print
function DebugModule.print_detailed_error(error_entry)
    print("^1================= DETAILED ERROR =================^7")
    print("^1Error: ^7" .. error_entry.message)
    print("^1Resource: ^7" .. error_entry.resource)
    print("^1Time: ^7" .. os.date("%Y-%m-%d %H:%M:%S", error_entry.timestamp))
    
    local trace_lines = DebugModule.format_stack_trace(error_entry.trace)
    print("^1Stack trace:^7")
    for i, line in ipairs(trace_lines) do
        print(line)
    end
    
    print("^1====================================================^7")
end

---@description Format a stack trace for better readability
---@param trace string The stack trace to format
---@return table formatted_lines The formatted trace lines
function DebugModule.format_stack_trace(trace)
    if not trace then return {"No trace available"} end
    
    local lines = {}
    for line in trace:gmatch("[^\r\n]+") do
        if not line:match("stack traceback:") then
            line = line:gsub("in function '([^']+)'", "in function '^3%1^7'")
            line = line:gsub("([^:]+):(%d+):", "^2%1^7:^5%2^7:")
            
            table.insert(lines, "  " .. line)
        end
    end
    
    return lines
end

---@description Get error statistics
---@return table stats Error statistics
function DebugModule.get_error_stats()
    return {
        total_errors = DebugModule.error_count,
        recent_errors = #DebugModule.last_errors,
        debug_enabled = DebugModule.enabled,
        dev_mode = DebugModule.is_dev_mode
    }
end

---@description Get the most recent errors
---@param count number Number of errors to retrieve (default: all)
---@return table errors The most recent errors
function DebugModule.get_recent_errors(count)
    local result = {}
    local limit = count or #DebugModule.last_errors
    
    for i = 1, math.min(limit, #DebugModule.last_errors) do
        table.insert(result, DebugModule.last_errors[i])
    end
    
    return result
end

---@description Clear the error history
function DebugModule.clear_errors()
    DebugModule.last_errors = {}
    logger.debug("Error history cleared")
end

---@description Enable or disable debug mode
---@param enabled boolean Whether debug mode should be enabled
function DebugModule.set_debug_mode(enabled)
    DebugModule.enabled = enabled
    logger.info("Debug mode " .. (enabled and "enabled" or "disabled"))
end

---@description Enable or disable developer mode
---@param enabled boolean Whether developer mode should be enabled
function DebugModule.set_dev_mode(enabled)
    DebugModule.is_dev_mode = enabled
    logger.info("Developer mode " .. (enabled and "enabled" or "disabled"))
end

---@description Create a protected call that catches errors
---@param func function The function to call
---@param ... any Arguments to pass to the function
---@return boolean success Whether the call succeeded
---@return any result The result of the function call or the error message
function DebugModule.protected_call(func, ...)
    if not func then
        return false, "No function provided"
    end
    
    local args = {...}
    local success, result = pcall(function()
        return func(table.unpack(args))
    end)
    
    if not success then
        DebugModule.handle_error(result, debug.traceback("", 2))
        return false, result
    end
    
    return true, result
end

return DebugModule 