Config = Config or {}

-- //[Main Config]\\ --
Config.ServerName = "your server"
Config.DiscordInvite = "https://discord.gg/xxxxxxx"
Config.AppealURL = "https://discord.gg/xxxxxxx"
Config.RequireSteam = false
Config.IdentifierCheck = true
Config.Debug = false
Config.DevMode = false
Config.DetectUnknownEvents = false
Config.MinimumOnlineSecondsBeforeBan = 55


-- //[Admin Menu]\\ --
Config.AdminLicenses = {
    "license:c796f63axxxxxxxxxxxxxxxxxxf25", 

}

Config.Admins = {
    { identifier = "license:xxxxxxxxxxxx", note = "ALX" },
}

Config.AdminMenuRefresh = {
    players = 5000,
    bans = 15000,
    stats = 10000,
}


-- //[Ban Times]\\ --
Config.BanTimes = {
    ["Ban"]  = 2147483647,
    ["Kick"] = -1,
    ["Warn"] = 0,
}


-- //[Protections]\\ --
Config.Protections = {

    -- //[Player]\\ --
    ["Anti Noclip"]            = true,
    ["Anti Godmode"]           = true,
    ["Anti Invisible"]         = false,
    ["Anti Teleport"]          = false,
    ["Anti Speed Hack"]        = true,
    ["Anti Super Jump"]        = true,
    ["Anti No Ragdoll"]        = false,
    ["Anti Infinite Stamina"]  = true,
    ["Anti Bigger Hitbox"]     = false,

    -- //[Combate / Armas]\\ --
    ["Anti Give Weapon"]       = true,
    ["Anti Weapon Pickup"]     = true,
    ["Anti Weapon Damage Modifier"] = true,
    ["Anti No Recoil"]         = true,
    ["Anti No Reload"]         = true,
    ["Anti Explosion Bullet"]  = false,
    ["Anti Magic Bullet"]      = true,
    ["Anti Aim Assist"]        = false,
    ["Anti AI"]                = true,

    -- //[Visuales]\\ --
    ["Anti Night Vision"]      = true,
    ["Anti Thermal Vision"]    = true,
    ["Anti Player Blips"]      = false,
    ["Anti ESP"]               = false,

    -- //[Cheats]\\ --
    ["Anti Freecam"]           = true,
    ["Anti Spectate"]          = true,

    -- //[Avanzados]\\ --
    ["Anti AFK Injection"]            = true,
    ["Anti State Bag Overflow"]       = true,
    ["Anti Input Block"]              = true,
    ["Anti Extended NUI Devtools"]    = true,
    ["Anti Resource Stop"]            = true,
    ["Anti Resource Starter"]         = true,
}


-- //[Enforcement Actions]\\ --
Config.EnforcementActions = {
    ["Anti Noclip"]            = "Ban",
    ["Anti Godmode"]           = "Ban",
    ["Anti Invisible"]         = "Ban",
    ["Anti Teleport"]          = "Ban",
    ["Anti Speed Hack"]        = "Ban",
    ["Anti Super Jump"]        = "Ban",
    ["Anti No Ragdoll"]        = "Ban",
    ["Anti Infinite Stamina"]  = "Ban",
    ["Anti Bigger Hitbox"]     = "Ban",
    ["Anti Give Weapon"]       = "Ban",
    ["Anti Weapon Pickup"]     = "Ban",
    ["Anti Weapon Damage Modifier"] = "Ban",
    ["Anti No Recoil"]         = "Ban",
    ["Anti No Reload"]         = "Ban",
    ["Anti Explosion Bullet"]  = "Ban",
    ["Anti Magic Bullet"]      = "Ban",
    ["Anti Aim Assist"]        = "Ban",
    ["Anti AI"]                = "Ban",
    ["Anti Night Vision"]      = "Ban",
    ["Anti Thermal Vision"]    = "Ban",
    ["Anti Player Blips"]      = "Ban",
    ["Anti ESP"]               = "Ban",
    ["Anti Freecam"]           = "Ban",
    ["Anti Spectate"]          = "Ban",
    ["Anti AFK Injection"]     = "Ban",
    ["Anti State Bag Overflow"]= "Ban",
    ["Anti Input Block"]       = "Ban",
    ["Anti Extended NUI Devtools"] = "Ban",
    ["Anti Resource Stop"]     = "Ban",
    ["Anti Resource Starter"]  = "Ban",
}


