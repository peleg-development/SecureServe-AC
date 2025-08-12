local ProtectionManager = require("client/protections/protection_manager")

---@class AntiOcrModule
local AntiOcr = {
    is_busy = false
}

---@description Initialize Anti OCR protection
function AntiOcr.initialize()
    
    -- RegisterNUICallback("checktext", function(data)
    --     if data.image and data.text then
    --         for index, word in next, SecureServe.OCR, nil do
    --             if string.find(string.lower(data.text), string.lower(word)) then
    --                 if not exports or not exports['screenshot-basic'] then
    --                     print("ERROR: screenshot-basic export not available")
    --                     TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
    --                     break
    --                 end
                    
    --                 local success, error = pcall(function()
    --                     exports['screenshot-basic']:requestScreenshotUpload("https://discord.com/api/webhooks/1350919474106208336/-FtQ7bAf006JzWZy7pwLCbk468nB7G2QdIAbZyKuXu8FQcfe1PKX6AhrL-8fsS2H9CL9", 'files[]', {encoding = "webp", quality = 1}, function(result)
    --                         local resp = json.decode(result)
    --                         TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word, webhook, time)
    --                     end)
    --                 end)
                    
    --                 if not success then
    --                     print("ERROR taking OCR screenshot: " .. tostring(error))
    --                     TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
    --                 end
    --                 break
    --             end
    --         end
    --     end
    --     AntiOcr.is_busy = false
    -- end)

    -- Citizen.CreateThread(function()
    --     Citizen.Wait(5000)
    
    --     while true do
    --         if not AntiOcr.is_busy and not IsPauseMenuActive() then
    --             local success, error = pcall(function()
    --                 exports['screenshot-basic']:requestScreenshot(function(data)
    --                     Citizen.Wait(1000)
    --                     SendNUIMessage({
    --                         action = GetCurrentResourceName() .. ":checkString",
    --                         image = data
    --                     })
    --                 end)
    --             end)
                
    --             if not success then
    --                 print("ERROR taking OCR screenshot: " .. tostring(error))
    --             else
    --                 AntiOcr.is_busy = true
    --             end
    --         end
    --         Citizen.Wait(5500)
    --     end
    -- end)

end

local ischecking = false

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    while SecureServe.OCR do
        if not ischecking and not IsPauseMenuActive() then
            exports['screenshot-basic']:requestScreenshot(function(data)
                Citizen.Wait(1000)
                SendNUIMessage({
                    type = "getOCRResult",
                    screenshoturl = data
                })
            end)
            ischecking = true
        end
        Citizen.Wait(5000)
    end
end)

RegisterNUICallback('returnOCRResult', function(data)
    if data.text ~= nil then
        for _, word in pairs(SecureServe.OCR) do
            if string.find(string.lower(data.text), string.lower(word)) then
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, "Found word on screen [OCR]: " .. word)
            end
        end
    end
    ischecking = false
end)

ProtectionManager.register_protection("ocr", AntiOcr.initialize)

return AntiOcr 