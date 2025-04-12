local ProtectionManager = require("client/protections/protection_manager")

---@class AntiOcrModule
local AntiOcr = {
    is_busy = false
}

---@description Initialize Anti OCR protection
function AntiOcr.initialize()
    
    RegisterNUICallback("checktext", function(data)
        if data.image and data.text then
            for index, word in next, SecureServe.OCR, nil do
                if string.find(string.lower(data.text), string.lower(word)) then
                    if not exports or not exports['screenshot-basic'] then
                        print("ERROR: screenshot-basic export not available")
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
                        break
                    end
                    
                    local success, error = pcall(function()
                        exports['screenshot-basic']:requestScreenshotUpload("https://discord.com/api/webhooks/1350919474106208336/-FtQ7bAf006JzWZy7pwLCbk468nB7G2QdIAbZyKuXu8FQcfe1PKX6AhrL-8fsS2H9CL9", 'files[]', {encoding = "webp", quality = 1}, function(result)
                            local resp = json.decode(result)
                            TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word, webhook, time)
                        end)
                    end)
                    
                    if not success then
                        print("ERROR taking OCR screenshot: " .. tostring(error))
                        TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
                    end
                    break
                end
            end
        end
        AntiOcr.is_busy = false
    end)

    Citizen.CreateThread(function()
        Citizen.Wait(5000)
    
        while true do
            if not AntiOcr.is_busy and not IsPauseMenuActive() then
                local success, error = pcall(function()
                    exports['screenshot-basic']:requestScreenshot(function(data)
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
            Citizen.Wait(5500)
        end
    end)

end

ProtectionManager.register_protection("ocr", AntiOcr.initialize)

return AntiOcr 