Config = Config or {}

Config.ServerName = "Descartes RP"
Config.DiscordInvite = "https://discord.gg/tuinvitacion"
Config.AppealURL = "https://discord.gg/tuinvitacion"
Config.RequireSteam = false
Config.IdentifierCheck = true
Config.Debug = false
Config.MinimumOnlineSecondsBeforeBan = 55

Config.AdminLicenses = {
    "license:c796f63aba3e4421ee37548ad2b315abf245df25",
    "license:0c01fe84b46fedaefc92405655a5027459cba824",
}

Config.AdminMenuRefresh = {
    players = 5000,
    bans = 15000,
    stats = 10000,
}

Config.BanTimes = {
    ["Ban"]  = 2147483647,
    ["Kick"] = -1,
    ["Warn"] = 0,
}

Config.Protections = {

    ["Anti Noclip"]            = true,
    ["Anti Godmode"]           = true,
    ["Anti Invisible"]         = true,
    ["Anti Teleport"]          = false,
    ["Anti Speed Hack"]        = true,
    ["Anti Super Jump"]        = true,
    ["Anti No Ragdoll"]        = true,
    ["Anti Infinite Stamina"]  = true,
    ["Anti Bigger Hitbox"]     = true,

    ["Anti Give Weapon"]       = true,
    ["Anti Weapon Pickup"]     = true,
    ["Anti Damage Modifier"]   = true,
    ["Anti No Recoil"]         = true,
    ["Anti No Reload"]         = true,
    ["Anti Explosion Bullet"]  = false,
    ["Anti Magic Bullet"]      = true,
    ["Anti Aim Assist"]        = false,
    ["Anti AI"]                = true,

    ["Anti Night Vision"]      = true,
    ["Anti Thermal Vision"]    = true,
    ["Anti Player Blips"]      = true,

    ["Anti Freecam"]           = true,
    ["Anti Spectate"]          = true,

    ["Anti AFK Injection"]            = true,
    ["Anti State Bag Overflow"]       = true,
    ["Anti Extended NUI Devtools"]    = true,
    ["Anti Resource Stop"]            = true,
    ["Anti Resource Starter"]         = true,
}

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
    ["Anti Damage Modifier"]   = "Ban",
    ["Anti No Recoil"]         = "Ban",
    ["Anti No Reload"]         = "Ban",
    ["Anti Explosion Bullet"]  = "Ban",
    ["Anti Magic Bullet"]      = "Ban",
    ["Anti Aim Assist"]        = "Ban",
    ["Anti AI"]                = "Ban",
    ["Anti Night Vision"]      = "Ban",
    ["Anti Thermal Vision"]    = "Ban",
    ["Anti Player Blips"]      = "Ban",
    ["Anti Freecam"]           = "Ban",
    ["Anti Spectate"]          = "Ban",
    ["Anti AFK Injection"]     = "Ban",
    ["Anti State Bag Overflow"]= "Ban",
    ["Anti Extended NUI Devtools"] = "Ban",
    ["Anti Resource Stop"]     = "Ban",
    ["Anti Resource Starter"]  = "Ban",
}

Config.Tunings = {
    ["Anti Speed Hack"]   = { max_speed = 8.0, tolerance = 4.5 },
    ["Anti Magic Bullet"] = { tolerance = 3 },
    ["Anti Damage Modifier"] = { multiplier = 1.5 },
    ["Anti AI"]           = { sensitivity = 1.5 },
    ["Anti Particles"]    = { limit = 5 },
}

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

Config.Heartbeat = {
    Enabled = true,
    BanOnViolation = true,
    CheckInterval = 3000,
    HeartbeatCheckInterval = 5000,
    MaxFailures = 7,
    TimeoutThreshold = 30,
    GracePeriod = 30,
    SilenceStrikes = 2,
}

Config.EntityModule = {
    Enabled = false,
    LockdownMode = "inactive",
    TakeScreenshot = true,

    SecurityWhitelist = {
        
    },

    Limits = {
        Vehicles = 10,
        Peds = 12,
        Objects = 20,
        Entities = 40,
    },
}

Config.WhitelistEvents = {
    "playerJoining",
    "esx:playerLoaded",
    "esx:playerDropped",
    "codem-garage:stored",
    "codem-garage:openGarage",
    "codem-garage:storeVehicle",

}

