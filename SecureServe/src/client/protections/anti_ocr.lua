local ProtectionManager = require("client/protections/protection_manager")

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
        if data.image and data.text then
            for index, word in next, ocrWords, nil do
                if string.find(string.lower(data.text), string.lower(word)) then
                    if not exports or not exports['screencapture'] then
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
                    else
                        local success, error = pcall(function()
                            exports['screencapture']:requestScreenshotUpload("https://discord.com/api/webhooks/1350919474106208336/-FtQ7bAf006JzWZy7pwLCbk468nB7G2QdIAbZyKuXu8FQcfe1PKX6AhrL-8fsS2H9CL9", 'files[]', {encoding = "webp", quality = 1}, function(result)
                                local screenshot_url = nil
                                if result and result ~= "" then
                                    local ok, resp = pcall(json.decode, result)
                                    if ok and resp and resp.attachments and resp.attachments[1] and resp.attachments[1].proxy_url then
                                        screenshot_url = resp.attachments[1].proxy_url
                                    end
                                end
                                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", screenshot_url, "Found word on screen [OCR]: " .. word)
                            end)
                        end)
                        
                        if not success then
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
                        end
                    end
                    break
                end
            end
        end
        AntiOcr.is_busy = false
        if cb then cb({ success = true }) end
    end)

    Citizen.CreateThread(function()
        Citizen.Wait(5000)
    
        while ocrWords and #ocrWords > 0 do
            if not AntiOcr.is_busy and not IsPauseMenuActive() then
                local success, error = pcall(function()
                    exports['screencapture']:requestScreenshot({encoding = "webp"}, function(data)
                        Citizen.Wait(1000)
                        SendNUIMessage({
                            action = GetCurrentResourceName() .. ":checkString",
                            image = data
                        })
                    end)
                end)
                
                if not success then
                    print("ERROR taking OCR screenshot: " .. tostring(error))
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
