local ban_manager    = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")
local logger         = require("server/core/logger")

local TOKEN_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local TOKEN_LEN   = 32

local Canary = {
    sessions         = {},
    expected_hello   = {},
    grace_period     = 60,
    timeout          = 60,
    hello_window     = 240,
    check_interval   = 5000,
    max_skip         = 100,
    silence_strikes  = 2,
    rotation_grace   = 30,
    initialized      = false,
    last_state_warn  = nil,
}

local function seconds()
    return os.time()
end

local function number_or(value, fallback, minimum)
    local parsed = tonumber(value)
    if not parsed then return fallback end
    parsed = math.floor(parsed)
    if minimum and parsed < minimum then return minimum end
    return parsed
end

local function load_config()
    local heartbeat = (SecureServe and SecureServe.Module and SecureServe.Module.Heartbeat) or {}
    local canary = type(heartbeat.Canary) == "table" and heartbeat.Canary or {}

    Canary.grace_period   = number_or(canary.GracePeriod or heartbeat.CanaryGracePeriod, Canary.grace_period, 10)
    Canary.timeout        = number_or(canary.Timeout or heartbeat.CanaryTimeout, Canary.timeout, 15)
    Canary.hello_window   = number_or(canary.HelloWindow or heartbeat.CanaryHelloWindow, Canary.hello_window, 30)
    Canary.check_interval = number_or(canary.CheckInterval or heartbeat.CanaryCheckInterval, Canary.check_interval, 1000)
    Canary.max_skip       = number_or(canary.MaxCounterSkip or heartbeat.CanaryMaxCounterSkip, Canary.max_skip, 10)
    Canary.silence_strikes = number_or(
        canary.SilenceStrikes or heartbeat.CanarySilenceStrikes,
        Canary.silence_strikes,
        1
    )
    Canary.rotation_grace = number_or(
        canary.RotationGrace or heartbeat.CanaryRotationGrace,
        Canary.rotation_grace,
        5
    )
end

local function generate_token()
    local token = {}
    local char_count = #TOKEN_CHARS

    for i = 1, TOKEN_LEN do
        local index = math.random(1, char_count)
        token[i] = TOKEN_CHARS:sub(index, index)
    end

    return table.concat(token)
end

local function is_valid_source(src)
    return type(src) == "number" and src > 0
end

local function is_connected(src)
    return is_valid_source(src) and GetPlayerName(src) ~= nil
end

local function keepalive_started()
    local state = GetResourceState("keep-alive")
    return state == "started", state
end

local function clear_player(src)
    Canary.sessions[src] = nil
    Canary.expected_hello[src] = nil
end

local function mark_expected_hello(src, at)
    if not is_valid_source(src) then return end

    Canary.expected_hello[src] = {
        started_at = at or seconds(),
    }
end

local function open_session(src, at)
    local now = at or seconds()
    local session = {
        token            = generate_token(),
        last_tick        = now,
        counter          = 0,
        established_at   = now,
        silent_strikes   = 0,
        replay_strikes   = 0,
        skip_strikes     = 0,
        missing_strikes  = 0,
    }

    Canary.sessions[src] = session
    Canary.expected_hello[src] = nil

    return session
end

local function assign_session(src, session)
    TriggerClientEvent("keepalive:assign", src, session.token)
end

local function can_punish_now(src, reason)
    local min_seconds = tonumber(SecureServe and SecureServe.MinimumOnlineSecondsBeforeBan) or 0
    if min_seconds <= 0 then return true end

    local joined_at = _G.SecureServe_PlayerJoinedAt and _G.SecureServe_PlayerJoinedAt[src]
    if not joined_at then return true end

    local online_seconds = seconds() - joined_at
    if online_seconds >= min_seconds then return true end

    logger.warn(("Canary punish ignored for %s; online %ds below %ds: %s")
        :format(tostring(src), online_seconds, min_seconds, tostring(reason)))
    return false
end

local function punish(src, reason)
    if not is_connected(src) or not can_punish_now(src, reason) then
        clear_player(src)
        return
    end

    local cfg = config_manager.get_config()
    local should_ban = true
    if cfg and cfg.Module and cfg.Module.Heartbeat then
        should_ban = cfg.Module.Heartbeat.BanOnViolation ~= false
    end

    logger.warn(("Canary violation by %s (id %s): %s"):format(
        GetPlayerName(src) or "?",
        tostring(src),
        reason
    ))

    if should_ban and ban_manager and type(ban_manager.ban_player) == "function" then
        ban_manager.ban_player(src, "Anticheat violation: " .. reason, {
            admin     = "Anti-Cheat System",
            time      = 2147483647,
            detection = reason,
        })
    else
        DropPlayer(tostring(src), "Anticheat violation: " .. reason)
    end

    clear_player(src)
end

local function is_valid_counter(counter)
    return type(counter) == "number"
        and counter == counter
        and counter >= 1
        and counter % 1 == 0
end