-- //[Tunings de detecciones]\\ --
Config.Tunings = {
    ["Anti Speed Hack"]            = { max_speed = 11.0, tolerance = 4.5 },
    ["Anti Magic Bullet"]          = { tolerance = 3 },
    ["Anti Weapon Damage Modifier"] = { multiplier = 1.5 },
    ["Anti AI"]                    = { sensitivity = 1.5 },
    ["Anti Particles"]             = { limit = 5 },
    ["Anti AFK Injection"]         = { strike_limit = 3, check_interval_ms = 5000 },
    ["Anti Bigger Hitbox"]         = { strike_limit = 3, check_interval_ms = 15000 },
    ["Anti Aim Assist"]            = { strike_limit = 4, check_interval_ms = 2500 },
    ["Anti Explosion Bullet"]      = { strike_limit = 3, check_interval_ms = 1500 },
    ["Anti Invisible"]             = { strike_limit = 8, spawn_grace_ms = 10000, damage_grace_ms = 3000, reset_ms = 60000, alpha_threshold = 50 },
}


-- //[Damage baseline por arma]\\ --
Config.WeaponDamages = {
    [GetHashKey("WEAPON_PISTOL")]        = 26,
    [GetHashKey("WEAPON_PISTOL_MK2")]    = 33,
    [GetHashKey("WEAPON_COMBATPISTOL")]  = 27,
    [GetHashKey("WEAPON_APPISTOL")]      = 34,
    [GetHashKey("WEAPON_PISTOL50")]      = 51,
    [GetHashKey("WEAPON_SNSPISTOL")]     = 25,
    [GetHashKey("WEAPON_HEAVYPISTOL")]   = 40,
    [GetHashKey("WEAPON_VINTAGEPISTOL")] = 34,
    [GetHashKey("WEAPON_MICROSMG")]      = 21,
    [GetHashKey("WEAPON_SMG")]           = 22,
    [GetHashKey("WEAPON_SMG_MK2")]       = 24,
    [GetHashKey("WEAPON_ASSAULTSMG")]    = 24,
    [GetHashKey("WEAPON_COMBATPDW")]     = 22,
    [GetHashKey("WEAPON_MACHINEPISTOL")] = 18,
    [GetHashKey("WEAPON_ASSAULTRIFLE")]  = 30,
    [GetHashKey("WEAPON_ASSAULTRIFLE_MK2")] = 34,
    [GetHashKey("WEAPON_CARBINERIFLE")]  = 33,
    [GetHashKey("WEAPON_CARBINERIFLE_MK2")] = 36,
    [GetHashKey("WEAPON_ADVANCEDRIFLE")] = 34,
    [GetHashKey("WEAPON_SPECIALCARBINE")] = 31,
    [GetHashKey("WEAPON_BULLPUPRIFLE")]  = 26,
    [GetHashKey("WEAPON_COMPACTRIFLE")]  = 30,
    [GetHashKey("WEAPON_PUMPSHOTGUN")]   = 32,
    [GetHashKey("WEAPON_SAWNOFFSHOTGUN")] = 27,
    [GetHashKey("WEAPON_ASSAULTSHOTGUN")] = 25,
    [GetHashKey("WEAPON_BULLPUPSHOTGUN")] = 14,
    [GetHashKey("WEAPON_HEAVYSHOTGUN")]  = 33,
    [GetHashKey("WEAPON_DBSHOTGUN")]     = 75,
    [GetHashKey("WEAPON_AUTOSHOTGUN")]   = 44,
    [GetHashKey("WEAPON_SNIPERRIFLE")]   = 100,
    [GetHashKey("WEAPON_HEAVYSNIPER")]   = 216,
    [GetHashKey("WEAPON_HEAVYSNIPER_MK2")] = 270,
    [GetHashKey("WEAPON_MARKSMANRIFLE")] = 50,
}


-- //[Heartbeat]\\ --
Config.Heartbeat = {
    Enabled = true,
    BanOnViolation = true,
    CheckInterval = 5000,
    HeartbeatCheckInterval = 10000,
    MaxFailures = 12,
    TimeoutThreshold = 60,
    GracePeriod = 90,
    SilenceStrikes = 4,
}


