local Require = {
    loaded = {},
    failed = {},
    paths = {
        "src/",
        "",
    },
}

local function enhanced_error_handler(err, module_name, trace_level)
    trace_level = trace_level or 2
    local trace = debug.traceback("", trace_level)

    local formatted = "\n^1============ SECURESERVE ERROR ============^7\n"
        .. "^1Module: ^3" .. tostring(module_name) .. "^7\n"
        .. "^1Message: ^3" .. tostring(err) .. "^7\n"
        .. "^1Traceback: ^7\n" .. trace:gsub("stack traceback:", "^3Stack traceback:^7")
        .. "\n^1==========================================^7\n"
    print(formatted)
end

function Require.load(module_name)
    local normalized = module_name
    if normalized:match("^server/") or normalized:match("^client/") or normalized:match("^shared/") then
        normalized = "src/" .. normalized
    end

    if Require.loaded[normalized] ~= nil then
        return Require.loaded[normalized]
    end

    local module_path, code

    local clean_name = module_name:gsub("^src/", "")

    for _, path in ipairs(Require.paths) do
        for _, suffix in ipairs({ ".lua", "/init.lua" }) do
            local full = path .. clean_name .. suffix
            local ok = pcall(function()
                code = LoadResourceFile(GetCurrentResourceName(), full)
            end)
            if ok and code and code ~= "" then
                module_path = full
                break
            end
        end
        if module_path then break end
    end

    if not module_path or not code then
        if not Require.failed[normalized] then
            Require.failed[normalized] = true
            enhanced_error_handler("Module not found: " .. module_name, module_name)
        end
        return nil
    end

    local module_env = setmetatable({
        require = function(name) return Require.load(name) end,
    }, { __index = _G })

    local module_func, err = load(code, "@" .. module_path, "bt", module_env)
    if not module_func then
        if not Require.failed[normalized] then
            Require.failed[normalized] = true
            enhanced_error_handler("Error loading module: " .. tostring(err), module_name)
        end
        return nil
    end

    local ok, result = pcall(module_func)
    if not ok then
        if not Require.failed[normalized] then
            Require.failed[normalized] = true
            enhanced_error_handler("Error executing module: " .. tostring(result), module_name)
        end
        return nil
    end

    if result == nil then
        result = true
    end

    Require.loaded[normalized] = result
    Require.failed[normalized] = nil
    return result
end

function Require.add_path(path)
    table.insert(Require.paths, 1, path)
end

if not _G.SecureServeErrorHandler then
    _G.SecureServeErrorHandler = function(err)
        local trace = debug.traceback("", 2)
        local formatted = "\n^1============ SECURESERVE RUNTIME ERROR ============^7\n"
            .. "^1Error: ^3" .. tostring(err) .. "^7\n"
            .. "^1Traceback: ^7\n" .. trace:gsub("stack traceback:", "^3Stack traceback:^7")
            .. "\n^1================================================^7\n"
        print(formatted)
        return err
    end
end

if _G.require ~= Require.load then
    _G.require = Require.load
end

return Require
