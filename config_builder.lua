-- config_builder.lua

SecureServe = {}
SecureServe.Setup = {}
SecureServe.Webhooks = {}
SecureServe.Protection = {}
SecureServe.Protection.DetectUnknownEvents = Config.DetectUnknownEvents == true

SecureServe.ServerName       = Config.ServerName
SecureServe.DiscordLink      = Config.DiscordInvite
SecureServe.AppealURL        = Config.AppealURL
SecureServe.RequireSteam     = Config.RequireSteam
SecureServe.IdentifierCheck  = Config.IdentifierCheck
SecureServe.Debug            = Config.Debug
SecureServe.MinimumOnlineSecondsBeforeBan = Config.MinimumOnlineSecondsBeforeBan

SecureServe.AdminMenu = {
    Webhook   = Config.Webhooks.Admin or "",
    Licenses  = Config.AdminLicenses or {},
    AutoRefresh = Config.AdminMenuRefresh or { players = 5000, bans = 15000, stats = 10000 },
}

SecureServe.Admins = Config.Admins or {}

SecureServe.BanTimes = Config.BanTimes

SecureServe.Detections = {
    Webhook = Config.Webhooks.Detection or "",
    ClientProtections = {},
}

for name, enabled in pairs(Config.Protections) do
    local entry = {
        enabled = enabled,
        action  = Config.EnforcementActions[name] or "Ban",
    }
    local tuning = Config.Tunings[name]
    if tuning then
        for k, v in pairs(tuning) do entry[k] = v end
    end
    SecureServe.Detections.ClientProtections[name] = entry
end

SecureServe.Module = {
    ModuleEnabled = Config.EntityModule and Config.EntityModule.Enabled or false,
    Events = {
        Whitelist = Config.WhitelistEvents or {},
    },
    Entity = Config.EntityModule and {
        LockdownMode      = Config.EntityModule.LockdownMode or "inactive",
        TakeScreenshot    = Config.EntityModule.TakeScreenshot,
        SecurityWhitelist = Config.EntityModule.SecurityWhitelist or {},
        Limits            = Config.EntityModule.Limits or { Vehicles = 10, Peds = 12, Objects = 20, Entities = 40 },
    } or {
        LockdownMode = "inactive",
        SecurityWhitelist = {},
        Limits = { Vehicles = 10, Peds = 12, Objects = 20, Entities = 40 },
    },
    Heartbeat = Config.Heartbeat or {},
}

do
    local function build_lookup(list)
        local out = {}
        if type(list) == "table" then
            for _, v in ipairs(list) do
                if type(v) == "string" and v ~= "" then
                    out[GetHashKey(v)] = true
                elseif type(v) == "number" then
                    local h = v
                    if h < 0 then h = h + 4294967296 end
                    out[h] = true
                    out[v] = true
                end
            end
        end
        return out
    end

    local sw = (Config.EntityModule and Config.EntityModule.SpamWhitelist) or {}
    SecureServe.Module.Entity.SpamWhitelist = {
        Objects  = build_lookup(sw.Objects),
        Peds     = build_lookup(sw.Peds),
        Vehicles = build_lookup(sw.Vehicles),
    }
end

SecureServe.SafeEvents     = Config.WhitelistEvents or {}
SecureServe.SafeResources  = Config.SafeResources or {}

local function resolve_webhook(convar_name, override_key, config_value)
    local v = GetConvar(convar_name, "")
    if type(v) == "string" and v ~= "" then return v end
    return config_value or ""
end

