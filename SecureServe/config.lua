--[[≺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━≻--                                                                                                                                                                                                                                                   
                                                                                                  
  ____                                                 ____                                       
6MMMMb\                                              6MMMMb\                                     
6M'    `                                             6M'    `                                     
MM         ____     ____  ___   ___ ___  __   ____   MM         ____  ___  __ ____    ___  ____   
YM.       6MMMMb   6MMMMb.`MM    MM `MM 6MM  6MMMMb  YM.       6MMMMb `MM 6MM `MM(    )M' 6MMMMb  
 YMMMMb  6M'  `Mb 6M'   Mb MM    MM  MM69 " 6M'  `Mb  YMMMMb  6M'  `Mb MM69 "  `Mb    d' 6M'  `Mb 
     `Mb MM    MM MM    `' MM    MM  MM'    MM    MM      `Mb MM    MM MM'      YM.  ,P  MM    MM 
      MM MMMMMMMM MM       MM    MM  MM     MMMMMMMM       MM MMMMMMMM MM        MM  M   MMMMMMMM 
      MM MM       MM       MM    MM  MM     MM             MM MM       MM        `Mbd'   MM       
L    ,M9 YM    d9 YM.   d9 YM.   MM  MM     YM    d9 L    ,M9 YM    d9 MM         YMP    YM    d9 
MYMMMM9   YMMMM9   YMMMM9   YMMM9MM__MM_     YMMMM9  MYMMMM9   YMMMM9 _MM_         M      YMMMM9  
                                                                                                  
                                                                                                                                                                                                                                     														
≺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━≻--]]
-- DOCS: https://peleg.gitbook.io/secureserve/
-- IN DOCS U WILL FIND AN INSTALL GUIDE PLEASE ALSO READ THE COMMENTS IN THIS FILE ( commnet = -- everything after this )

-- DO NOT TOUCH THIS! THIS ISNT THE PLACE TO CHANGE WEBHOOKS! NOT HERE!
SecureServe = {}
SecureServe.Setup = {}
SecureServe.Webhooks = {}
SecureServe.Protection = {}

---@!!!!!IMPORTANT!!! ADMIN PANEL COMMAND: /ssm
SecureServe.AdminMenu = {
    Webhook = "",
    Licenses = {
        -- "license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    },
    AutoRefresh = {
        players = 5000,
        bans = 15000,
        stats = 10000
    }
}

--  ______ _______ __   _ _______  ______ _______       
-- |  ____ |______ | \  | |______ |_____/ |_____| |     
-- |_____| |______ |  \_| |______ |    \_ |     | |_____
SecureServe.ServerName = ""                                                                   -- The name of the server.
SecureServe.DiscordLink = ""                                                                  -- The link to your discord server.
SecureServe.RequireSteam = false                                                              -- Just requires players that want to join your server to have steam open and logged in as well u must have a valid steam api key for this option read more in docs
SecureServe.IdentifierCheck = true                                                            -- Checks when player connects if his identifiers are valid. if not it won't let him join the server.
SecureServe.Debug = false 																      -- Enables debug mode, this will print debug messages in the console.



-- FiveM built-in server security options to prevent cheating
-- First try enabling everything and then disable the ones that are not needed or cause issues in your server 
-- This system is Fivem Built-in and not created by SecureServe's team...
SecureServe.ServerSecurity = {
    Enabled = true, -- Master toggle for all server security settings
    
    -- CONNECTION & AUTHENTICATION SETTINGS
    Connection = {
        -- Player connection timeout settings (in seconds)
        KickTimeout = 600,              -- Time before kicking inactive players (10 minutes)
                                        -- If experiencing connection issues, increase to 1200
        
        UpdateRate = 60,                -- How often player status is checked (every 60 seconds)
                                        -- Lower values increase server load but improve security
        
        ConsecutiveFailures = 2,        -- Number of consecutive failures before kicking
                                        -- Increase to 3 if experiencing false kicks
        
        -- Identity verification settings
        AuthMaxVariance = 1,            -- Maximum allowed identity variance (1 = strict)
                                        -- If players have connection issues, try setting to 2
        
        AuthMinTrust = 5,               -- Minimum trust level required (5 = high security)
                                        -- Lower to 3 if experiencing legitimate player problems
        
        -- Client verification
        VerifyClientSettings = true     -- Verify client settings via adhesive connection
                                        -- Disable only if causing major issues
    },
    
    -- NETWORK EVENT SECURITY
    NetworkEvents = {
        -- Prevent malicious network events
        FilterRequestControl = 2,       -- Block REQUEST_CONTROL_EVENT routing (0 = off, 1 = occupied vehicles, 2 = all player-controlled entities)
                                        -- Set to 0 if vehicle/entity-related issues occur
        
        DisableNetworkedSounds = true,  -- Block NETWORK_PLAY_SOUND_EVENT routing
                                        -- May break some sound-based resources
        
        DisablePhoneExplosions = true,  -- Block REQUEST_PHONE_EXPLOSION_EVENT
                                        -- Safe to keep enabled in most cases
        
        DisableScriptEntityStates = false -- Block SCRIPT_ENTITY_STATE_CHANGE_EVENT
                                          -- May interfere with some entity-based scripts
    },
    
    -- CLIENT MODIFICATION PROTECTION
    ClientProtection = {
        -- Settings to prevent client-side modifications
        PureLevel = 0,                  -- Block modified client files (2 = max security)
                                        -- Set to 1 to allow audio mods and graphics changes
                                        -- Set to 0 to disable (not recommended)
        
        DisableClientReplays = true,    -- Prevents replay-based cheating techniques
                                        -- Note: Disables Rockstar Editor functionality
        
        ScriptHookAllowed = false       -- Prevents Script Hook from working
                                        -- Must be false for proper security
    },
    
    -- MISC SECURITY SETTINGS
    Misc = {
        -- Additional security measures
        EnableChatSanitization = true,  -- Sanitize chat messages (prevents exploits)
                                        -- Safe to keep enabled
        
        -- Rate limits to prevent flooding/DoS
        ResourceKvRateLimit = 20,       -- Resource KeyValue rate limit
                                        -- Lower if experiencing entity spam
        
        EntityKvRateLimit = 20          -- Entity KeyValue rate limit
                                        -- Lower if experiencing entity spam
    }
}

---@!!!IMPORTANT!!!
-- If you wish to enjoy everything secureserve has to offer and want secureserve to work properly enable the option: EnableModule
SecureServe.Module = {
	ModuleEnabled = false, -- Activates protection against unauthorized explosion events.
	Events = {
		Whitelist = { -- Events explicitly allowed even if detected as potential threats (prevents false bans).
			-- Add event names here that trigger false bans (check console for exact event names).
			"TestEvent",
			"playerJoining",
		},
	},

	Entity = {
		LockdownMode = "inactive", -- Controls entity creation security levels:
									 -- 'relaxed': Blocks client-side created entities not linked to scripts.
									 -- 'strict': Only allows server-side scripts to create entities.
									 -- 'inactive': Entity security disabled.

		SecurityWhitelist = { -- Resource exceptions allowing entity creation without triggering security measures.
			-- { resource = "bob74_ipl", whitelist = true },
			-- { resource = "6x_houserobbery", whitelist = true },
		},

		Limits = { -- Defines maximum number of entities each player can spawn before triggering bans.
			Vehicles = 10,
			Peds = 12,
			Objects = 20,
			Entities = 40,
		},
	},

	Explosions = {
		ModuleEnabled = false, -- Activates protection against unauthorized explosion events.

		Whitelist = { -- Allows specific resources to legitimately trigger explosion events without penalties.
			["resource_name_1"] = true,
			["resource_name_2"] = true,
		},
	},
}


-- |       ______ _______ _______
-- |      |     | |  ____ |______
-- |_____ |_____| |_____| ______|

-- SecureServe Logs they are
SecureServe.Logs = {
    -- Discord logger settings
    Enabled = true,         -- Enable or disable all Discord logging features
    
    -- Core webhook endpoints
    system = "",            -- System logs (startup, shutdown, etc.)
    detection = "",         -- Detection logs (player cheating detections)
    ban = "",               -- Ban logs
    kick = "",              -- Kick logs
    screenshot = "",        -- Screenshot logs
    admin = "",             -- Admin action logs
    debug = "",             -- Debug logs for troubleshooting
    
    -- New webhook endpoints
    join = "",              -- Player join logs
    leave = "",             -- Player leave logs
    kill = "",              -- Player kill logs
    resource = ""           -- Resource start/stop logs
}


-- _____   ______   _____  _______ _______ _______ _______ _____  _____  __   _
-- |_____] |_____/ |     |    |    |______ |          |      |   |     | | \  |
-- |       |    \_ |_____|    |    |______ |_____     |    __|__ |_____| |  \_|
SecureServe.BanTimes = { -- Preset ban times, preset name can be used in the protections.
	["Ban"] = 2147483647, -- Perm
	["Kick"] = -1,        -- Kick
	["Warn"] = 0,         -- Warn
}

