---@class RequireLibrary
---@field loaded table Table of loaded modules
---@field paths table Paths to search for modules
local Require = {
    loaded = {},
    paths = {
        "./src/shared/",
        "./src/client/",
        "./src/server/",
        "./"
    }
}

---@description Set a custom error handler that provides more detailed error information
---@param err string The error message
---@param module_name string The module name that caused the error
---@param trace_level number The level to start tracing from
---@return nil
local function enhanced_error_handler(err, module_name, trace_level)
    local trace_level = trace_level or 2
    local trace = debug.traceback("", trace_level)
    
    local formatted_error = "\n^1============ SECURESERVE ERROR ============^7\n"
    formatted_error = formatted_error .. "^1Error in module: ^3" .. tostring(module_name) .. "^7\n"
    formatted_error = formatted_error .. "^1Message: ^3" .. tostring(err) .. "^7\n"
    formatted_error = formatted_error .. "^1Traceback: ^7\n" .. trace:gsub("stack traceback:", "^3Stack traceback:^7")
    formatted_error = formatted_error .. "\n^1==========================================^7\n"
    
    print(formatted_error)
    
    return err
end

---@param module_name string The name of the module to require
---@return any The exported module content
function Require.load(module_name)
    if Require.loaded[module_name] then
        return Require.loaded[module_name]
    end
    
    if module_name:match("^server/") then
        module_name = "src/" .. module_name
    elseif module_name:match("^client/") then
        module_name = "src/" .. module_name
    elseif module_name:match("^shared/") then
        module_name = "src/" .. module_name
    end
    
    local module_path = nil
    local code = nil
    
    for _, path in ipairs(Require.paths) do
        local full_path = path .. module_name .. ".lua"
        local success = pcall(function()
            code = LoadResourceFile(GetCurrentResourceName(), full_path)
        end)
        
        if success and code and code ~= "" then
            module_path = full_path
            break
        end
        
        full_path = path .. module_name .. "/init.lua"
        success = pcall(function()
            code = LoadResourceFile(GetCurrentResourceName(), full_path)
        end)
        
        if success and code and code ~= "" then
            module_path = full_path
            break
        end
        
        full_path = module_name .. ".lua"
        success = pcall(function()
            code = LoadResourceFile(GetCurrentResourceName(), full_path)
        end)
        
        if success and code and code ~= "" then
            module_path = full_path
            break
        end
    end
    
    if not module_path or not code then
        return enhanced_error_handler("Module not found: " .. module_name, module_name)
    end
    
    local module_env = setmetatable({
        require = function(name) return Require.load(name) end,
    }, {__index = _G})
    
    local module_func, err = load(code, module_path, "bt", module_env)
    if not module_func then
        return enhanced_error_handler("Error loading module: " .. tostring(err), module_name)
    end
    
    local success, result = pcall(module_func)
    if not success then
        return enhanced_error_handler("Error executing module: " .. tostring(result), module_name)
    end
    
    local module_exports = result or module_env.exports
    
    Require.loaded[module_name] = module_exports
    
    return module_exports
end

---@param path string Path to add to the require paths
function Require.add_path(path)
    table.insert(Require.paths, 1, path)
end

_G.SecureServeErrorHandler = function(err)
    local trace = debug.traceback("", 2)
    
    local formatted_error = "\n^1============ SECURESERVE RUNTIME ERROR ============^7\n"
    formatted_error = formatted_error .. "^1Error: ^3" .. tostring(err) .. "^7\n"
    formatted_error = formatted_error .. "^1Traceback: ^7\n" .. trace:gsub("stack traceback:", "^3Stack traceback:^7")
    formatted_error = formatted_error .. "\n^1================================================^7\n"
    
    print(formatted_error)
    
    return err
end

_G.require = function(module_name)
    return Require.load(module_name)
end

return Require 