SecureServe.Logs = {
    Enabled    = Config.Webhooks.Enabled ~= false,
    system     = resolve_webhook("secureserve_webhook_system",     "System",     Config.Webhooks.System),
    detection  = resolve_webhook("secureserve_webhook_detection",  "Detection",  Config.Webhooks.Detection),
    ban        = resolve_webhook("secureserve_webhook_ban",        "Ban",        Config.Webhooks.Ban),
    kick       = resolve_webhook("secureserve_webhook_kick",       "Kick",       Config.Webhooks.Kick),
    screenshot = resolve_webhook("secureserve_webhook_screenshot", "Screenshot", Config.Webhooks.Screenshot),
    admin      = resolve_webhook("secureserve_webhook_admin",      "Admin",      Config.Webhooks.Admin),
    debug      = resolve_webhook("secureserve_webhook_debug",      "Debug",      Config.Webhooks.Debug),
    join       = resolve_webhook("secureserve_webhook_join",       "Join",       Config.Webhooks.Join),
    leave      = resolve_webhook("secureserve_webhook_leave",      "Leave",      Config.Webhooks.Leave),
    kill       = resolve_webhook("secureserve_webhook_kill",       "Kill",       Config.Webhooks.Kill),
    resource   = resolve_webhook("secureserve_webhook_resource",   "Resource",   Config.Webhooks.Resource),
}

SecureServe.Detections.Webhook = SecureServe.Logs.detection or ""

SecureServe.Webhooks.Simple                = resolve_webhook("secureserve_webhook_simple",                "Simple",                Config.Webhooks.Simple)                ~= "" and resolve_webhook("secureserve_webhook_simple",                "Simple",                Config.Webhooks.Simple)                or SecureServe.Logs.detection
SecureServe.Webhooks.BlacklistedExplosions = resolve_webhook("secureserve_webhook_blacklisted_explosions", "BlacklistedExplosions", Config.Webhooks.BlacklistedExplosions)
SecureServe.Webhooks.BlacklistedCommands   = resolve_webhook("secureserve_webhook_blacklisted_commands",   "BlacklistedCommands",   Config.Webhooks.BlacklistedCommands)
SecureServe.Webhooks.BlacklistedSprites    = resolve_webhook("secureserve_webhook_blacklisted_sprites",    "BlacklistedSprites",    Config.Webhooks.BlacklistedSprites)
SecureServe.Webhooks.BlacklistedAnimDicts  = resolve_webhook("secureserve_webhook_blacklisted_animdicts",  "BlacklistedAnimDicts",  Config.Webhooks.BlacklistedAnimDicts)
SecureServe.Webhooks.BlacklistedWeapons    = resolve_webhook("secureserve_webhook_blacklisted_weapons",    "BlacklistedWeapons",    Config.Webhooks.BlacklistedWeapons)
SecureServe.Webhooks.BlacklistedVehicles   = resolve_webhook("secureserve_webhook_blacklisted_vehicles",   "BlacklistedVehicles",   Config.Webhooks.BlacklistedVehicles)
SecureServe.Webhooks.BlacklistedObjects    = resolve_webhook("secureserve_webhook_blacklisted_objects",    "BlacklistedObjects",    Config.Webhooks.BlacklistedObjects)
SecureServe.Webhooks.BlacklistedPeds       = resolve_webhook("secureserve_webhook_blacklisted_peds",       "BlacklistedPeds",       Config.Webhooks.BlacklistedPeds)