local function handle_tick(src, token, counter)
    local now = seconds()

    if type(token) ~= "string" or not is_valid_counter(counter) then
        punish(src, "Malformed canary tick")
        return
    end

    local session = Canary.sessions[src]
    if not session then
        session = open_session(src, now)
        assign_session(src, session)
        return
    end

    local session_age = now - session.established_at

    if session.token ~= token then
        if session_age <= Canary.rotation_grace then
            assign_session(src, session)
            return
        end

        punish(src, "Invalid canary token")
        return
    end

    if counter <= session.counter then
        if session_age <= Canary.rotation_grace then
            return
        end

        session.replay_strikes = (session.replay_strikes or 0) + 1
        if session.replay_strikes >= 2 then
            punish(src, ("Canary replay (counter %d <= %d)"):format(counter, session.counter))
        else
            assign_session(src, session)
        end
        return
    end

    local jump = counter - session.counter
    if jump > Canary.max_skip then
        if session_age <= Canary.rotation_grace then
            session.counter = counter
            session.last_tick = now
            session.silent_strikes = 0
            return
        end

        session.skip_strikes = (session.skip_strikes or 0) + 1
        if session.skip_strikes >= 2 then
            punish(src, ("Canary counter skip suspicious (jump of %d)"):format(jump))
        else
            session.counter = counter
            session.last_tick = now
        end
        return
    end

    session.counter = counter
    session.last_tick = now
    session.silent_strikes = 0
    session.replay_strikes = 0
    session.skip_strikes = 0
end

local function monitor_sessions(now)
    for src, session in pairs(Canary.sessions) do
        if not is_connected(src) then
            clear_player(src)
        else
            local since_join = now - session.established_at
            local since_tick = now - session.last_tick

            if since_join > Canary.grace_period and since_tick > Canary.timeout then
                session.silent_strikes = (session.silent_strikes or 0) + 1
                if session.silent_strikes >= Canary.silence_strikes then
                    punish(src, ("Canary silent for %ds"):format(since_tick))
                end
            else
                session.silent_strikes = 0
            end
        end
    end
end

local function recover_missing_hellos(now)
    for src, entry in pairs(Canary.expected_hello) do
        if not is_connected(src) then
            clear_player(src)
        elseif (now - entry.started_at) > Canary.hello_window then
            local session = open_session(src, now)
            assign_session(src, session)
            logger.warn(("Canary hello missing for %s; issued recovery token"):format(tostring(src)))
        end
    end
end

local function monitor_loop()
    while true do
        Citizen.Wait(Canary.check_interval)

        local started, state = keepalive_started()
        if not started then
            if Canary.last_state_warn ~= state then
                logger.warn(("Canary monitor paused; keep-alive resource state is %s"):format(tostring(state)))
                Canary.last_state_warn = state
            end
        else
            Canary.last_state_warn = nil
            local now = seconds()

            monitor_sessions(now)
            recover_missing_hellos(now)
        end
    end
end

function Canary.initialize()
    if Canary.initialized then return end
    Canary.initialized = true

    load_config()
    math.randomseed(seconds() + math.floor((os.clock() * 1000000) % 1000000000))

    AddEventHandler("playerJoining", function()
        mark_expected_hello(source, seconds())
    end)

    AddEventHandler("playerDropped", function()
        clear_player(source)
    end)

    AddEventHandler("onResourceStart", function(resource_name)
        if resource_name ~= "keep-alive" then return end

        local now = seconds()
        for _, player_id in ipairs(GetPlayers()) do
            local src = tonumber(player_id)
            if src and not Canary.sessions[src] then
                mark_expected_hello(src, now)
            end
        end
    end)

    AddEventHandler("onResourceStop", function(resource_name)
        if resource_name == "keep-alive" then
            Canary.last_state_warn = nil
        end
    end)

    for _, player_id in ipairs(GetPlayers()) do
        local src = tonumber(player_id)
        if src then
            mark_expected_hello(src, seconds())
        end
    end

    RegisterNetEvent("keepalive:hello", function()
        local src = source
        if not is_valid_source(src) then return end

        local session = open_session(src, seconds())
        assign_session(src, session)
    end)

    RegisterNetEvent("keepalive:tick", function(token, counter)
        local src = source
        if not is_valid_source(src) then return end

        handle_tick(src, token, counter)
    end)

    RegisterNetEvent("keepalive:ssMissing", function()
        local src = source
        if not is_valid_source(src) then return end

        local session = Canary.sessions[src] or open_session(src, seconds())
        session.missing_strikes = (session.missing_strikes or 0) + 1

        if session.missing_strikes >= 2 then
            punish(src, "SecureServe stopped on client side")
        else
            assign_session(src, session)
            logger.warn(("Canary SecureServe missing report from %s; waiting for confirmation")
                :format(tostring(src)))
        end
    end)

    Citizen.CreateThread(monitor_loop)

    logger.info("^5[SUCCESS] ^3Canary^7 system initialized")
end

return Canary
