local ProtectionManager = require("client/protections/protection_manager")
local Cache = require("client/core/cache")

---@class AntiOcrModule
local AntiOcr = {
    is_busy = false
}

---@description Initialize Anti OCR protection
function AntiOcr.initialize()
    if not SecureServe.OCR then return end

    local ocrWords = {}
    local screenshotInterval = 5500

    if type(SecureServe.OCR) == "table" then
        if SecureServe.OCR.Words then
            ocrWords = SecureServe.OCR.Words
            screenshotInterval = SecureServe.OCR.ScreenshotInterval or 5500
        else
            screenshotInterval = SecureServe.OCR.ScreenshotInterval or 5500

            for key, value in pairs(SecureServe.OCR) do
                if type(key) == "number" and type(value) == "string" then
                    table.insert(ocrWords, value)
                end
            end

            table.sort(ocrWords, function(a, b) return a < b end)
        end
    end

    if not ocrWords or #ocrWords == 0 then
        return
    end

    RegisterNUICallback("checktext", function(data, cb)
        if Cache.Get("hasPermission", "ocr")
            or Cache.Get("hasPermission", "all")
            or Cache.Get("isAdmin")
        then
            AntiOcr.is_busy = false
            if cb then cb({ success = true }) end
            return
        end

        if type(data) ~= "table" or type(data.image) ~= "string" or type(data.text) ~= "string" then
            AntiOcr.is_busy = false
            if cb then cb({ success = false }) end
            return
        end

        if #data.text > 8192 then
            data.text = data.text:sub(1, 8192)
        end

        for index, word in next, ocrWords, nil do
            if string.find(string.lower(data.text), string.lower(word)) then
                local ocr_webhook = ConfigLoader.get_protection_setting("Anti OCR", "webhook") or ""
                if ocr_webhook == "" and SecureServe and SecureServe.Webhooks then
                    ocr_webhook = SecureServe.Webhooks.Simple or ""
                end

                if ocr_webhook == ""
                    or not exports['screenshot-basic']
                    or type(exports['screenshot-basic'].requestScreenshotUpload) ~= "function"
                then
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
                else
                    local success = pcall(function()
                        exports['screenshot-basic']:requestScreenshotUpload(
                            ocr_webhook,
                            'files[]',
                            { encoding = "webp", quality = 1 },
                            function(result)
                                local screenshot_url = nil
                                if result and result ~= "" then
                                    local ok, resp = pcall(json.decode, result)
                                    if ok and resp and resp.attachments and resp.attachments[1] and resp.attachments[1].proxy_url then
                                        screenshot_url = resp.attachments[1].proxy_url
                                    end
                                end
                                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", screenshot_url, "Found word on screen [OCR]: " .. word)
                            end
                        )
                    end)

                    if not success then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
                    end
                end
                break
            end
        end
        AntiOcr.is_busy = false
        if cb then cb({ success = true }) end
    end)

    Citizen.CreateThread(function()
        Citizen.Wait(5000)

        if not exports['screenshot-basic'] or type(exports['screenshot-basic'].requestScreenshot) ~= "function" then
            if SecureServe and SecureServe.Debug then
                print("^3[SecureServe] Anti OCR disabled: 'screenshot-basic' resource not running.^7")
            end
            return
        end

        while ocrWords and #ocrWords > 0 do
            if not AntiOcr.is_busy and not IsPauseMenuActive() then
                local success, error = pcall(function()
                    exports['screenshot-basic']:requestScreenshot({ encoding = "webp" }, function(data)
                        Citizen.Wait(1000)
                        SendNUIMessage({
                            action = GetCurrentResourceName() .. ":checkString",
                            image = data
                        })
                    end)
                end)

                if not success then
                    if SecureServe and SecureServe.Debug then
                        print("ERROR taking OCR screenshot: " .. tostring(error))
                    end
                else
                    AntiOcr.is_busy = true
                end
            end
            Citizen.Wait(screenshotInterval)
        end
    end)
end

ProtectionManager.register_protection("ocr", AntiOcr.initialize)

return AntiOcr