-- //[Module: Entity Security]\\ --
Config.EntityModule = {
    Enabled = false,
    LockdownMode = "inactive",      -- "relaxed", "strict" o "inactive"
    TakeScreenshot = true,

    SecurityWhitelist = {
        -- { resource = "bob74_ipl", whitelist = true },
    },

    Limits = {
        Vehicles = 10,
        Peds = 12,
        Objects = 20,
        Entities = 40,
    },

    SpamWhitelist = {
        Objects = {
            "prop_weed_01",
            "prop_plant_01b",
            "prop_plant_fern_02a",
            "prop_barrel_exp_01a",
            "prop_mp_drug_pack_blue",
        },
        Peds = {
            -- "a_c_chickenhawk",
        },
        Vehicles = {
            "asifun_boatdrug",
            "asifun_boattrailer",
            "asifun_cardrug",
        },
    },
}


-- //[Eventos en whitelist]\\ --
Config.WhitelistEvents = {
    "playerJoining",
    "esx:playerLoaded",
    "esx:playerDropped",
    "codem-garage:stored",
    "codem-garage:openGarage",
    "codem-garage:storeVehicle",
}


-- //[Recursos en whitelist]\\ --
Config.SafeResources = {
    "bob74_ipl",
    "ox_inventory",
    "codem-garaje",
    "m-vehicleshop",
}


-- //[Ejecutores y menus blacklisted]\\ --
Config.BlockedMenus = {
    "rootMenu", "rootMenuv2", "rootMenuv3", "Wugr4yfgb",
}

Config.BlacklistedExecutors = {
    "Eulen", "EulenMenu", "EulenMenu2", "EulenMenu3", "SkidMenu", "AbsoluteEulen",
    "HamMafia", "LynxRevolution", "Lynx8", "LynxSeven", "TiagoMenu", "MarketMenu",
    "KoGuSzEk", "SentioMenu", "SwagMenu", "Dopamine", "Script Hook", "ScrHook",
    "d0pa1998", "HydroMenu", "D0paMenu", "Lux", "LuxuinityMenu", "OpenMenuV",
    "xAries", "Krepozz", "CiacaDasai", "GenesisV", "Deluxe Menu", "Ruby",
    "SwagCheats", "HudMenuX", "xseira", "SkazaMenu", "WADUI", "aries", "SidMenu",
    "AlwaysKaffa", "Lynx", "Maestro Menu", "NertigelFunc", "FendinX", "Root Menu",
    "Fuckingmenu", "Falcon", "Fallout Menu", "Redengine", "Executor", "DreamMenu",
    "Executor.lua", "RottenV", "Deer Menu", "Dopameme", "dopamine", "ICMENU",
    "Qlieplayer", "MaestroMenu", "Roblox Hack", "Nano", "SKRIPT.LUA", "Macias",
    "GrubyMenu", "Wolfi", "Ham", "luminous", "Absolute", "Mockingbird",
    "FlexSkazaMenu", "Nebula", "BellaMenu", "WaveMenu",
}


-- //[Comandos blacklisted]\\ --
Config.BlacklistedCommands = {
    "jd", "KP", "opk", "ham", "lol", "hoax", "vibes", "haha", "panik", "brutan",
    "panic", "hyra", "hydro", "lynx", "tiago", "desudo", "ssssss", "redstonia",
    "dopamine", "dopamina", "purgemenu", "WarMenu", "lynx9_fixed", "injected",
    "hammafia", "hamhaxia", "chocolate", "Information", "Maestro", "FunCtionOk",
    "TiagoModz", "jolmany", "SovietH4X", "killmenu", "panickey", "d0pamine",
    "[dopamine]", "brutanpremium", "www.d0pamine.xyz",
    "d0pamine v1.1 by Nertigel", "TiagoModz#1478",
}