SecureServe.Detections = {
    -- Central webhook for all detections (can be overridden per category)
    Webhook = "",
    
    -- Core client-side protections
    ClientProtections = {
        -- Movement & Position
        ["Anti Teleport"] = { enabled = true, action = "Ban", whitelisted_coords = {
            -- { x = -1037.62, y = -2737.86, z = 20.17, radius = 100.0 },
            -- { x = 200.0, y = -900.0, z = 30.0, radius = 60.0 }
        }},
        ["Anti Speed Hack"] = { enabled = true, action = "Ban", max_speed = 8.0, tolerance = 4.5 },
        ["Anti Super Jump"] = { enabled = true, action = "Ban" },
        ["Anti Noclip"] = { enabled = true, action = "Ban" },
        ["Anti Freecam"] = { enabled = true, action = "Ban" },
        ["Anti Spectate"] = { enabled = true, action = "Ban" },
        
        -- Combat & Weapons
        ["Anti Godmode"] = { enabled = true, action = "Ban" },
        ["Anti Invisible"] = { enabled = true, action = "Ban" },
        ["Anti Give Weapon"] = { enabled = true, action = "Ban" },
        ["Anti Weapon Pickup"] = { enabled = true, action = "Ban" },
        ["Anti Damage Modifier"] = { enabled = true, action = "Ban", multiplier = 1.5 },
        ["Anti No Recoil"] = { enabled = true, action = "Ban" },
        ["Anti No Reload"] = { enabled = true, action = "Ban" },
        ["Anti Rapid Fire"] = { enabled = true, action = "Ban" },
        ["Anti Infinite Ammo"] = { enabled = true, action = "Ban" },
        ["Anti Explosion Bullet"] = { enabled = true, action = "Ban" },
        ["Anti Magic Bullet"] = { enabled = true, action = "Ban", tolerance = 3 },
        ["Anti Aim Assist"] = { enabled = true, action = "Ban" },
        ["Anti Bigger Hitbox"] = { enabled = true, action = "Ban" },
        
        -- Visual & Effects
        ["Anti Night Vision"] = { enabled = true, action = "Ban" },
        ["Anti Thermal Vision"] = { enabled = true, action = "Ban" },
        ["Anti Player Blips"] = { enabled = true, action = "Ban" },
        ["Anti Particles"] = { enabled = true, action = "Ban", limit = 5 },
        
        -- Player State
        ["Anti Infinite Stamina"] = { enabled = true, action = "Ban" },
        ["Anti No Ragdoll"] = { enabled = true, action = "Ban" },
        ["Anti Remove From Car"] = { enabled = true, action = "Ban" },
        
        -- Vehicle Modifications
        ["Anti Vehicle God Mode"] = { enabled = true, action = "Ban" },
        ["Anti Vehicle Power Increase"] = { enabled = true, action = "Ban" },
        ["Anti Plate Changer"] = { enabled = true, action = "Ban" },
        ["Anti Car Fly"] = { enabled = true, action = "Ban" },
        ["Anti Car Ram"] = { enabled = false, action = "Ban" }, -- Disabled by default
        
        -- Advanced Detection
        ["Anti AI"] = { enabled = true, action = "Ban", sensitivity = 1.5 },
        ["Anti Cheat Engine"] = { enabled = true, action = "Ban" },
        ["Anti State Bag Overflow"] = { enabled = true, action = "Ban" },
        ["Anti Extended NUI Devtools"] = { enabled = true, action = "Ban" },
        ["Anti AFK Injection"] = { enabled = true, action = "Ban" },
        ["Anti Play Sound"] = { enabled = true, action = "Ban" },
        ["Anti Solo Session"] = { enabled = true, action = "Ban" },
        ["Anti Kill All"] = { enabled = true, action = "Ban" },
        ["Anti Rage"] = { enabled = true, action = "Ban" },
        
        -- Resource Management
        ["Anti Resource Stopper"] = { enabled = true, action = "Ban" },
        ["Anti Resource Starter"] = { enabled = true, action = "Ban" },
        
        -- Vehicle Protections
        ["Anti Vehicle Modifier"] = { 
            enabled = true, 
            action = "Ban",
            default = 1.5, -- Maximum allowed engine power multiplier
            defaultr = 1.5, -- Maximum allowed torque multiplier  
            defaults = 50.0, -- Minimum vehicle mass in kg
            tolerance = 5.0 -- Maximum traction/grip multiplier
        },
        
        -- Animation & Task Protections
        ["Anti Animation Injection"] = { 
            enabled = true, 
            action = "Ban",
            limit = 10 -- Max animations per time window before action
        },
        ["Anti Blacklisted Task"] = { 
            enabled = true, 
            action = "Ban",
            limit = 20 -- Max ClearPedTasks calls per time window
        }
    }
}