local function build_blacklist_simple(list, default_action)
    local out = {}
    for _, value in ipairs(list or {}) do
        if type(value) == "string" then
            out[#out + 1] = { name = value, time = default_action, webhook = "" }
        elseif type(value) == "table" then
            value.time = value.time or default_action
            value.webhook = value.webhook or ""
            out[#out + 1] = value
        end
    end
    return out
end

SecureServe.Protection.BlacklistedCommands  = (function()
    local out = {}
    for _, cmd in ipairs(Config.BlacklistedCommands or {}) do
        out[#out + 1] = { command = cmd, time = "Ban", webhook = "" }
    end
    return out
end)()

SecureServe.Protection.BlacklistedSprites = (function()
    local out = {}
    for _, entry in ipairs(Config.BlacklistedSprites or {}) do
        entry.time = entry.time or "Ban"
        entry.webhook = entry.webhook or ""
        out[#out + 1] = entry
    end
    return out
end)()

SecureServe.Protection.BlacklistedAnimDicts = (function()
    local out = {}
    for _, dict in ipairs(Config.BlacklistedAnimDicts or {}) do
        out[#out + 1] = { dict = dict, time = "Ban", webhook = "" }
    end
    return out
end)()

SecureServe.Protection.BlacklistedWeapons   = build_blacklist_simple(Config.BlacklistedWeapons,   "Ban")
SecureServe.Protection.BlacklistedVehicles  = build_blacklist_simple(Config.BlacklistedVehicles,  "Ban")
SecureServe.Protection.BlacklistedObjects   = build_blacklist_simple(Config.BlacklistedObjects,   "Ban")

SecureServe.Protection.BlacklistedPeds = (function()
    local out = {}
    for _, name in ipairs(Config.BlacklistedPeds or {}) do
        out[#out + 1] = { name = name, hash = GetHashKey(name) }
    end
    return out
end)()

SecureServe.Protection.BlacklistedExplosions = (function()
    local out = {}
    for _, e in ipairs(Config.BlacklistedExplosions or {}) do
        out[#out + 1] = {
            id        = e.id,
            limit     = e.limit or 1,
            audio     = e.audio,
            invisible = e.invisible,
            scale     = e.scale or 1.0,
            time      = e.time or "Ban",
            webhook   = "",
        }
    end
    return out
end)()

SecureServe.Protection.CancelOtherExplosions = Config.CancelOtherExplosions == true

SecureServe.WeaponDamages = Config.WeaponDamages or {}

SecureServe.OCR = { ScreenshotInterval = (Config.OCR and Config.OCR.ScreenshotInterval) or 8500 }
for _, word in ipairs((Config.OCR and Config.OCR.Words) or {}) do
    SecureServe.OCR[#SecureServe.OCR + 1] = word
end

SecureServe.BlockedMenus         = Config.BlockedMenus         or {}
SecureServe.BlacklistedExecutors = Config.BlacklistedExecutors or {}

SecureServe.ServerSecurity = Config.ServerSecurity or { Enabled = false }
SecureServe.AntiResourceInjection = Config.AntiResourceInjection or { Mode = "warn" }
SecureServe.ShadowMode = Config.ShadowMode == true
SecureServe.ShadowModeOverrides = Config.ShadowModeOverrides or {}
SecureServe.AltDetection = Config.AltDetection or { Enabled = true, IpThreshold = 3 }

SecureServe.Protection.Simple = {}
for name, settings in pairs(SecureServe.Detections.ClientProtections) do
    SecureServe.Protection.Simple[#SecureServe.Protection.Simple + 1] = {
        protection         = name,
        enabled            = settings.enabled,
        time               = settings.action,
        webhook            = "",
        limit              = settings.limit,
        default            = settings.multiplier or settings.sensitivity,
        defaultr           = settings.max_speed,
        defaults           = settings.tolerance,
        tolerance          = settings.tolerance,
        whitelisted_coords = settings.whitelisted_coords,
    }
end

local function fill_webhook_fallback(list, fallback)
    if type(list) ~= "table" or fallback == "" then return end
    for _, entry in pairs(list) do
        if type(entry) == "table" and (entry.webhook == nil or entry.webhook == "") then
            entry.webhook = fallback
        end
    end
end

fill_webhook_fallback(SecureServe.Protection.BlacklistedExplosions, SecureServe.Webhooks.BlacklistedExplosions)
fill_webhook_fallback(SecureServe.Protection.BlacklistedCommands,   SecureServe.Webhooks.BlacklistedCommands)
fill_webhook_fallback(SecureServe.Protection.BlacklistedSprites,    SecureServe.Webhooks.BlacklistedSprites)
fill_webhook_fallback(SecureServe.Protection.BlacklistedAnimDicts,  SecureServe.Webhooks.BlacklistedAnimDicts)
fill_webhook_fallback(SecureServe.Protection.BlacklistedWeapons,    SecureServe.Webhooks.BlacklistedWeapons)
fill_webhook_fallback(SecureServe.Protection.BlacklistedVehicles,   SecureServe.Webhooks.BlacklistedVehicles)
fill_webhook_fallback(SecureServe.Protection.BlacklistedObjects,    SecureServe.Webhooks.BlacklistedObjects)
fill_webhook_fallback(SecureServe.Protection.BlacklistedPeds,       SecureServe.Webhooks.BlacklistedPeds)
