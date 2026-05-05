local Canary = {
    sessions       = {},
    expected_hello = {},
    grace_period   = 60,
    timeout        = 60,
    hello_window   = 240,
    check_interval = 5000,
    max_skip       = 100,
    silence_strikes = 2,
    rotation_grace = 30,
                            
    initialized    = false,
}

local ban_manager    = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")
local logger         = require("server/core/logger")

local TOKEN_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local TOKEN_LEN   = 32

local function generate_token()
    local n = #TOKEN_CHARS
    local t = {}
    for i = 1, TOKEN_LEN do
        t[i] = TOKEN_CHARS:sub(math.random(n), math.random(n))
    end
    return table.concat(t)
end

local function ban(src, reason)
    local cfg = config_manager.get_config()
    local should_ban = true
    if cfg and cfg.Module and cfg.Module.Heartbeat then
        should_ban = cfg.Module.Heartbeat.BanOnViolation ~= false
    end

    logger.warn(("Canary violation by %s (id %s): %s"):format(
        GetPlayerName(src) or "?", tostring(src), reason))

    if should_ban and ban_manager and ban_manager.ban_player then
        ban_manager.ban_player(src, "Anticheat violation: " .. reason, {
            admin     = "Anti-Cheat System",
            time      = 2147483647,
            detection = reason,
        })
    else
        DropPlayer(tostring(src), "Anticheat violation: " .. reason)
    end
end

local function open_session(src)
    local token = generate_token()
    Canary.sessions[src] = {
        token          = token,
        last_tick      = os.time(),
        counter        = 0,
        established_at = os.time(),
        silent_strikes = 0,
    }
    Canary.expected_hello[src] = nil
    return token
end

function Canary.initialize()
    if Canary.initialized then return end
    Canary.initialized = true

    math.randomseed(os.time() + math.floor((os.clock() * 1e6) % 1e9))

    AddEventHandler("playerJoining", function()
        local src = source
        if src and src > 0 then
            Canary.expected_hello[src] = os.time()
        end
    end)

    AddEventHandler("playerDropped", function()
        local src = source
        if src then
            Canary.sessions[src] = nil
            Canary.expected_hello[src] = nil
        end
    end)

    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if src then Canary.expected_hello[src] = os.time() end
    end

    RegisterNetEvent("keepalive:hello", function()
        local src = source
        if not src or src <= 0 then return end

        local token = open_session(src)
        TriggerClientEvent("keepalive:assign", src, token)
    end)

    RegisterNetEvent("keepalive:tick", function(token, counter)
        local src = source
        if not src or src <= 0 then return end

        if type(token) ~= "string" or type(counter) ~= "number" then
            ban(src, "Malformed canary tick")
            Canary.sessions[src] = nil
            return
        end

        local s = Canary.sessions[src]

        if not s then
            local new_token = open_session(src)
            TriggerClientEvent("keepalive:assign", src, new_token)
            return
        end

        local age = os.time() - s.established_at

        if s.token ~= token then
            
            if age < Canary.rotation_grace then
                TriggerClientEvent("keepalive:assign", src, s.token)
                return
            end
            ban(src, "Invalid canary token")
            Canary.sessions[src] = nil
            return
        end

        if counter <= s.counter then
            
            if age < Canary.rotation_grace then
                return
            end
            ban(src, ("Canary replay (counter %d <= %d)"):format(counter, s.counter))
            Canary.sessions[src] = nil
            return
        end

        if (counter - s.counter) > Canary.max_skip then
            
            if age < Canary.rotation_grace then
                s.counter        = counter
                s.last_tick      = os.time()
                s.silent_strikes = 0
                return
            end
            ban(src, ("Canary counter skip suspicious (jump of %d)"):format(counter - s.counter))
            Canary.sessions[src] = nil
            return
        end

        s.counter        = counter
        s.last_tick      = os.time()
        s.silent_strikes = 0
    end)

    RegisterNetEvent("keepalive:ssMissing", function()
        local src = source
        if not src or src <= 0 then return end
        ban(src, "SecureServe stopped on client side")
        Canary.sessions[src] = nil
        Canary.expected_hello[src] = nil
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Canary.check_interval)
            local now = os.time()

            for src, s in pairs(Canary.sessions) do
                if not GetPlayerName(src) then
                    Canary.sessions[src] = nil
                else
                    local since_join = now - s.established_at
                    local since_tick = now - s.last_tick

                    if since_join > Canary.grace_period and since_tick > Canary.timeout then
                        s.silent_strikes = (s.silent_strikes or 0) + 1
                        if s.silent_strikes >= Canary.silence_strikes then
                            ban(src, ("Canary silent for %ds"):format(since_tick))
                            Canary.sessions[src] = nil
                        end
                    else
                        s.silent_strikes = 0
                    end
                end
            end

            for src, joined_at in pairs(Canary.expected_hello) do
                if not GetPlayerName(src) then
                    Canary.expected_hello[src] = nil
                elseif (now - joined_at) > Canary.hello_window then
                    ban(src, "keep-alive resource never started on client")
                    Canary.expected_hello[src] = nil
                end
            end
        end
    end)

    logger.info("^5[SUCCESS] ^3Canary^7 system initialized")
end

return Canary