-- Server-Side Protection Settings
SecureServe.ServerProtections = {
    ["Anti Ped Spam"] = {
        enabled = true,
        action = "Ban",
        max_peds_per_player = 15, -- Maximum peds a player can spawn
        rapid_spawn_threshold = 5, -- Peds spawned in short time = ban
        rapid_spawn_window = 5000 -- Time window in ms for rapid spawn check
    },
    
    ["Anti Fake Death"] = {
        enabled = true,
        action = "Ban",
        death_spam_threshold = 5, -- Max deaths in time window
        death_spam_window = 30000 -- Time window in ms (30 seconds)
    },
    
    ["Anti Event Flood"] = {
        enabled = true,
        action = "Ban",
        max_events_per_second = 25, -- Max events per player per second
        suspicious_event_threshold = 50, -- Total events that trigger warning
        blocked_event_threshold = 5 -- Times player can trigger blocked events
    }
}

SecureServe.OCR = { -- Words on scrren that will get player banned
	"FlexSkazaMenu","SidMenu","Lynx8","LynxEvo","Maestro Menu","redEngine","HamMafia","HamHaxia","Dopameme","redMENU","Desudo","explode","gamesense","Anticheat","Tapatio","Malossi","RedStonia","Chocohax",
	"skin changer","torque multiple","override player speed","colision proof","explosion proof","copy outfit","play single particle","infinite ammo","rip server","remove ammo","remove all weapons",
	"V1s_u4l","D3str_0y","D3str_Oy","S3tt1ngs","P4rt1cl_3s","Pl4y3rz","D3l3t3","Sp4m","V3h1cl3s","T4ze","1nv1s1bll3","R41nb_0w","Sp33d","R41nb_Ow","F_ly","3xpl_0d3","Pr0pz","D3str_0y","M4p","G1v3",
	"Convert Vehicle Into Ramps","injected at","Explode Players","Ram Players","Force Third Person","fallout","godmode","ANTI-CHEAT","god mode","modmenu","esx money","give armor","aimbot","trigger",
	"triggerbot","rage bot","ragebot","rapidfire","freecam","execute","noclip","ckgangisontop","lumia1","ISMMENU","TAJNEMENUMenu","rootMenu","Outcasts666","WaveCheat","NacroxMenu","MarketMenu","topMenu",
	"Flip Vehicle","Rainbow Paintjob","Combat Assiters","Damage Multiplier","Give All Weapons","Teleport To","Explosive Impact","Server Nuke Options","No Ragdoll","Super Powers",
	"invisible all vehicles","Spam Message","Destroy Map","Give RPG","max Speed Vehicles","Rainbow All Vehicles","Delete Props","Cobra Menu","Bind Menu Key","Clone Outfit","Give Health",
	"Rp_GG","V3h1cl3","Sl4p","D4nce","3mote","D4nc3","no-clip","injected","Money Options","Nuke Options","Razer","Aimbot","TriggerBot","RageBot","RapidFire",
	"Force Player Blips","Force Radar","Force Gamertags","ESX Money Options","press AV PAG","TP to Waypoint","S elf Options","Vehicle options","Weapon Options","spam Vehicles","taze All",
	"explosive ammo","super damage","rapid fire","Super Jump","Infinite Roll","No Criticals","Move On Water","Disable Ragdoll","CutzuSD","Vertisso","M3ny00","Pl4y_3r","W34p_On","W34p_0n","V3h1_cl3",
	"fuck server","lynx","absolute","Lumia","Gamesense","Fivesense","SkidMenu","Dopamine","Explode","Teleport Options","infnite combat roll","Hydro Menu","Enter Menu Open Key",
	"Give Single Weapon","Airstrike Player","Taze Player","Razer Menu","Swagamine","Visual Options","d0pamine","Infinite Stamina","Blackout","Delete Vehicles Within Radius","Engine Power Boost",
	"Teleport Into Player's Vehicle","fivesense","menu keybind","nospread","transparent props","bullet tracers","model chams","reload images","fade out in speed","cursor size","custom weapons texture",
	"Inyection","Inyected","Dumper","LUA Executor","Executor","Lux Menu","Event Blocker","Spectate","Wallhack","triggers","crosshair","Alokas66","Hacking System!","Destroy Menu","Server IP","Teleport To",
	"Butan Premium", "RAIDEN", "Give All Weapons", "Miscellaneous", "World Menu", "Sex Adanc", "Tapatio®", "Rico", "Rico Menu"
}

