---@class DebugModule
local DebugModule = {
    error_count = 0,
    recent_errors = {},
    max_errors = 10,
    is_dev_mode = false
}

local logger = require("server/core/logger")

---@description Initialize the debug module
function DebugModule.initialize()
    local config = SecureServe or {}
    DebugModule.max_errors = config.MaxErrorHistory or DebugModule.max_errors
        DebugModule.is_dev_mode = config.DevMode or false
end

---@description Handle and log an error
---@param err string The error message
---@param trace string The stack trace
function DebugModule.handle_error(err, trace)
    DebugModule.error_count = DebugModule.error_count + 1
    
    local entry = {
        message = tostring(err),
        trace = trace,
        timestamp = os.time()
    }
    
    table.insert(DebugModule.recent_errors, 1, entry)
    
    while #DebugModule.recent_errors > DebugModule.max_errors do
        table.remove(DebugModule.recent_errors)
    end
    
    if logger then
        logger.error("Error: " .. tostring(err))
    end
    
    if DebugModule.is_dev_mode and trace then
        print(trace)
    end
end

---@description Enable or disable developer mode
---@param enabled boolean Whether developer mode should be enabled
function DebugModule.set_dev_mode(enabled)
    DebugModule.is_dev_mode = enabled == true
end

---@description Get error statistics
---@return table stats Error statistics
function DebugModule.get_error_stats()
    return {
        total_errors = DebugModule.error_count,
        recent_errors = #DebugModule.recent_errors,
        dev_mode = DebugModule.is_dev_mode
    }
end

return DebugModule 