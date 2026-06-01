-- keep-alive: canary del anticheat SecureServe.
--
-- Manda un tick periodico al servidor con un token de sesion y un counter
-- monotono creciente. Si el servidor deja de recibir ticks de un cliente o
-- detecta que SecureServe no esta cargado en el cliente -> ban.
--
-- IMPORTANTE: los nombres de evento (keepalive:hello, keepalive:assign,
-- keepalive:tick, keepalive:ssMissing) deben coincidir con los que el modulo
-- canary.lua del SecureServe registra en el lado servidor. No los cambies
-- por separado.

local session_token       = nil
local ping_counter        = 0
local hello_attempts      = 0
local ss_missing_strikes  = 0

local SS_MISSING_STRIKES  = 6   -- ~30s consecutivos en estado parado antes de avisar

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

RegisterNetEvent("keepalive:request_hello", function()
    session_token = nil
    ping_counter = 0
    hello_attempts = 0
    send_hello()
end)


-- //[Hello loop: pide el token al servidor hasta tenerlo]\\ --
-- Reintentamos para siempre con backoff. El cap previo de 10 intentos
-- provocaba que un blip de red al conectar dejase al cliente en silencio
-- permanente y el server lo baneaba por hello_window.
CreateThread(function()
    Wait(2000)
    while not session_token do
        send_hello()
        local backoff = math.min(3000 + hello_attempts * 500, 15000)
        Wait(backoff)
    end
end)


-- //[Tick loop: ping cada ~4s con token + counter incremental]\\ --
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


-- //[Cross-check loop: SecureServe debe estar arrancado]\\ --
-- Si un cheater paro el SecureServe en su cliente, este thread lo detecta
-- (los recursos son visibles entre si en GetResourceState).
--
-- Solo contamos strikes cuando el estado es "stopped" o "missing" (parada
-- real). Estados transitorios como "starting" o "stopping" pueden ocurrir
-- durante un restart en caliente del recurso y no deben provocar ban falso.
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
        -- Estados intermedios (starting, stopping) no incrementan ni
        -- resetean: simplemente esperamos a que se estabilice.
    end
end)


-- //[Backwards compat con heartbeat existente]\\ --
-- El SecureServe ya espera estos eventos para marcar el inicio del check
-- de alive. Mantenerlos para no romper nada.
AddEventHandler("playerSpawned", function()
    TriggerServerEvent("SecureServe:Heartbeat:AllowedStop")
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent("SecureServe:Heartbeat:AllowedStop")
end)