SecureServe.Weapons = { -- Add all your weapons to here most of the weapons should arlready be here make sure u added all of them if you are using qbcore if not u can delete this
	[GetHashKey('WEAPON_FLASHLIGHT')] = 'WEAPON_FLASHLIGHT',
	[GetHashKey('weapon_flashbang')] = 'weapon_flashbang',
	[GetHashKey('WEAPON_KNIFE')] = 'WEAPON_KNIFE',
	[GetHashKey('WEAPON_MACHETE')] = 'WEAPON_MACHETE',
	[GetHashKey('WEAPON_NIGHTSTICK')] = 'WEAPON_NIGHTSTICK',
	[GetHashKey('WEAPON_HAMMER')] = 'WEAPON_HAMMER',
	[GetHashKey('WEAPON_BATS')] = 'WEAPON_BATS',
	[GetHashKey('WEAPON_GOLFCLUB')] = 'WEAPON_GOLFCLUB',
	[GetHashKey('WEAPON_CROWBAR')] = 'WEAPON_CROWBAR',
	[GetHashKey('WEAPON_BOTTLE')] = 'WEAPON_BOTTLE',
	[GetHashKey('WEAPON_HATCHET')] = 'WEAPON_HATCHET',
	[GetHashKey('WEAPON_DAGGER')] = 'WEAPON_DAGGER',
	[GetHashKey('WEAPON_KATANA')] = 'WEAPON_KATANA',
	[GetHashKey('WEAPON_SHIV')] = 'WEAPON_SHIV',
	[GetHashKey('WEAPON_WRENCH')] = 'WEAPON_WRENCH',
	[GetHashKey('WEAPON_BOOK')] = 'WEAPON_BOOK',
	[GetHashKey('WEAPON_CASH')] = 'WEAPON_CASH',
	[GetHashKey('WEAPON_BRICK')] = 'WEAPON_BRICK',
	[GetHashKey('WEAPON_SHOE')] = 'WEAPON_SHOE',
	[GetHashKey('WEAPON_PISTOL')] = 'WEAPON_PISTOL',
	[GetHashKey('WEAPON_PISTOL_MK2')] = 'WEAPON_PISTOL_MK2',
	[GetHashKey('WEAPON_COMBATPISTOL')] = 'WEAPON_COMBATPISTOL',
	[GetHashKey('WEAPON_FN57')] = 'WEAPON_FN57',
	[GetHashKey('WEAPON_APPISTOL')] = 'WEAPON_APPISTOL',
	[GetHashKey('WEAPON_PISTOL50')] = 'WEAPON_PISTOL50',
	[GetHashKey('WEAPON_SNSPISTOL')] = 'WEAPON_SNSPISTOL',
	[GetHashKey('WEAPON_HEAVYPISTOL')] = 'WEAPON_HEAVYPISTOL',
	[GetHashKey('WEAPON_NAILGUN')] = 'WEAPON_NAILGUN',
	[GetHashKey('WEAPON_GLOCK17')] = 'WEAPON_GLOCK17',
	[GetHashKey('WEAPON_GLOCK')] = 'WEAPON_GLOCK',
	[GetHashKey('WEAPON_BROWNING')] = 'WEAPON_BROWNING',
	[GetHashKey('WEAPON_DP9')] = 'WEAPON_DP9',
	[GetHashKey('WEAPON_MICROSMG')] = 'WEAPON_MICROSMG',
	[GetHashKey('weapon_microsmg2')] = 'weapon_microsmg2',
	[GetHashKey('weapon_microsmg3')] = 'weapon_microsmg3',
	[GetHashKey('WEAPON_MP7')] = 'WEAPON_MP7',
	[GetHashKey('WEAPON_SMG')] = 'WEAPON_SMG',
	[GetHashKey('WEAPON_MINISMG2')] = 'WEAPON_MINISMG2',
	[GetHashKey('WEAPON_MACHINEPISTOL')] = 'WEAPON_MACHINEPISTOL',
	[GetHashKey('WEAPON_COMBATPDW')] = 'WEAPON_COMBATPDW',
	[GetHashKey('WEAPON_PUMPSHOTGUN')] = 'WEAPON_PUMPSHOTGUN',
	[GetHashKey('WEAPON_PUMPSHOTGUN_MK2')] = 'WEAPON_PUMPSHOTGUN_MK2',
	[GetHashKey('WEAPON_SAWNOFFSHOTGUN')] = 'WEAPON_SAWNOFFSHOTGUN',
	[GetHashKey('WEAPON_AK47')] = 'WEAPON_AK47',
	[GetHashKey('weapon_assaultrifle2')] = 'weapon_assaultrifle2',
	[GetHashKey('weapon_assaultrifle_mk2')] = 'weapon_assaultrifle_mk2',
	[GetHashKey('weapon_stungun')] = 'weapon_stungun',
	[GetHashKey('WEAPON_CARBINERIFLE')] = 'WEAPON_CARBINERIFLE',
	[GetHashKey('WEAPON_CARBINERIFLE_MK2')] = 'WEAPON_CARBINERIFLE_MK2',
	[GetHashKey('WEAPON_ADVANCEDRIFLE')] = 'WEAPON_ADVANCEDRIFLE',
	[GetHashKey('WEAPON_M4')] = 'WEAPON_M4',
	[GetHashKey('WEAPON_HK416')] = 'WEAPON_HK416',
	[GetHashKey('WEAPON_AR15')] = 'WEAPON_AR15',
	[GetHashKey('WEAPON_M110')] = 'WEAPON_M110',
	[GetHashKey('WEAPON_M14')] = 'WEAPON_M14',
	[GetHashKey('WEAPON_SPECIALCARBINE_MK2')] = 'WEAPON_SPECIALCARBINE_MK2',
	[GetHashKey('WEAPON_DRAGUNOV')] = 'WEAPON_DRAGUNOV',
	[GetHashKey('WEAPON_COMPACTRIFLE')] = 'WEAPON_COMPACTRIFLE',
	[GetHashKey('WEAPON_MG')] = 'WEAPON_MG',
	[GetHashKey('WEAPON_SNIPERRIFLE')] = 'WEAPON_SNIPERRIFLE',
	[GetHashKey('WEAPON_SNIPERRIFLE2')] = 'WEAPON_SNIPERRIFLE2',
	[GetHashKey('WEAPON_GRENADELAUNCHER_SMOKE')] = 'WEAPON_GRENADELAUNCHER_SMOKE',
	[GetHashKey('WEAPON_RPG')] = 'WEAPON_RPG',
	[GetHashKey('WEAPON_MINIGUN')] = 'WEAPON_MINIGUN',
	[GetHashKey('WEAPON_GRENADE')] = 'WEAPON_GRENADE',
	[GetHashKey('WEAPON_STICKYBOMB')] = 'WEAPON_STICKYBOMB',
	[GetHashKey('WEAPON_SMOKEGRENADE')] = 'WEAPON_SMOKEGRENADE',
	[GetHashKey('WEAPON_BZGAS')] = 'WEAPON_BZGAS',
	[GetHashKey('WEAPON_MOLOTOV')] = 'WEAPON_MOLOTOV',
	[GetHashKey('WEAPON_FIREWORK')] = 'WEAPON_FIREWORK',
	[GetHashKey('WEAPON_TASER')] = 'WEAPON_TASER',
	[GetHashKey('WEAPON_RAILGUN')] = 'WEAPON_RAILGUN',
	[GetHashKey('WEAPON_DBSHOTGUN')] = 'WEAPON_DBSHOTGUN',
	[GetHashKey('WEAPON_LTL')] = 'WEAPON_LTL',
	[GetHashKey('WEAPON_PIPEBOMB')] = 'WEAPON_PIPEBOMB',
	[GetHashKey('WEAPON_DOUBLEACTION')] = 'WEAPON_DOUBLEACTION',
	[GetHashKey('WEAPON_ASSAULTRIFLE')] = 'WEAPON_ASSAULTRIFLE',
	[GetHashKey('WEAPON_PISTOL')] = 'WEAPON_PISTOL',
	[GetHashKey('WEAPON_PISTOL_MK2')] = 'WEAPON_PISTOL_MK2',
	[GetHashKey('WEAPON_COMBATPISTOL')] = 'WEAPON_COMBATPISTOL',
	[GetHashKey('WEAPON_APPISTOL')] = 'WEAPON_APPISTOL',
	[GetHashKey('WEAPON_PISTOL50')] = 'WEAPON_PISTOL50',
	[GetHashKey('WEAPON_SNSPISTOL')] = 'WEAPON_SNSPISTOL',
	[GetHashKey('WEAPON_HEAVYPISTOL')] = 'WEAPON_HEAVYPISTOL'
}

