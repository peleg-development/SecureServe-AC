local session_token       = nil
local ping_counter        = 0
local hello_attempts      = 0
local ss_missing_strikes  = 0

local SS_MISSING_STRIKES  = 6

local function send_hello()
    hello_attempts = hello_attempts + 1
    TriggerServerEvent("keepalive:hello")
end

RegisterNetEvent("keepalive:assign", function(token)
    if type(token) == "string" and #token == 32 then
        session_token  = token
        ping_counter   = 0
        hello_attempts = 0

        ping_counter = ping_counter + 1
        TriggerServerEvent("keepalive:tick", session_token, ping_counter)
    end
end)
CreateThread(function()
    Wait(2000)
    while not session_token do
        send_hello()
        local backoff = math.min(3000 + hello_attempts * 500, 15000)
        Wait(backoff)
    end
end)
CreateThread(function()
    while true do
        local jitter = math.random(3500, 4500)
        Wait(jitter)

        if session_token then
            ping_counter = ping_counter + 1
            TriggerServerEvent("keepalive:tick", session_token, ping_counter)
        end
    end
end)

CreateThread(function()
    Wait(20000)

    while true do
        Wait(5000)
        local state = GetResourceState("SecureServe")

        if state == "stopped" or state == "missing" then
            ss_missing_strikes = ss_missing_strikes + 1
            if ss_missing_strikes >= SS_MISSING_STRIKES and session_token then
                TriggerServerEvent("keepalive:ssMissing")
                ss_missing_strikes = 0
            end
        elseif state == "started" then
            ss_missing_strikes = 0
        end
    end
end)