-- //[Sprites blacklisted]\\ --
Config.BlacklistedSprites = {
    { sprite = "deadline",           name = "Dopamine" },
    { sprite = "Dopameme",           name = "Dopamine Menu" },
    { sprite = "dopamine",           name = "Dopamine Menu" },
    { sprite = "dopamemes",          name = "Dopameme Menu" },
    { sprite = "wm2",                name = "WM Menu" },
    { sprite = "KentasCheckboxDict", name = "Kentas Menu Synapse" },
    { sprite = "KentasMenu",         name = "Kentas Menu Synapse" },
    { sprite = "HydroMenuHeader",    name = "HydroMenu" },
    { sprite = "godmenu",            name = "God Menu" },
    { sprite = "redrum",             name = "Redrum Menu" },
    { sprite = "beautiful",          name = "Beautiful Menu" },
    { sprite = "Absolut",            name = "Absolute Menu" },
    { sprite = "hoaxmenu",           name = "Hoax Menu" },
    { sprite = "fendin",             name = "Fendinx Menu" },
    { sprite = "Ham",                name = "Ham Menu" },
    { sprite = "hammafia",           name = "Ham Mafia Menu" },
    { sprite = "Fallout",            name = "Fallout" },
    { sprite = "menu_bg",            name = "Fallout Menu" },
    { sprite = "DefaultMenu",        name = "Default Menu" },
    { sprite = "ISMMENUHeader",      name = "ISMMENU" },
    { sprite = "fivesense",          name = "Fivesense Menu" },
    { sprite = "maestro",            name = "Maestro Menu" },
    { sprite = "kekhack",            name = "KekHack Menu" },
    { sprite = "trolling",           name = "Trolling Menu" },
    { sprite = "mm",                 name = "MM Menu" },
    { sprite = "MmPremium",          name = "MM Premium Menu" },
    { sprite = "dopatest",           name = "Dopa Menu" },
    { sprite = "cat",                name = "Cat Menu" },
    { sprite = "John2",              name = "SugarMenu" },
    { sprite = "bartowmenu",         name = "Bartow Menu" },
    { sprite = "duiTex",             name = "Copypaste Menu" },
    { sprite = "Mafins",             name = "Mafins Menu" },
    { sprite = "skidmenu",           name = "Skid Menu" },
    { sprite = "Urubu3",             name = "Urubu Menu" },
    { sprite = "Urubu",              name = "Urubu Menu" },
    { sprite = "love",               name = "Love Menu" },
    { sprite = "brutan",             name = "Brutan Menu" },
    { sprite = "auttaja",            name = "Auttaja Menu" },
    { sprite = "oblivious",          name = "Oblivious Menu" },
    { sprite = "malossimenu",        name = "Malossi Menu" },
    { sprite = "Memeeee",            name = "Memeeee Menu" },
    { sprite = "Tiago",              name = "Tiago Menu" },
    { sprite = "fantasy",            name = "Fantasy Menu" },
    { sprite = "Vagos",              name = "Vagos Menu" },
    { sprite = "simplicity",         name = "Simplicity Menu" },
    { sprite = "WarMenu",            name = "War Menu" },
    { sprite = "Darkside",           name = "Darkside Menu" },
    { sprite = "antario",            name = "Antario Menu" },
    { sprite = "kingpin",            name = "Kingpin Menu" },
    { sprite = "Wave (alt.)",        name = "Wave (alt.)" },
    { sprite = "Wave",               name = "Wave" },
    { sprite = "Alokas66",           name = "Alokas66" },
    { sprite = "Guest Menu",         name = "Guest Menu" },
}


-- //[Anim dicts blacklisted]\\ --
Config.BlacklistedAnimDicts = {
    "rcmjosh2",
    "rcmpaparazzo_2",
}


-- //[Armas blacklisted]\\ --
Config.BlacklistedWeapons = {
    "weapon_rayminigun",
    "weapon_raycarbine",
    "weapon_rpg",
    "weapon_grenadelauncher",
    "weapon_minigun",
    "weapon_railgun",
    "weapon_firework",
    "weapon_hominglauncher",
    "weapon_compactlauncher",
}


-- //[Vehiculos blacklisted]\\ --
Config.BlacklistedVehicles = {
    "dinghy5", "kosatka", "patrolboat",
    "cerberus", "cerberus2", "cerberus3", "phantom2",
    "akula", "annihilator", "buzzard", "savage", "annihilator2",
    "cutter", "apc", "barrage", "chernobog", "halftrack", "khanjali",
    "minitank", "rhino", "thruster", "trailersmall2",
    "oppressor", "oppressor2", "dukes2", "ruiner2",
    "dune3", "dune4", "dune5", "insurgent", "insurgent3",
    "menacer", "rcbandito", "technical", "technical2", "technical3",
    "avenger", "avenger2", "bombushka", "cargoplane", "cargoplane2",
    "hydra", "lazer", "molotok", "nokota", "pyro", "rogue",
    "starling", "strikeforce", "limo2", "scramjet", "vigilante",
}