SecureServe.Webhooks.BlacklistedExplosions = ""  -- Takes action if an explosion with the id got detected.
SecureServe.Protection.BlacklistedExplosions = {
    { id = 0, time = "Ban",  webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Grenades
    { id = 1, time = "Ban",  webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Sticky Bombs
    { id = 2, time = "Ban",  webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Grenade Launcher
    { id = 3, time = "Ban",  webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Molotov Cocktails
    { id = 4, time = "Ban",  webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Rockets
    { id = 5, time = "Ban",  webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Tank Shells
    { id = 6, time = "Ban",  webhook = "", limit = 4, audio = true, scale = 1.0, invisible = false }, -- Hi Octane
    { id = 7, time = "Ban",  webhook = "", limit = 5, audio = true, scale = 1.0, invisible = false }, -- Car Explosions
    { id = 18, time = "Ban",  limit = 8, audio = true, scale = 1.0, invisible = false }, -- Bullet Explosions
    { id = 19, time = "Ban",  limit = 8, audio = true, scale = 1.0, invisible = false }, -- Smoke Grenade Launcher
    { id = 20, time = "Ban",  limit = 5, audio = true, scale = 1.0, invisible = false }, -- Smoke Grenades
    { id = 21, time = "Ban",  limit = 5, audio = true, scale = 1.0, invisible = false }, -- BZ Gas
    { id = 22, time = "Ban",  limit = 5, audio = true, scale = 1.0, invisible = false }, -- Flares
    { id = 25, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Programmable AR
    { id = 36, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Railgun
    { id = 37, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Blimp 2
    { id = 38, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Fireworks
    { id = 40, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Proximity Mines
    { id = 43, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Pipe Bombs
    { id = 44, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Vehicle Mines
    { id = 45, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Explosive Ammo
    { id = 46, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- APC Shells
    { id = 47, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Cluster Bombs
    { id = 48, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Gas Bombs
    { id = 49, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Incendiary Bombs
    { id = 50, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Standard Bombs
    { id = 51, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Torpedoes
    { id = 52, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Underwater Torpedoes
    { id = 53, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Bombushka Cannon
    { id = 54, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Cluster Bomb Secondary Explosions
    { id = 55, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Hunter Barrage
    { id = 56, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Hunter Cannon
    { id = 57, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Rogue Cannon
    { id = 58, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Underwater Mines
    { id = 59, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Orbital Cannon
    { id = 60, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Wide Standard Bombs
    { id = 61, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Explosive Shotgun Ammo
    { id = 62, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Oppressor 2 Cannon
    { id = 63, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Kinetic Mortar
    { id = 64, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Kinetic Vehicle Mine
    { id = 65, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- EMP Vehicle Mine
    { id = 66, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Spike Vehicle Mine
    { id = 67, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Slick Vehicle Mine
    { id = 68, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Tar Vehicle Mine
    { id = 69, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Script Drone
    { id = 70, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Raygun
	{ id = 71, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Buried Mine
	{ id = 72, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Script Missle
	{ id = 82, time = "Ban",  limit = 1, audio = true, scale = 1.0, invisible = false }, -- Submarine
}

SecureServe.Webhooks.BlacklistedCommands = ""
SecureServe.Protection.BlacklistedCommands = { -- Takes action if a blacklisted command is registered.
	{ command = "jd",                        time = "Ban" },
	{ command = "KP",                        time = "Ban" },
	{ command = "opk",                       time = "Ban" },
	{ command = "ham",                       time = "Ban" },
	{ command = "lol",                       time = "Ban" },
	{ command = "hoax",                      time = "Ban" },
	{ command = "vibes",                     time = "Ban" },
	{ command = "haha",                      time = "Ban" },
	{ command = "panik",                     time = "Ban" },
	{ command = "brutan",                    time = "Ban" },
	{ command = "panic",                     time = "Ban" },
	{ command = "hyra",                      time = "Ban" },
	{ command = "hydro",                     time = "Ban" },
	{ command = "lynx",                      time = "Ban" },
	{ command = "tiago",                     time = "Ban" },
	{ command = "desudo",                    time = "Ban" },
	{ command = "ssssss",                    time = "Ban" },
	{ command = "redstonia",                 time = "Ban" },
	{ command = "dopamine",                  time = "Ban" },
	{ command = "dopamina",                  time = "Ban" },
	{ command = "purgemenu",                 time = "Ban" },
	{ command = "WarMenu",                   time = "Ban" },
	{ command = "lynx9_fixed",               time = "Ban" },
	{ command = "injected",                  time = "Ban" },
	{ command = "hammafia",                  time = "Ban" },
	{ command = "hamhaxia",                  time = "Ban" },
	{ command = "chocolate",                 time = "Ban" },
	{ command = "Information",               time = "Ban" },
	{ command = "Maestro",                   time = "Ban" },
	{ command = "FunCtionOk",                time = "Ban" },
	{ command = "TiagoModz",                 time = "Ban" },
	{ command = "jolmany",                   time = "Ban" },
	{ command = "SovietH4X",                 time = "Ban" },
	{ command = "killmenu",                  time = "Ban" },
	{ command = "panickey",                  time = "Ban" },
	{ command = "d0pamine",                  time = "Ban" },
	{ command = "[dopamine]",                time = "Ban" },
	{ command = "brutanpremium",             time = "Ban" },
	{ command = "www.d0pamine.xyz",          time = "Ban" },
	{ command = "d0pamine v1.1 by Nertigel", time = "Ban" },
	{ command = "TiagoModz#1478",            time = "Ban" },
}

SecureServe.Webhooks.BlacklistedSprites = ""
SecureServe.Protection.BlacklistedSprites = { -- Takes action if a blacklisted sprite is detected.
	{ sprite = "deadline",           name = "Dopamine",            time = "Ban" },
	{ sprite = "Dopameme",           name = "Dopamine Menu",       time = "Ban" },
	{ sprite = "dopamine",           name = "Dopamine Menu",       time = "Ban" },
	{ sprite = "dopamemes",          name = "Dopameme Menu",       time = "Ban" },
	{ sprite = "wm2",                name = "WM Menu",             time = "Ban" },
	{ sprite = "KentasCheckboxDict", name = "Kentas Menu Synapse", time = "Ban" },
	{ sprite = "KentasMenu",         name = "Kentas Menu Synapse", time = "Ban" },
	{ sprite = "HydroMenuHeader",    name = "HydroMenu",           time = "Ban" },
	{ sprite = "godmenu",            name = "God Menu",            time = "Ban" },
	{ sprite = "redrum",             name = "Redrum Menu",         time = "Ban" },
	{ sprite = "beautiful",          name = "Beautiful Menu",      time = "Ban" },
	{ sprite = "Absolut",            name = "Absolute Menu",       time = "Ban" },
	{ sprite = "hoaxmenu",           name = "Hoax Menu",           time = "Ban" },
	{ sprite = "fendin",             name = "Fendinx Menu",        time = "Ban" },
	{ sprite = "Ham",                name = "Ham Menu",            time = "Ban" },
	{ sprite = "hammafia",           name = "Ham Mafia Menu",      time = "Ban" },
	{ sprite = "Fallout",            name = "Fallout",             time = "Ban" },
	{ sprite = "menu_bg",            name = "Fallout Menu",        time = "Ban" },
	{ sprite = "DefaultMenu",        name = "Default Menu",        time = "Ban" },
	{ sprite = "ISMMENUHeader",      name = "ISMMENU",             time = "Ban" },
	{ sprite = "fivesense",          name = "Fivesense Menu",      time = "Ban" },
	{ sprite = "maestro",            name = "Maestro Menu",        time = "Ban" },
	{ sprite = "kekhack",            name = "KekHack Menu",        time = "Ban" },
	{ sprite = "trolling",           name = "Trolling Menu",       time = "Ban" },
	{ sprite = "mm",                 name = "MM Menu",             time = "Ban" },
	{ sprite = "MmPremium",          name = "MM Premium Menu",     time = "Ban" },
	{ sprite = "Fallout",            name = "Fallout",             time = "Ban" },
	{ sprite = "dopatest",           name = "Dopa Menu",           time = "Ban" },
	{ sprite = "deadline",           name = "Dopamine",            time = "Ban" },
	{ sprite = "dopamine",           name = "Dopamine Menu",       time = "Ban" },
	{ sprite = "cat",                name = "Cat Menu",            time = "Ban" },
	{ sprite = "John2",              name = "SugarMenu",           time = "Ban" },
	{ sprite = "bartowmenu",         name = "Bartow Menu",         time = "Ban" },
	{ sprite = "duiTex",             name = "Copypaste Menu",      time = "Ban" },
	{ sprite = "Mafins",             name = "Mafins Menu",         time = "Ban" },
	{ sprite = "__REAPER24__",       name = "Repear Menu",         time = "Ban" },
	{ sprite = "__REAPER5__",        name = "Repear Menu",         time = "Ban" },
	{ sprite = "__REAPER7__",        name = "Repear Menu",         time = "Ban" },
	{ sprite = "__REAPER8__",        name = "Repear Menu",         time = "Ban" },
	{ sprite = "__REAPER10__",       name = "Repear Menu",         time = "Ban" },
	{ sprite = "__REAPER3__",        name = "Repear Menu",         time = "Ban" },
	{ sprite = "__REAPER2__",        name = "Repear Menu",         time = "Ban" },
	{ sprite = "__REAPER1__",        name = "Repear Menu",         time = "Ban" },
	{ sprite = "__REAPER23__",       name = "Repear Menu",         time = "Ban" },
	{ sprite = "__REAPER17__",       name = "Repear Menu",         time = "Ban" },
	{ sprite = "skidmenu",           name = "Skid Menu",           time = "Ban" },
	{ sprite = "skidmenu",           name = "Skid Menu",           time = "Ban" },
	{ sprite = "Urubu3",             name = "Urubu Menu",          time = "Ban" },
	{ sprite = "Urubu",              name = "Urubu Menu",          time = "Ban" },
	{ sprite = "love",               name = "Love Menu",           time = "Ban" },
	{ sprite = "brutan",             name = "Brutan Menu",         time = "Ban" },
	{ sprite = "auttaja",            name = "Auttaja Menu",        time = "Ban" },
	{ sprite = "oblivious",          name = "Oblivious Menu",      time = "Ban" },
	{ sprite = "malossimenu",        name = "Malossi Menu",        time = "Ban" },
	{ sprite = "Memeeee",            name = "Memeeee Menu",        time = "Ban" },
	{ sprite = "Tiago",              name = "Tiago Menu",          time = "Ban" },
	{ sprite = "fantasy",            name = "Fantasy Menu",        time = "Ban" },
	{ sprite = "Vagos",              name = "Vagos Menu",          time = "Ban" },
	{ sprite = "simplicity",         name = "Simplicity Menu",     time = "Ban" },
	{ sprite = "WarMenu",            name = "War Menu",            time = "Ban" },
	{ sprite = "Darkside",           name = "Darkside Menu",       time = "Ban" },
	{ sprite = "antario",            name = "Antario Menu",        time = "Ban" },
	{ sprite = "kingpin",            name = "Kingpin Menu",        time = "Ban" },
	{ sprite = "Wave (alt.)",        name = "Wave (alt.)",         time = "Ban" },
	{ sprite = "Wave",               name = "Wave",                time = "Ban" },
	{ sprite = "Alokas66",           name = "Alokas66",            time = "Ban" },
	{ sprite = "Guest Menu",         name = "Guest Menu",          time = "Ban" },
}

SecureServe.Webhooks.BlacklistedAnimDicts = ""
SecureServe.Protection.BlacklistedAnimDicts = { -- Takes action if a blacklisted anim dict got loaded.
	{ dict = "rcmjosh2",       time = "Ban" },
	{ dict = "rcmpaparazzo_2", time = "Ban" },
}

SecureServe.Webhooks.BlacklistedWeapons = ""
SecureServe.Protection.BlacklistedWeapons = { -- Weapons Names can be found here: https://gtahash.ru/weapons/
	{ name = "weapon_rayminigun",      time = "Ban" },
	{ name = "weapon_raycarbine",      time = "Ban" },
	{ name = "weapon_rpg",             time = "Ban" },
	{ name = "weapon_grenadelauncher", time = "Ban" },
	{ name = "weapon_minigun",         time = "Ban" },
	{ name = "weapon_railgun",         time = "Ban" },
	{ name = "weapon_firework",        time = "Ban" },
	{ name = "weapon_hominglauncher",  time = "Ban" },
	{ name = "weapon_compactlauncher", time = "Ban" },
}

SecureServe.Webhooks.BlacklistedVehicles = ""
SecureServe.Protection.BlacklistedVehicles = { -- Vehicles List can be found here: https://wiki.rage.mp/index.php?title=Vehicles
	{ name = "dinghy5",       time = "Ban" },
	{ name = "kosatka",       time = "Ban" },
	{ name = "patrolboat",    time = "Ban" },
	{ name = "cerberus",      time = "Ban" },
	{ name = "cerberus2",     time = "Ban" },
	{ name = "cerberus3",     time = "Ban" },
	{ name = "phantom2",      time = "Ban" },
	{ name = "akula",         time = "Ban" },
	{ name = "annihilator",   time = "Ban" },
	{ name = "buzzard",       time = "Ban" },
	{ name = "savage",        time = "Ban" },
	{ name = "annihilator2",  time = "Ban" },
	{ name = "cutter",        time = "Ban" },
	{ name = "apc",           time = "Ban" },
	{ name = "barrage",       time = "Ban" },
	{ name = "chernobog",     time = "Ban" },
	{ name = "halftrack",     time = "Ban" },
	{ name = "khanjali",      time = "Ban" },
	{ name = "minitank",      time = "Ban" },
	{ name = "rhino",         time = "Ban" },
	{ name = "thruster",      time = "Ban" },
	{ name = "trailersmall2", time = "Ban" },
	{ name = "oppressor",     time = "Ban" },
	{ name = "oppressor2",    time = "Ban" },
	{ name = "dukes2",        time = "Ban" },
	{ name = "ruiner2",       time = "Ban" },
	{ name = "dune3",         time = "Ban" },
	{ name = "dune4",         time = "Ban" },
	{ name = "dune5",         time = "Ban" },
	{ name = "insurgent",     time = "Ban" },
	{ name = "insurgent3",    time = "Ban" },
	{ name = "menacer",       time = "Ban" },
	{ name = "rcbandito",     time = "Ban" },
	{ name = "technical3",    time = "Ban" },
	{ name = "technical2",    time = "Ban" },
	{ name = "technical",     time = "Ban" },
	{ name = "avenger",       time = "Ban" },
	{ name = "avenger2",      time = "Ban" },
	{ name = "bombushka",     time = "Ban" },
	{ name = "cargoplane",    time = "Ban" },
	{ name = "cargoplane2",   time = "Ban" },
	{ name = "hydra",         time = "Ban" },
	{ name = "lazer",         time = "Ban" },
	{ name = "molotok",       time = "Ban" },
	{ name = "nokota",        time = "Ban" },
	{ name = "pyro",          time = "Ban" },
	{ name = "rogue",         time = "Ban" },
	{ name = "starling",      time = "Ban" },
	{ name = "strikeforce",   time = "Ban" },
	{ name = "limo2",         time = "Ban" },
	{ name = "scramjet",      time = "Ban" },
	{ name = "vigilante",     time = "Ban" },
}

SecureServe.Protection.BlacklistedPeds = { -- Add blacklisted ped models here
    { name = "s_m_y_swat_01", hash = GetHashKey("s_m_y_swat_01") },
    { name = "s_m_y_hwaycop_01", hash = GetHashKey("s_m_y_hwaycop_01") },
    { name = "s_m_m_movalien_01", hash = GetHashKey("s_m_m_movalien_01") },
}

SecureServe.Webhooks.BlacklistedObjects = ""
SecureServe.Protection.BlacklistedObjects = {
	{ name = "prop_logpile_07b",                         },
	{ name = "prop_logpile_07",                          },
	{ name = "prop_logpile_06b",                         },
	{ name = "prop_logpile_06",                          },
	{ name = "prop_logpile_05",                          },
	{ name = "prop_logpile_04",                          },
	{ name = "prop_logpile_03",                          },
	{ name = "prop_logpile_02",                          },
	{ name = "prop_logpile_01",                          },
	{ name = "hei_prop_carrier_radar_1_l1",              },
	{ name = "v_res_mexball",                            },
	{ name = "prop_rock_1_a",                            },
	{ name = "prop_rock_1_b",                            },
	{ name = "prop_rock_1_c",                            },
	{ name = "prop_rock_1_d",                            },
	{ name = "prop_player_gasmask",                      },
	{ name = "prop_rock_1_e",                            },
	{ name = "prop_rock_1_f",                            },
	{ name = "prop_rock_1_g",                            },
	{ name = "prop_rock_1_h",                            },
	{ name = "prop_test_boulder_01",                     },
	{ name = "prop_test_boulder_02",                     },
	{ name = "prop_test_boulder_03",                     },
	{ name = "prop_test_boulder_04",                     },
	{ name = "apa_mp_apa_crashed_usaf_01a",              },
	{ name = "ex_prop_exec_crashdp",                     },
	{ name = "apa_mp_apa_yacht_o1_rail_a",               },
	{ name = "apa_mp_apa_yacht_o1_rail_b",               },
	{ name = "apa_mp_h_yacht_armchair_01",               },
	{ name = "apa_mp_h_yacht_armchair_03",               },
	{ name = "apa_mp_h_yacht_armchair_04",               },
	{ name = "apa_mp_h_yacht_barstool_01",               },
	{ name = "apa_mp_h_yacht_bed_01",                    },
	{ name = "apa_mp_h_yacht_bed_02",                    },
	{ name = "apa_mp_h_yacht_coffee_table_01",           },
	{ name = "apa_mp_h_yacht_coffee_table_02",           },
	{ name = "apa_mp_h_yacht_floor_lamp_01",             },
	{ name = "apa_mp_h_yacht_side_table_01",             },
	{ name = "apa_mp_h_yacht_side_table_02",             },
	{ name = "apa_mp_h_yacht_sofa_01",                   },
	{ name = "apa_mp_h_yacht_sofa_02",                   },
	{ name = "apa_mp_h_yacht_stool_01",                  },
	{ name = "apa_mp_h_yacht_strip_chair_01",            },
	{ name = "apa_mp_h_yacht_table_lamp_01",             },
	{ name = "apa_mp_h_yacht_table_lamp_02",             },
	{ name = "apa_mp_h_yacht_table_lamp_03",             },
	{ name = "prop_flag_columbia",                       },
	{ name = "apa_mp_apa_yacht_o2_rail_a",               },
	{ name = "apa_mp_apa_yacht_o2_rail_b",               },
	{ name = "apa_mp_apa_yacht_o3_rail_a",               },
	{ name = "apa_mp_apa_yacht_o3_rail_b",               },
	{ name = "apa_mp_apa_yacht_option1",                 },
	{ name = "proc_searock_01",                          },
	{ name = "apa_mp_h_yacht_",                          },
	{ name = "apa_mp_apa_yacht_option1_cola",            },
	{ name = "apa_mp_apa_yacht_option2",                 },
	{ name = "apa_mp_apa_yacht_option2_cola",            },
	{ name = "apa_mp_apa_yacht_option2_colb",            },
	{ name = "apa_mp_apa_yacht_option3",                 },
	{ name = "apa_mp_apa_yacht_option3_cola",            },
	{ name = "apa_mp_apa_yacht_option3_colb",            },
	{ name = "apa_mp_apa_yacht_option3_colc",            },
	{ name = "apa_mp_apa_yacht_option3_cold",            },
	{ name = "apa_mp_apa_yacht_option3_cole",            },
	{ name = "apa_mp_apa_yacht_jacuzzi_cam",             },
	{ name = "apa_mp_apa_yacht_jacuzzi_ripple003",       },
	{ name = "apa_mp_apa_yacht_jacuzzi_ripple1",         },
	{ name = "apa_mp_apa_yacht_jacuzzi_ripple2",         },
	{ name = "apa_mp_apa_yacht_radar_01a",               },
	{ name = "apa_mp_apa_yacht_win",                     },
	{ name = "prop_crashed_heli",                        },
	{ name = "apa_mp_apa_yacht_door",                    },
	{ name = "prop_shamal_crash",                        },
	{ name = "xm_prop_x17_shamal_crash",                 },
	{ name = "apa_mp_apa_yacht_door2",                   },
	{ name = "apa_mp_apa_yacht",                         },
	{ name = "prop_flagpole_2b",                         },
	{ name = "prop_flagpole_2c",                         },
	{ name = "prop_flag_canada",                         },
	{ name = "apa_prop_yacht_float_1a",                  },
	{ name = "apa_prop_yacht_float_1b",                  },
	{ name = "apa_prop_yacht_glass_01",                  },
	{ name = "apa_prop_yacht_glass_02",                  },
	{ name = "apa_prop_yacht_glass_03",                  },
	{ name = "prop_beach_fire",                          },
	{ name = "prop_rock_4_big2",                         },
	{ name = "prop_beachflag_le",                        },
	{ name = "freight",                                  },
	{ name = "stt_prop_race_start_line_03b",             },
	{ name = "stt_prop_stunt_soccer_sball",              }
}


---@DONT TOUCH THIS (BACKWARDS COMPATIBILITY INSTEAD OF MODIFYING THE ENTIRE LOADER)
SecureServe.Webhooks.Simple = SecureServe.Detections.Webhook
SecureServe.Protection.Simple = {}
for name, settings in pairs(SecureServe.Detections.ClientProtections) do
    table.insert(SecureServe.Protection.Simple, {
        protection = name,
        enabled = settings.enabled,
        time = settings.action,
        webhook = "",
        limit = settings.limit,
        default = settings.multiplier or settings.sensitivity,
        defaultr = settings.max_speed,
        defaults = settings.tolerance,
        tolerance = settings.tolerance,
        whitelisted_coords = settings.whitelisted_coords
    })
end

for k, v in pairs(SecureServe.Protection.BlacklistedExplosions) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedExplosions[k].webhook = SecureServe.Webhooks.BlacklistedExplosions
    end
end

for k, v in pairs(SecureServe.Protection.BlacklistedCommands) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedCommands[k].webhook = SecureServe.Webhooks.BlacklistedCommands
    end
end

for k, v in pairs(SecureServe.Protection.BlacklistedSprites) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedSprites[k].webhook = SecureServe.Webhooks.BlacklistedSprites
    end
end

for k, v in pairs(SecureServe.Protection.BlacklistedAnimDicts) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedAnimDicts[k].webhook = SecureServe.Webhooks.BlacklistedAnimDicts
    end
end

for k, v in pairs(SecureServe.Protection.BlacklistedWeapons) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedWeapons[k].webhook = SecureServe.Webhooks.BlacklistedWeapons
    end
end

for k, v in pairs(SecureServe.Protection.BlacklistedVehicles) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedVehicles[k].webhook = SecureServe.Webhooks.BlacklistedVehicles
    end
end

for k, v in pairs(SecureServe.Protection.BlacklistedObjects) do
    if v.webhook == "" then
        SecureServe.Protection.BlacklistedObjects[k].webhook = SecureServe.Webhooks.BlacklistedObjects
    end
end