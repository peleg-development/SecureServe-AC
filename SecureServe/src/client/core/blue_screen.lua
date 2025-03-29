---@class BlueScreenModule
local BlueScreen = {}
local bluescreenActive = false

---@description Initialize the blue screen module
function BlueScreen.initialize()
    local bluescreenActive = false

    RegisterNetEvent("SecureServe:ShowWindowsBluescreen", function()
        if bluescreenActive then return end
        bluescreenActive = true

        local soundId = GetSoundId()
        PlaySoundFrontend(soundId, "Bed", "WastedSounds", true)

        local stopCodes = {
            "SYSTEM_SERVICE_EXCEPTION",
            "CRITICAL_PROCESS_DIED",
            "PAGE_FAULT_IN_NONPAGED_AREA",
            "MEMORY_MANAGEMENT",
            "UNEXPECTED_KERNEL_MODE_TRAP",
            "DPC_WATCHDOG_VIOLATION",
            "IRQL_NOT_LESS_OR_EQUAL",
            "KERNEL_SECURITY_CHECK_FAILURE",
            "SYSTEM_THREAD_EXCEPTION_NOT_HANDLED",
            "UNEXPECTED_STORE_EXCEPTION",
            "DRIVER_POWER_STATE_FAILURE",
            "KMODE_EXCEPTION_NOT_HANDLED"
        }

        local cheatingErrorCodes = {
            "SECURE_SERV_ANTICHEAT_VIOLATION",
            "MEMORY_INTEGRITY_FAILURE",
            "CHEAT_ENGINE_DETECTED",
            "MEMORY_INJECTION_DETECTED",
            "INVALID_GAME_MODIFICATION",
            "PROCESS_TAMPERING_DETECTED"
        }

        local stopCode = math.random() > 0.4
            and cheatingErrorCodes[math.random(1, #cheatingErrorCodes)]
            or stopCodes[math.random(1, #stopCodes)]

        local randomErr = string.format("0x%08X", math.random(0, 4294967295))

        local percent = 0
        local lastUpdate = GetGameTimer()

        Citizen.CreateThread(function()
            SetNuiFocus(true, true)

            while bluescreenActive do
                DisableAllControlActions(0)

                DrawRect(0.5, 0.5, 1.0, 1.0, 0, 120, 212, 255)

                SetTextFont(4)
                SetTextScale(1.8, 1.8)
                SetTextColour(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextDropShadow(0, 0, 0, 0, 255)
                SetTextEdge(0, 0, 0, 0, 0)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(":(")
                EndTextCommandDisplayText(0.5, 0.22)

                SetTextFont(4)
                SetTextScale(0.65, 0.65)
                SetTextColour(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextDropShadow(0, 0, 0, 0, 255)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName("Your PC ran into a problem and needs to restart.")
                EndTextCommandDisplayText(0.5, 0.33)

                SetTextFont(4)
                SetTextScale(0.43, 0.43)
                SetTextColour(255, 255, 255, 190)
                SetTextCentre(true)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(
                "We're just collecting some error info, and then we'll restart for you.")
                EndTextCommandDisplayText(0.5, 0.39)

                local currentTime = GetGameTimer()
                if currentTime - lastUpdate > 30 then
                    if percent < 30 then
                        percent = percent + math.random(2, 3)
                    elseif percent < 70 then
                        percent = percent + math.random(3, 5)
                    elseif percent < 90 then
                        percent = percent + math.random(1, 3)
                    elseif percent < 100 then
                        percent = percent + 1
                    end
                    percent = math.min(percent, 100)
                    lastUpdate = currentTime
                end

                SetTextFont(4)
                SetTextScale(0.43, 0.43)
                SetTextColour(255, 255, 255, 190)
                SetTextCentre(true)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(percent .. "% complete")
                EndTextCommandDisplayText(0.5, 0.44)

                SetTextFont(4)
                SetTextScale(0.37, 0.37)
                SetTextColour(255, 255, 255, 190)
                SetTextCentre(false)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(
                "If you'd like to know more, you can search online later for this error:")
                EndTextCommandDisplayText(0.33, 0.7)

                SetTextFont(4)
                SetTextScale(0.37, 0.37)
                SetTextColour(255, 255, 255, 190)
                SetTextCentre(false)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(stopCode)
                EndTextCommandDisplayText(0.33, 0.74)

                SetTextFont(4)
                SetTextScale(0.37, 0.37)
                SetTextColour(255, 255, 255, 190)
                SetTextCentre(false)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(randomErr)
                EndTextCommandDisplayText(0.33, 0.78)

                Citizen.Wait(0)
            end

            SetNuiFocus(false, false)
        end)

        Citizen.SetTimeout(3000, function()
            bluescreenActive = false
            if soundId then
                StopSound(soundId)
                ReleaseSoundId(soundId)
            end
        end)
    end)

    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end
        bluescreenActive = false
        SetNuiFocus(false, false)
    end)
end

return BlueScreen