Config.SafeResources = {
    "bob74_ipl",
    "ox_inventory",
    "codem-garaje",
}

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

Config.BlacklistedCommands = {
    "jd", "KP", "opk", "ham", "lol", "hoax", "vibes", "haha", "panik", "brutan",
    "panic", "hyra", "hydro", "lynx", "tiago", "desudo", "ssssss", "redstonia",
    "dopamine", "dopamina", "purgemenu", "WarMenu", "lynx9_fixed", "injected",
    "hammafia", "hamhaxia", "chocolate", "Information", "Maestro", "FunCtionOk",
    "TiagoModz", "jolmany", "SovietH4X", "killmenu", "panickey", "d0pamine",
    "[dopamine]", "brutanpremium", "www.d0pamine.xyz",
    "d0pamine v1.1 by Nertigel", "TiagoModz#1478",
}

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

Config.BlacklistedAnimDicts = {
    "rcmjosh2",
    "rcmpaparazzo_2",
}

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

Config.BlacklistedPeds = {
    "s_m_y_swat_01",
    "s_m_y_hwaycop_01",
    "s_m_m_movalien_01",
}

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

Config.BlacklistedExplosions = {
    { id = 0,  limit = 1, audio = true, invisible = false },
    { id = 1,  limit = 1, audio = true, invisible = false },
    { id = 2,  limit = 1, audio = true, invisible = false },
    { id = 3,  limit = 1, audio = true, invisible = false },
    { id = 4,  limit = 1, audio = true, invisible = false },
    { id = 5,  limit = 1, audio = true, invisible = false },
    { id = 6,  limit = 4, audio = true, invisible = false },
    { id = 7,  limit = 5, audio = true, invisible = false },
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

Config.OCR = {
    ScreenshotInterval = 8500,
    Words = {
        "FlexSkazaMenu", "SidMenu", "Lynx8", "LynxEvo", "Maestro Menu",
        "redEngine", "HamMafia", "tzx", "HamHaxia", "Dopameme", "redMENU",
        "Desudo", "explode", "gamesense", "Anticheat", "Tapatio",
        "Malossi", "RedStonia", "Chocohax", "susano",
        "skin changer", "torque multiple", "override player speed",
        "colision proof", "explosion proof", "copy outfit",
        "play single particle", "infinite ammo", "rip server",
        "remove ammo", "remove all weapons",
        "Convert Vehicle Into Ramps", "injected at",
        "Explode Players", "Ram Players", "Force Third Person",
        "fallout", "godmode", "ANTI-CHEAT", "god mode", "modmenu",
        "esx money", "give armor", "aimbot", "trigger",
    },
}

Config.Webhooks = {
    Enabled    = true,

    System     = "https://discord.com/api/webhooks/1497863529062203534/rtqiciHwp2cqqpkU-lAEYs8F---wqteN7LeI8P6xrOEWh67UYfk-8J3AKEqj4GYLCp8l",
    Detection  = "https://discord.com/api/webhooks/1497863597995331626/dDYlOtc-6cpwW7ysxY5T0GZX3rXBLwe81ZI-Tjf2SMOSkYltmeYKWO1EnGEo6ndaRtzp",
    Ban        = "https://discord.com/api/webhooks/1497864020013879376/EYJJbve643WgP1C_mFcNAcZwsIvQ1WjQDd0WbS27B35fr9TQcuO5407sj3LM6UsprbAu",
    Kick       = "https://discord.com/api/webhooks/1497863975587545170/ux3WEu6T8ggXot3FcLeQnXo6GGXOxXwNS6To4Vc5CbJNcgZGeiLY3SjrzyhWS5YnODZ9",
    Screenshot = "https://discord.com/api/webhooks/1497863933720133734/5ndGJ1QT6qGVmwR31yKun8npZviksp3KXd84TLRJwL94eNMlg-HtcsTJuXmQwpbudRuW",
    Admin      = "https://discord.com/api/webhooks/1497863664651468944/eSNZhVt0LEGjyku94IQkXVYpHF6oQzVKBE8Y4Hj0sPflwVla4APXFw50MFpiFY0DuNKZ",
    Debug      = "",

    Join       = "https://discord.com/api/webhooks/1497863781618024519/i2JqX3mbb962oyE1wW89cdswdHclbu-tf0K-poYcvqmO88FA-NLoKuriG6QQHybULUWz",
    Leave      = "https://discord.com/api/webhooks/1497863838199185692/NsG2NhQSb3IpfuLIA8qHFNWkZsjSY4cVs7klvOOWIDdCaOSs_nNVD04VPA3RPl4dwJIT",
    Kill       = "https://discord.com/api/webhooks/1497863737351082194/7ReKYe74l6MoqnVJBF0AR6sTrWxfbTLQICQlaFK_wn5qvzXYnu7WRnzfmq9Xndx49tqI",
    Resource   = "",

    Simple                = "",
    BlacklistedExplosions = "",
    BlacklistedCommands   = "",
    BlacklistedSprites    = "",
    BlacklistedAnimDicts  = "",
    BlacklistedWeapons    = "",
    BlacklistedVehicles   = "",
    BlacklistedObjects    = "",
    BlacklistedPeds       = "",
}

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

Config.KnownWeapons = {
    [GetHashKey("WEAPON_FLASHLIGHT")]          = "WEAPON_FLASHLIGHT",
    [GetHashKey("WEAPON_KNIFE")]               = "WEAPON_KNIFE",
    [GetHashKey("WEAPON_MACHETE")]             = "WEAPON_MACHETE",
    [GetHashKey("WEAPON_NIGHTSTICK")]          = "WEAPON_NIGHTSTICK",
    [GetHashKey("WEAPON_HAMMER")]              = "WEAPON_HAMMER",
    [GetHashKey("WEAPON_BAT")]                 = "WEAPON_BAT",
    [GetHashKey("WEAPON_GOLFCLUB")]            = "WEAPON_GOLFCLUB",
    [GetHashKey("WEAPON_CROWBAR")]             = "WEAPON_CROWBAR",
    [GetHashKey("WEAPON_BOTTLE")]              = "WEAPON_BOTTLE",
    [GetHashKey("WEAPON_HATCHET")]             = "WEAPON_HATCHET",
    [GetHashKey("WEAPON_DAGGER")]              = "WEAPON_DAGGER",
    [GetHashKey("WEAPON_WRENCH")]              = "WEAPON_WRENCH",
    [GetHashKey("WEAPON_PISTOL")]              = "WEAPON_PISTOL",
    [GetHashKey("WEAPON_PISTOL_MK2")]          = "WEAPON_PISTOL_MK2",
    [GetHashKey("WEAPON_COMBATPISTOL")]        = "WEAPON_COMBATPISTOL",
    [GetHashKey("WEAPON_APPISTOL")]            = "WEAPON_APPISTOL",
    [GetHashKey("WEAPON_PISTOL50")]            = "WEAPON_PISTOL50",
    [GetHashKey("WEAPON_SNSPISTOL")]           = "WEAPON_SNSPISTOL",
    [GetHashKey("WEAPON_HEAVYPISTOL")]         = "WEAPON_HEAVYPISTOL",
    [GetHashKey("WEAPON_STUNGUN")]             = "WEAPON_STUNGUN",
    [GetHashKey("WEAPON_MICROSMG")]            = "WEAPON_MICROSMG",
    [GetHashKey("WEAPON_SMG")]                 = "WEAPON_SMG",
    [GetHashKey("WEAPON_MACHINEPISTOL")]       = "WEAPON_MACHINEPISTOL",
    [GetHashKey("WEAPON_COMBATPDW")]           = "WEAPON_COMBATPDW",
    [GetHashKey("WEAPON_PUMPSHOTGUN")]         = "WEAPON_PUMPSHOTGUN",
    [GetHashKey("WEAPON_SAWNOFFSHOTGUN")]      = "WEAPON_SAWNOFFSHOTGUN",
    [GetHashKey("WEAPON_ASSAULTRIFLE")]        = "WEAPON_ASSAULTRIFLE",
    [GetHashKey("WEAPON_CARBINERIFLE")]        = "WEAPON_CARBINERIFLE",
    [GetHashKey("WEAPON_ADVANCEDRIFLE")]       = "WEAPON_ADVANCEDRIFLE",
    [GetHashKey("WEAPON_SPECIALCARBINE")]      = "WEAPON_SPECIALCARBINE",
    [GetHashKey("WEAPON_BULLPUPRIFLE")]        = "WEAPON_BULLPUPRIFLE",
    [GetHashKey("WEAPON_SNIPERRIFLE")]         = "WEAPON_SNIPERRIFLE",
    [GetHashKey("WEAPON_HEAVYSNIPER")]         = "WEAPON_HEAVYSNIPER",
    [GetHashKey("WEAPON_GRENADELAUNCHER")]     = "WEAPON_GRENADELAUNCHER",
    [GetHashKey("WEAPON_MINIGUN")]             = "WEAPON_MINIGUN",
    [GetHashKey("WEAPON_GRENADE")]             = "WEAPON_GRENADE",
    [GetHashKey("WEAPON_STICKYBOMB")]          = "WEAPON_STICKYBOMB",
    [GetHashKey("WEAPON_MOLOTOV")]             = "WEAPON_MOLOTOV",
    [GetHashKey("WEAPON_FIREWORK")]            = "WEAPON_FIREWORK",
    [GetHashKey("WEAPON_RAILGUN")]             = "WEAPON_RAILGUN",
    [GetHashKey("WEAPON_RPG")]                 = "WEAPON_RPG",
    [GetHashKey("WEAPON_DOUBLEACTION")]        = "WEAPON_DOUBLEACTION",
    [GetHashKey("WEAPON_REVOLVER")]            = "WEAPON_REVOLVER",
    [GetHashKey("WEAPON_REVOLVER_MK2")]        = "WEAPON_REVOLVER_MK2",
    [GetHashKey("WEAPON_NAVYREVOLVER")]        = "WEAPON_NAVYREVOLVER",
}

SecureServe = {}
SecureServe.Setup = {}
SecureServe.Webhooks = {}
SecureServe.Protection = {}

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

SecureServe.SafeEvents     = Config.WhitelistEvents or {}
SecureServe.SafeResources  = Config.SafeResources or {}

SecureServe.Logs = {
    Enabled    = Config.Webhooks.Enabled ~= false,
    system     = Config.Webhooks.System     or "",
    detection  = Config.Webhooks.Detection  or "",
    ban        = Config.Webhooks.Ban        or "",
    kick       = Config.Webhooks.Kick       or "",
    screenshot = Config.Webhooks.Screenshot or "",
    admin      = Config.Webhooks.Admin      or "",
    debug      = Config.Webhooks.Debug      or "",
    join       = Config.Webhooks.Join       or "",
    leave      = Config.Webhooks.Leave      or "",
    kill       = Config.Webhooks.Kill       or "",
    resource   = Config.Webhooks.Resource   or "",
}

SecureServe.Webhooks.Simple                = Config.Webhooks.Simple                or Config.Webhooks.Detection or ""
SecureServe.Webhooks.BlacklistedExplosions = Config.Webhooks.BlacklistedExplosions or ""
SecureServe.Webhooks.BlacklistedCommands   = Config.Webhooks.BlacklistedCommands   or ""
SecureServe.Webhooks.BlacklistedSprites    = Config.Webhooks.BlacklistedSprites    or ""
SecureServe.Webhooks.BlacklistedAnimDicts  = Config.Webhooks.BlacklistedAnimDicts  or ""
SecureServe.Webhooks.BlacklistedWeapons    = Config.Webhooks.BlacklistedWeapons    or ""
SecureServe.Webhooks.BlacklistedVehicles   = Config.Webhooks.BlacklistedVehicles   or ""
SecureServe.Webhooks.BlacklistedObjects    = Config.Webhooks.BlacklistedObjects    or ""
SecureServe.Webhooks.BlacklistedPeds       = Config.Webhooks.BlacklistedPeds       or ""

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

SecureServe.Weapons = Config.KnownWeapons or {}
SecureServe.WeaponDamages = Config.WeaponDamages or {}

SecureServe.OCR = { ScreenshotInterval = (Config.OCR and Config.OCR.ScreenshotInterval) or 8500 }
for _, word in ipairs((Config.OCR and Config.OCR.Words) or {}) do
    SecureServe.OCR[#SecureServe.OCR + 1] = word
end

SecureServe.BlockedMenus         = Config.BlockedMenus         or {}
SecureServe.BlacklistedExecutors = Config.BlacklistedExecutors or {}

SecureServe.ServerSecurity = Config.ServerSecurity or { Enabled = false }

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
