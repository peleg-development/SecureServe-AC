-- Anti Resource Injection
--
-- Mantiene una lista de recursos "conocidos" del servidor. Detecta cuando
-- aparece uno nuevo en runtime que NO esta en la lista del operador.
--
-- Modos (controlados por config):
--
--   Config.AntiResourceInjection = {
--       Mode = "warn" | "strict" | "off",
--       --   warn:   loguea aviso por cada resource desconocido (default).
--       --   strict: loguea aviso + manda al webhook system. NO baneamos al
--       --           jugador; los recursos los carga el server, no el cliente.
--       --   off:    desactivado (no inicializa).
--       KnownResources = { "essential", "es_extended", "..." },
--           -- Lista canonica de recursos legitimos del server. Si tu config
--           -- no incluye este array, hacemos snapshot del arranque (modo
--           -- legacy, equivalente al comportamiento antiguo).
--   }
--
-- Si en config no se define este bloque, conservamos el comportamiento
-- legacy (snapshot del arranque) por compatibilidad.

local AntiResourceInjection = {
    whitelisted_server_resources = {},
    mode = "warn",
    strict_known_only = false,
}

local logger = require("server/core/logger")
local DiscordLogger -- lazy

local function notify(resource_name)
    if AntiResourceInjection.mode == "off" then return end

    logger.warn(("Anti Resource Injection: unknown resource started '%s'"):format(tostring(resource_name)))

    if AntiResourceInjection.mode == "strict" then
        DiscordLogger = DiscordLogger or require("server/core/discord_logger")
        if DiscordLogger and type(DiscordLogger.log_system) == "function" then
            local ok, err = pcall(DiscordLogger.log_system,
                "Resource Injection Alert",
                ("Unknown resource started at runtime: `%s`. Verify it is legitimate."):format(tostring(resource_name)),
                { color = 16753920 })
            if not ok then logger.debug("DiscordLogger.log_system failed: " .. tostring(err)) end
        end
    end
end

function AntiResourceInjection.initialize()
    local cfg = SecureServe and SecureServe.AntiResourceInjection
        or (Config and Config.AntiResourceInjection)
        or nil

    if cfg and type(cfg) == "table" then
        AntiResourceInjection.mode = (cfg.Mode == "strict" or cfg.Mode == "off") and cfg.Mode or "warn"
    end

    if AntiResourceInjection.mode == "off" then
        logger.info("Anti Resource Injection is OFF.")
        return
    end

    -- Si el usuario define KnownResources, usamos esa lista (mas seguro:
    -- maliciosos ya presentes en el arranque saltaran el aviso). Si no,
    -- caemos al snapshot legacy.
    if cfg and type(cfg.KnownResources) == "table" and #cfg.KnownResources > 0 then
        AntiResourceInjection.strict_known_only = true
        for _, name in ipairs(cfg.KnownResources) do
            if type(name) == "string" and name ~= "" then
                AntiResourceInjection.whitelisted_server_resources[name] = true
            end
        end
        -- Anadimos siempre el propio AC.
        AntiResourceInjection.whitelisted_server_resources[GetCurrentResourceName()] = true

        -- Comparamos contra lo cargado: cualquier resource cargado y NO
        -- declarado deberia saltar como aviso al admin.
        local n = GetNumResources()
        for i = 0, n - 1 do
            local name = GetResourceByFindIndex(i)
            if name and not AntiResourceInjection.whitelisted_server_resources[name] then
                notify(name)
            end
        end

        logger.info(("Anti Resource Injection (strict) initialized: %d known resources declared in config."):format(
            (function() local k=0; for _ in pairs(AntiResourceInjection.whitelisted_server_resources) do k=k+1 end; return k end)()
        ))
    else
        -- Legacy: snapshot del arranque.
        local n = GetNumResources()
        for i = 0, n - 1 do
            local name = GetResourceByFindIndex(i)
            if name then
                AntiResourceInjection.whitelisted_server_resources[name] = true
            end
        end
        logger.info(("Anti Resource Injection (legacy snapshot) initialized with %d resources. Consider defining Config.AntiResourceInjection.KnownResources for a more secure setup."):format(n))
    end

    AddEventHandler("onResourceStart", function(resourceName)
        if not resourceName then return end
        if AntiResourceInjection.whitelisted_server_resources[resourceName] then
            return
        end
        if AntiResourceInjection.strict_known_only then
            -- En modo estricto NO auto-whitelisteamos. Avisamos al admin.
            notify(resourceName)
        else
            -- Modo legacy: para no romper flujos, agregamos pero avisamos.
            AntiResourceInjection.whitelisted_server_resources[resourceName] = true
            logger.debug("Resource added to runtime whitelist (legacy): " .. resourceName)
        end
    end)

    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName and resourceName ~= GetCurrentResourceName() then
            -- Solo en modo legacy quitamos del whitelist al parar; en estricto
            -- la lista de KnownResources del operador es la verdad y no se toca.
            if not AntiResourceInjection.strict_known_only then
                AntiResourceInjection.whitelisted_server_resources[resourceName] = nil
            end
        end
    end)
end

function AntiResourceInjection.whitelist_resource(name)
    if not name or name == "" then return false end
    AntiResourceInjection.whitelisted_server_resources[name] = true
    return true
end

function AntiResourceInjection.unwhitelist_resource(name)
    if not name or name == "" then return false end
    if not AntiResourceInjection.whitelisted_server_resources[name] then return false end
    AntiResourceInjection.whitelisted_server_resources[name] = nil
    return true
end

function AntiResourceInjection.is_resource_whitelisted(name)
    return AntiResourceInjection.whitelisted_server_resources[name] == true
end

return AntiResourceInjection
