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
                    -- Fix: hardcoded Discord webhook removed (it shipped to every client = leak). The OCR screenshot is no longer captured at all (PunishPlayer does not take one): assumed loss of evidence, not a move server-side.
                    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
                    break
                end
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