-- //[Peds blacklisted]\\ --
Config.BlacklistedPeds = {
    "s_m_y_swat_01",
    "s_m_y_hwaycop_01",
    "s_m_m_movalien_01",
}


-- //[Objetos blacklisted]\\ --
Config.BlacklistedObjects = {
    "prop_logpile_01", "prop_logpile_02", "prop_logpile_03",
    "prop_logpile_04", "prop_logpile_05", "prop_logpile_06",
    "prop_logpile_06b", "prop_logpile_07", "prop_logpile_07b",
    "hei_prop_carrier_radar_1_l1", "v_res_mexball",
    "prop_rock_1_a", "prop_rock_1_b", "prop_rock_1_c", "prop_rock_1_d",
    "prop_rock_1_e", "prop_rock_1_f", "prop_rock_1_g", "prop_rock_1_h",
    "prop_player_gasmask",
    "prop_test_boulder_01", "prop_test_boulder_02",
    "prop_test_boulder_03", "prop_test_boulder_04",
    "apa_mp_apa_crashed_usaf_01a", "ex_prop_exec_crashdp",
    "prop_crashed_heli", "prop_shamal_crash", "xm_prop_x17_shamal_crash",
    "prop_flagpole_2b", "prop_flagpole_2c", "prop_flag_canada",
    "prop_flag_columbia", "prop_beach_fire", "prop_rock_4_big2",
    "prop_beachflag_le", "freight",
    "stt_prop_race_start_line_03b", "stt_prop_stunt_soccer_sball",
}


