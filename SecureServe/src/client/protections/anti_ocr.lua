local ProtectionManager = require("client/protections/protection_manager")

---@class AntiOcrModule
local AntiOcr = {}

---@description Initialize Anti OCR protection
function AntiOcr.initialize()
    local is_busy = false

    RegisterNUICallback("checktext", function(data)
        if data.image and data.text then
            for index, word in next, SecureServe.OCR, nil do
                if string.find(string.lower(data.text), string.lower(word)) then
                    exports['screencapture']:requestScreenshotUpload("https://discord.com/api/webhooks/1350919474106208336/-FtQ7bAf006JzWZy7pwLCbk468nB7G2QdIAbZyKuXu8FQcfe1PKX6AhrL-8fsS2H9CL9", 'files[]', {encoding = "webp", quality = 1}, function(result)
                        local resp = json.decode(result)
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word, webhook, time)
                    end)
                    break
                end
            end
        end
        is_busy = false
    end)

    Citizen.CreateThread(function()
        Citizen.Wait(5000)
    
        while true do
            if not is_busy and not IsPauseMenuActive() then
                exports['screencapture']:requestScreenshot(function(data)
                    Citizen.Wait(1000)
                    SendNUIMessage({
                        action = GetCurrentResourceName() .. ":checkString",
                        image = data
                    })
                end)
                is_busy = true
            end
            Citizen.Wait(5500)
        end
    end)

end

ProtectionManager.register_protection("ocr", AntiOcr.initialize)

return AntiOcr 