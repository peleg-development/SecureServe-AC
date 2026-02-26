---@class ScreenshotHelperModule
local ScreenshotHelper = {}

local providers = {
    {
        name = "screencapture",
        upload = "requestScreenshotUpload",
        capture = "requestScreenshot",
        player_capture = "serverCapture"
    },
    {
        name = "screenshot-basic",
        upload = "requestScreenshotUpload",
        capture = "requestScreenshot",
        player_capture = "requestClientScreenshot"
    }
}

local function get_export(resource_name)
    if _G.exports and _G.exports[resource_name] then
        return _G.exports[resource_name]
    end
    if exports and exports[resource_name] then
        return exports[resource_name]
    end
    return nil
end

local function find_provider(method_key)
    for _, provider in ipairs(providers) do
        local export_ref = get_export(provider.name)
        local method_name = provider[method_key]
        if export_ref and method_name and type(export_ref[method_name]) == "function" then
            return export_ref, provider.name, method_name
        end
    end
    return nil, nil, nil
end

---@return table|nil export_ref
---@return string|nil provider
function ScreenshotHelper.get_upload_provider()
    local export_ref, provider = find_provider("upload")
    return export_ref, provider
end

---@return table|nil export_ref
---@return string|nil provider
function ScreenshotHelper.get_capture_provider()
    local export_ref, provider = find_provider("capture")
    return export_ref, provider
end

---@param webhook_url string
---@param field_name string|nil
---@param options table|nil
---@param callback function|nil
---@return boolean started
---@return string|nil provider
function ScreenshotHelper.request_upload(webhook_url, field_name, options, callback)
    local export_ref, provider, method_name = find_provider("upload")
    if not export_ref then
        if callback then callback(nil, nil) end
        return false, nil
    end

    export_ref[method_name](export_ref, webhook_url, field_name or "files[]", options or {}, function(data)
        if callback then callback(data, provider) end
    end)

    return true, provider
end

---@param options table|nil
---@param callback function|nil
---@return boolean started
---@return string|nil provider
function ScreenshotHelper.request_capture(options, callback)
    local export_ref, provider, method_name = find_provider("capture")
    if not export_ref then
        if callback then callback(nil, nil) end
        return false, nil
    end

    export_ref[method_name](export_ref, options or {}, function(data)
        if callback then callback(data, provider) end
    end)

    return true, provider
end

---@param player_id number|string
---@param options table|nil
---@param callback function|nil
---@return boolean started
---@return string|nil provider
function ScreenshotHelper.capture_player(player_id, options, callback)
    for _, provider in ipairs(providers) do
        local export_ref = get_export(provider.name)
        local method_name = provider.player_capture
        if export_ref and method_name and type(export_ref[method_name]) == "function" then
            if provider.name == "screencapture" then
                export_ref[method_name](export_ref, tostring(player_id), options or {}, function(data)
                    if callback then callback(data, nil, provider.name) end
                end)
            else
                export_ref[method_name](export_ref, tonumber(player_id), options or {}, function(err, data)
                    if callback then callback(data, err, provider.name) end
                end)
            end
            return true, provider.name
        end
    end

    if callback then callback(nil, "No screenshot provider available", nil) end
    return false, nil
end

---@param response_data string|nil
---@return string|nil screenshot_url
function ScreenshotHelper.extract_uploaded_url(response_data)
    if type(response_data) ~= "string" or response_data == "" then
        return nil
    end

    local ok, payload = pcall(json.decode, response_data)
    if not ok or type(payload) ~= "table" then
        return nil
    end

    local attachment = payload.attachments and payload.attachments[1]
    if attachment and type(attachment.proxy_url) == "string" and attachment.proxy_url ~= "" then
        return attachment.proxy_url
    end
    if attachment and type(attachment.url) == "string" and attachment.url ~= "" then
        return attachment.url
    end

    return nil
end

return ScreenshotHelper
