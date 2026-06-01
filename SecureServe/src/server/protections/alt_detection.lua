-- alt_detection.lua
--
-- Deteccion de multicuenta / alts.
--
-- FILOSOFIA: NO banea. Solo MARCA y AVISA al staff cuando varias cuentas
-- comparten el mismo HWID/token o IP. Detectar HWID compartido es un hecho
-- objetivo, no una inferencia de comportamiento, asi que no puede castigar a un
-- inocente: la decision (ban evasion, hermanos en casa, cibercafe...) la toma
-- el staff. Ninguna accion punitiva es automatica.

local AltDetection = {}

local logger        = require("server/core/logger")
local DiscordLogger -- lazy

-- token/hwid -> { [identifier] = playerName }
local hwid_map = {}
-- ip -> { [identifier] = playerName }
local ip_map   = {}

-- Para no spamear el mismo aviso repetidamente.
local notified = {}

local function get_identifier(src)
    -- license como identidad estable principal
    local n = GetNumPlayerIdentifiers(src) or 0
    for i = 0, n - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find("^license:") then return id end
    end
    return "src:" .. tostring(src)
end

local function notify(kind, sharedValue, accounts)
    DiscordLogger = DiscordLogger or require("server/core/discord_logger")

    local list = {}
    for ident, name in pairs(accounts) do
        list[#list + 1] = ("%s (%s)"):format(tostring(name), tostring(ident))
    end

    local msg = ("Multiple accounts share the same %s `%s`:\n%s"):format(
        kind, tostring(sharedValue), table.concat(list, "\n"))

    logger.warn(("Alt detection: %d accounts share %s %s"):format(#list, kind, tostring(sharedValue)))

    if DiscordLogger and type(DiscordLogger.log_system) == "function" then
        pcall(DiscordLogger.log_system, "Possible Alt Accounts Detected", msg, { color = 16776960 })
    end
end

function AltDetection.check(src)
    if not src or src <= 0 then return end

    local cfg = SecureServe and SecureServe.AltDetection
    if cfg and cfg.Enabled == false then return end

    local ident = get_identifier(src)
    local name  = GetPlayerName(src) or "unknown"

    -- HWID / tokens.
    if GetNumPlayerTokens then
        local tn = GetNumPlayerTokens(src) or 0
        for i = 0, tn - 1 do
            local token = GetPlayerToken(src, i)
            if token and token ~= "" then
                hwid_map[token] = hwid_map[token] or {}
                hwid_map[token][ident] = name

                local count = 0
                for _ in pairs(hwid_map[token]) do count = count + 1 end
                if count >= 2 then
                    local key = "hwid:" .. token
                    if not notified[key] or (os.time() - notified[key]) > 3600 then
                        notified[key] = os.time()
                        notify("HWID token", token:sub(1, 16) .. "...", hwid_map[token])
                    end
                end
            end
        end
    end

    -- IP / endpoint.
    if GetPlayerEndpoint then
        local ep = GetPlayerEndpoint(src)
        if ep then
            local ip = tostring(ep):match("^(%d+%.%d+%.%d+%.%d+)") or tostring(ep)
            ip_map[ip] = ip_map[ip] or {}
            ip_map[ip][ident] = name

            local count = 0
            for _ in pairs(ip_map[ip]) do count = count + 1 end
            -- Umbral mas alto para IP: hermanos/wifi compartida es comun.
            local ip_threshold = (cfg and cfg.IpThreshold) or 3
            if count >= ip_threshold then
                local key = "ip:" .. ip
                if not notified[key] or (os.time() - notified[key]) > 3600 then
                    notified[key] = os.time()
                    notify("IP", ip, ip_map[ip])
                end
            end
        end
    end
end

function AltDetection.initialize()
    local cfg = SecureServe and SecureServe.AltDetection
    if cfg and cfg.Enabled == false then
        logger.info("Alt Detection is OFF.")
        return
    end

    AddEventHandler("playerJoining", function()
        local src = source
        if src then
            -- pequeno delay para que identifiers/tokens esten disponibles
            Citizen.SetTimeout(2000, function()
                if GetPlayerName(src) then
                    pcall(AltDetection.check, src)
                end
            end)
        end
    end)

    logger.info("Alt Detection initialized (notify-only, no bans).")
end

---@param identifier string license u otro identificador
---@return table accounts cuentas que comparten HWID/IP con este identificador
function AltDetection.get_linked_accounts(identifier)
    local linked = {}
    for _, accounts in pairs(hwid_map) do
        if accounts[identifier] then
            for ident, name in pairs(accounts) do linked[ident] = name end
        end
    end
    for _, accounts in pairs(ip_map) do
        if accounts[identifier] then
            for ident, name in pairs(accounts) do linked[ident] = name end
        end
    end
    linked[identifier] = nil
    return linked
end

return AltDetection