-- //[Explosiones blacklisted]\\ --
-- id = numero de tipo de explosion (ver lista en https://docs.fivem.net)
-- limit = cuantas se permiten antes de banear
-- audio = true para banear si la explosion es inaudible
-- invisible = true para banear si la explosion es invisible
Config.BlacklistedExplosions = {
    { id = 0,  limit = 1, audio = true, invisible = false }, -- Grenades
    { id = 1,  limit = 1, audio = true, invisible = false }, -- Sticky Bombs
    { id = 2,  limit = 1, audio = true, invisible = false }, -- Grenade Launcher
    { id = 3,  limit = 1, audio = true, invisible = false }, -- Molotov
    { id = 4,  limit = 1, audio = true, invisible = false }, -- Rockets
    { id = 5,  limit = 1, audio = true, invisible = false }, -- Tank Shells
    { id = 6,  limit = 4, audio = true, invisible = false }, -- Hi Octane
    { id = 7,  limit = 5, audio = true, invisible = false }, -- Car Explosions
    { id = 18, limit = 8, audio = true, invisible = false },
    { id = 19, limit = 8, audio = true, invisible = false },
    { id = 20, limit = 5, audio = true, invisible = false },
    { id = 21, limit = 5, audio = true, invisible = false },
    { id = 22, limit = 5, audio = true, invisible = false },
    { id = 25, limit = 1, audio = true, invisible = false },
    { id = 36, limit = 1, audio = true, invisible = false },
    { id = 37, limit = 1, audio = true, invisible = false },
    { id = 38, limit = 1, audio = true, invisible = false },
    { id = 40, limit = 1, audio = true, invisible = false },
    { id = 43, limit = 1, audio = true, invisible = false },
    { id = 44, limit = 1, audio = true, invisible = false },
    { id = 45, limit = 1, audio = true, invisible = false },
    { id = 46, limit = 1, audio = true, invisible = false },
    { id = 47, limit = 1, audio = true, invisible = false },
    { id = 48, limit = 1, audio = true, invisible = false },
    { id = 49, limit = 1, audio = true, invisible = false },
    { id = 50, limit = 1, audio = true, invisible = false },
    { id = 51, limit = 1, audio = true, invisible = false },
    { id = 52, limit = 1, audio = true, invisible = false },
    { id = 53, limit = 1, audio = true, invisible = false },
    { id = 54, limit = 1, audio = true, invisible = false },
    { id = 55, limit = 1, audio = true, invisible = false },
    { id = 56, limit = 1, audio = true, invisible = false },
    { id = 57, limit = 1, audio = true, invisible = false },
    { id = 58, limit = 1, audio = true, invisible = false },
    { id = 59, limit = 1, audio = true, invisible = false },
    { id = 60, limit = 1, audio = true, invisible = false },
    { id = 61, limit = 1, audio = true, invisible = false },
    { id = 62, limit = 1, audio = true, invisible = false },
    { id = 63, limit = 1, audio = true, invisible = false },
    { id = 64, limit = 1, audio = true, invisible = false },
    { id = 65, limit = 1, audio = true, invisible = false },
    { id = 66, limit = 1, audio = true, invisible = false },
    { id = 67, limit = 1, audio = true, invisible = false },
    { id = 68, limit = 1, audio = true, invisible = false },
    { id = 69, limit = 1, audio = true, invisible = false },
    { id = 70, limit = 1, audio = true, invisible = false },
    { id = 71, limit = 1, audio = true, invisible = false },
    { id = 72, limit = 1, audio = true, invisible = false },
    { id = 82, limit = 1, audio = true, invisible = false },
}

Config.CancelOtherExplosions = false


-- //[OCR]\\ --
Config.OCR = {
    ScreenshotInterval = 8500,
    Words = {
        "FlexSkazaMenu", "SidMenu", "Lynx8", "LynxEvo", "Maestro Menu",
        "redEngine", "HamMafia", "tzx", "HamHaxia", "Dopameme", "redMENU",
        "Desudo", "explode", "gamesense", "Tapatio",
        "Malossi", "RedStonia", "Chocohax", "susano",
        "skin changer", "torque multiple", "override player speed",
        "colision proof", "explosion proof", "copy outfit",
        "play single particle", "infinite ammo", "rip server",
        "remove ammo", "remove all weapons",
        "Convert Vehicle Into Ramps", "injected at",
        "Explode Players", "Ram Players", "Force Third Person",
        "fallout", "godmode", "god mode", "modmenu",
        "esx money", "give armor", "aimbot", "trigger",
    },
}


-- //[Discord Webhooks]\\ --
Config.Webhooks = {
    Enabled    = true,

    -- Categorias principales
    System     = "https://discord.com/api/webhooks/xxxxxxxxxx",
    Detection  = "https://discord.com/api/webhooks/xxxxxxxxxx",
    Ban        = "https://discord.com/api/webhooks/xxxxxxxxxx",
    Kick       = "https://discord.com/api/webhooks/xxxxxxxxxx",
    Screenshot = "https://discord.com/api/webhooks/xxxxxxxxxx",
    Admin      = "https://discord.com/api/webhooks/xxxxxxxxxx",
    Debug      = "https://discord.com/api/webhooks/xxxxxxxxxx",

    -- Eventos del servidor
    Join       = "https://discord.com/api/webhooks/xxxxxxxxxx",
    Leave      = "https://discord.com/api/webhooks/xxxxxxxxxx",
    Kill       = "https://discord.com/api/webhooks/xxxxxxxxxx",
    Resource   = "https://discord.com/api/webhooks/xxxxxxxxxx",

    -- Webhooks por categoria de blacklist
    Simple                = "",
    BlacklistedExplosions = "",
    BlacklistedCommands   = "",
    BlacklistedSprites    = "",
    BlacklistedAnimDicts  = "",
    BlacklistedWeapons    = "",
    BlacklistedObjects    = "",
    BlacklistedVehicles   = "",
    BlacklistedPeds       = "",
}


-- //[Anti Resource Injection]\\ --
Config.AntiResourceInjection = {
    Mode = "warn",
    KnownResources = {
        -- "essential",
        -- "es_extended",
        -- "qb-core",
        -- "ox_lib",
    },
}


-- //[Shadow Mode]\\ --
Config.ShadowMode = false
Config.ShadowModeOverrides = {
    -- ["Anti Aim Assist"]     = true,
    -- ["Anti Bigger Hitbox"]  = true,
}


-- //[Alt Detection]\\ --
Config.AltDetection = {
    Enabled = true,
    IpThreshold = 3,
}


-- //[Server Security (FiveM built-in)]\\ --
Config.ServerSecurity = {
    Enabled = false,
    Connection = {
        KickTimeout = 600,
        UpdateRate = 60,
        ConsecutiveFailures = 2,
        AuthMaxVariance = 1,
        AuthMinTrust = 5,
        VerifyClientSettings = true,
    },
    NetworkEvents = {
        StateBagStrictMode = true,
        FilterUsageEvents = true,
        EnableNetEventReassembly = true,
    },
    Resources = {
        EnforceGameBuild = true,
        OneSyncEnabled = true,
        OneSyncPopulation = true,
    },
}
