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






--  ______ _______ __   _ _______  ______ _______       
-- |  ____ |______ | \  | |______ |_____/ |_____| |     
-- |_____| |______ |  \_| |______ |    \_ |     | |_____
SecureServe.ServerName = ""                                                                   -- The name of the server.
SecureServe.DiscordLink = ""                                                                  -- The link to your discord server.
SecureServe.RequireSteam = false                                                              -- Just requires players that want to join your server to have steam open and logged in as well u must have a valid steam api key for this option read more in docs
SecureServe.IdentifierCheck = true                                                            -- Checks when player connects if his identifiers are valid. if not it won't let him join the server.
SecureServe.Debug = true 																      -- Enables debug mode, this will print debug messages in the console.



-- This will auto config safe events and entity security as well as explosions but when u use this u must follow the instructions!
-- 1) Make sure that first the ac loads up with no errors if it does follow docs and make sure u installed correctly
-- 2) Enable the option below ( set SecureServe.AutoConfig to true and not false as follows 'SecureServe.AutoConfig = true' )
-- 3) Restart the server and check the console for any errors 
-- 4) If no errors are found u can get into the server and play normally
-- Important!!!!!!!! - now when this is enabled u shouldnt try any cheets in your server and make sure that u are the only one in there u can do this with more people but make sure they are not using any cheats
-- This option will auto config the ac for u only in safe events and in explosions and in entityn security
-- Now after u played for some time in your server disable this option then restart it and then u can let other players play normmaly this option is important to be disabled since it prevents any bans
-- Meaning no one can be bnnaed while this is active
SecureServe.AutoConfig = false              
-- Once u start the server explnation about this option will come up please read everything
SecureServe.InstructionsPrint = true

-- _______ _    _ _______ __   _ _______ _______
-- |______  \  /  |______ | \  |    |    |______
-- |______   \/   |______ |  \_|    |    ______|                                                  
SecureServe.EnableAutoSafeEvents = true  -- Enables auto safe events meaning it will by defualt install the module for you
SecureServe.EventWhitelist = {
	-- If u get the fowlling ban: 
    -- "A player has been banned for Trigger Event with an executor (name of the event)"
	-- And its a false ban add the event name to here
	-- [Note] enableautosafe events must be on for this to work
	"TestEvent",
}

-- manual safe events still requires module they are just if u dont want to use the auto which i dont see a reason why not with auto config as an option
-- DONT USE THIS THIS ISNT FINISHED AND THIS ISNT HOW U WHITELIST EVENTS! WHITELISTING EVENTS IS DONE IN SecureServe.EventWhitelist
SecureServe.ProtectedEvents = {
	-- This will only work if enable auto safe events is false this will protect only the events listed here 
	"event_name",
}



-- _______ __   _ _______ _____ _______ __   __
-- |______ | \  |    |      |      |      \_/  
-- |______ |  \_|    |    __|__    |       |   
SecureServe.EntityLockdownMode = "inactive" -- relaxed: Only script-owned entities created by clients are blocked., strict: Only Server-Side Scripts can create entites. | inactive 
SecureServe.EntitySecurity = { -- Resources that are causing false bans add to here make sure to use lowercases and put the name corretely
	{ resource = "bob74_ipl",  whitelist = true},
	{ resource = "6x_houserobbery",  whitelist = true},
}

SecureServe.Webhooks.SpamEntities = ""  
SecureServe.maxVehicle = 5 -- How many vehicles can player spawn before getting banned
SecureServe.maxPed = 5 -- How many peds can player spawn before getting banned
SecureServe.maxObject = 10 -- How many objects can player spawn before getting banned


-- _______ _     _  _____          _____  _______ _____  _____  __   _ _______
-- |______  \___/  |_____] |      |     | |______   |   |     | | \  | |______
-- |______ _/   \_ |       |_____ |_____| ______| __|__ |_____| |  \_| ______|
-- the whitelist option should be enabled in case of repeted bans with the reason: 
-- Explosion Details: Type: %s, Position: %s, Damage Scale: %s
-- u will need to find the script causing the ban with a few steps ( TODO: this is only for now i will make it better in the future )
-- 	1. first find when the players are getting banned what explosions causes the ban
--  2. look for the resource that creates the explosion by finding its id or by the resource it self ( explosions ids can be found here: https://wiki.rage.mp/wiki/Explosions)
--  3. add the name of the resource u found to SecureServe.ExplosionsWhitelist with the following format:
SecureServe.ExplosionsWhitelist = {
    -- Add resource names here to whitelist them for explosion events
    ["resource_name_1"] = true,
    ["resource_name_2"] = true,
    -- Example: ["my_custom_resource"] = true,
}
-- in case u still are having issues disable the option by setting the option below to false:
SecureServe.ExplosionsModule = true



-- |       ______ _______ _______
-- |      |     | |  ____ |______
-- |_____ |_____| |_____| ______|

-- SecureServe Logs they are
SecureServe.OtherLogs = {
    JoinWebhook = "YOUR_WEBHOOK_URL", -- Logs when a player connects to the server, including their identifiers such as Steam ID, Discord ID, license, and IP address.
    LeaveWebhook = "YOUR_WEBHOOK_URL", -- Logs when a player disconnects from the server, including their name, Steam ID, Discord ID, and the reason for leaving.
    KillWebhook = "YOUR_WEBHOOK_URL", -- Logs player kills in the server. It records details about the attacker, victim, and possibly the weapon or method used.
    ResourceWebhook = "YOUR_WEBHOOK_URL" -- Logs resource-related events such as when a resource starts or stops on the server. Useful for monitoring the health and status of server resources.
}


-- _______ ______  _______ _____ __   _ _______
-- |_____| |     \ |  |  |   |   | \  | |______
-- |     | |_____/ |  |  | __|__ |  \_| ______|
-- DO NOT UNCOMMENT ANYTHING ABOVE THE FUNCTION!
-- Make Sure to add the resource that checks the perms as a dependency in the fxmanifest so it will work this option is only for custom cores there is already built in support for ESX QBCORE VRP QBOX TAZE and ACE PERMS 
-- Important use a callback this will run in the client in order to prevent errors
-- This make sures admins dosent get banned for nocliping godmode blips and such (it will be soon removed since im working on new better detections!)
-- Detections this admin can bypass: {
--  "Anti Player Blips",
--  "Anti Car Fly",
--  "Anti Noclip",
--  "Anti God Mode",
--  "Anti Spectate",
--  "Anti Freecam",
--  "Anti Night Vision",
--  "Anti Thermal Vision",
--  "Anti Infinite Stamina"
--  }
SecureServe.AdminFramework = "" -- set this to custom if u want to use the function below to set whitelist
SecureServe.IsWhitelisted = function(Player)
    --> [QB-Core] <--
    local QBCore = exports['qb-core']:GetCoreObject()
    if QBCore.Functions.HasPermission(Player, "admin") then
        return true
    end

    --> [ESX] <--
	-- local ESX = exports['es_extended']:getSharedObject()
    -- if ESX then
    --     local xPlayer = ESX.GetPlayerFromId(Player)
    --     if xPlayer then
    --         local group = xPlayer.getGroup()
    --         if group == 'admin' or group == 'mod' or group == 'superadmin' or group == 'god' then
    --             return true
	-- 		else
	-- 			return false
    --         end
    --     end
    -- end

    --> [vRP] <--
	-- local Tunnel = module("vrp", "lib/Tunnel")
	-- local Proxy = module("vrp", "lib/Proxy")
    -- local vRP = Proxy.getInterface("vRP")
    -- local user_id = vRP.getUserId({Player})
    -- if user_id and vRP.hasPermission({user_id, "admin"}) then
    --     return true
    -- else
    -- 	   return false
	-- end
end

-- Note Putting your steam or any id inside Admins { } will not give u whitelist meaning u will be banned the on that gives whitelist is SecureServe.IsWhitelisted
-- SecureServe.IsWhitelisted gives whitelist for specific and unchangeable detections meaning u cant give whitelist to a person for a specific detection
-- use /ssm to open admin panel (this admins are for admin panel only and not for protections)
SecureServe.AdminMenu = {
	Webhook = "", -- Webhook for the admin menu images
	Admins = { 
		-- Who can open the admin panel has nothing to do whit who gets banned or not! 
		-- You can use other staff and not just steam hex u can do more staff
		"license:licensehere",
		"discord:discordidhere",
	},
	CanOpenAdminPanel = function(Player) 
		-- [NOTE] this step is optinal and i recommend to usse steam/discord ids
		-- example use case optional in case u prefer to use ace perms or other methods
		-- add this to server.cfg 
		-- add_ace group.admin "adminpanel.access" allow

		-- local playerIdentifier = GetPlayerIdentifier(Player, 0)

		-- if IsPlayerAceAllowed(Player, "adminpanel.access") then
		-- 	return true
		-- else
		-- 	return false
		-- end
	end
}




-- _____   ______   _____  _______ _______ _______ _______ _____  _____  __   _
-- |_____] |_____/ |     |    |    |______ |          |      |   |     | | \  |
-- |       |    \_ |_____|    |    |______ |_____     |    __|__ |_____| |  \_|
SecureServe.BanTimes = { -- Preset ban times, preset name can be used in the protections.
	["Ban"] = 2147483647, -- Perm
	["Kick"] = -1,        -- Kick
	["Warn"] = 0,         -- Warn
}



SecureServe.Webhooks.Simple = ""
SecureServe.Protection.Simple = {     
	{ protection = "Anti Give Weapon",            time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player used excutor to spawn a weapon.                                                         
	{ protection = "Anti Player Blips",           time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player has player blips enabled.
	{ protection = "Anti Car Fly",                time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player uses car fly in the server
	{ protection = "Anti Particles",              time = "Ban", webhook = "",       enabled = true, limit = 5 },          -- Takes action if particles are spawning.
	{ protection = "Anti Damage Modifier",        time = "Ban", webhook = "",       enabled = true, default = 1.5, },     -- Takes action if weapon does more damage than it should.
	{ protection = "Anti Weapon Pickup",          time = "Ban", webhook = "",       enabled = true },                     -- Removes all weapons from the floor every couple of seconds.
	{ protection = "Anti Remove From Car",        time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player has been removed from the car.
	{ protection = "Anti Spectate",               time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player is spectating
	{ protection = "Anti Freecam",                time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player is using freecam
	{ protection = "Anti Explosion Bullet",       time = "Ban", webhook = "",       enabled = true },                     -- Takes action if weapon has explosive bullets
	{ protection = "Anti Night Vision",           time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player is using night vision.
	{ protection = "Anti Thermal Vision",         time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player is using thermal vision.
	{ protection = "Anti God Mode",               time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player has god mode.
	{ protection = "Anti Infinite Ammo",          time = "Ban", webhook = "",       enabled = true },                     -- Disables infinite ammo for the player every couple of seconds.
	{ protection = "Anti Teleport",               time = "Ban", webhook = "",       enabled = true },                     -- Takes action if the player teleported.
	{ protection = "Anti Invisible",              time = "Ban", webhook = "",       enabled = true },                     -- Takes action if the player is invisible
	{ protection = "Anti Resource Stopper",       time = "Ban", webhook = "",       enabled = true },                     -- Takes action if a resouce is stopped (Do not stop any resource if this feature is enabled).
	{ protection = "Anti Resource Starter",       time = "Ban", webhook = "",       enabled = true },                     -- Takes action if a resouce is started (Do not start any resource if this feature is enabled).
	{ protection = "Anti Vehicle God Mode",       time = "Ban", webhook = "",       enabled = true },                     -- Takes action if vehicle has god mode.
	{ protection = "Anti Vehicle Power Increase", time = "Ban", webhook = "",       enabled = true },                     -- Takes action if torque power changed.
	{ protection = "Anti Speed Hack",             time = "Ban", webhook = "",       enabled = true, defaultr = 8, defaults = 4.5, }, -- Takes action if a vehicle is using speedhack.
	{ protection = "Anti Plate Changer",          time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player changed his plate.
	{ protection = "Anti Cheat Engine",           time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player stopped values from changing (Expiremental).
	{ protection = "Anti Rage",                   time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player killed someone that is not on their screen.
	{ protection = "Anti Aim Assist",             time = "Ban", webhook = "",       enabled = true },                     -- Disables aim assist for the player every millisecond.
	{ protection = "Anti Kill All",               time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player tried to kill everyone.
	{ protection = "Anti Solo Session",           time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player is in solo session.
	{ protection = "Anti AI",                     time = "Ban", webhook = "",       enabled = true, default = 1.5, },     -- Takes action if player has modified his ai files (Expiremental).
	{ protection = "Anti No Reload",              time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player uses no reload.
	{ protection = "Anti Rapid Fire",             time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player has modified his fire rate .
	{ protection = "Anti Bigger Hitbox",          time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player has bigger hitbox.
	{ protection = "Anti No Recoil",              time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player has no recoil on.
	{ protection = "Anti State Bag Overflow",     time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player has modified his state bag (Expiremental).
	{ protection = "Anti Extended NUI Devtools",  time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player opened dev tools and extends the anti-cheat (Expiremental).
	{ protection = "Anti No Ragdoll",             time = "Ban", webhook = "",       enabled = true },                     -- Takes action if a disabled ragdolls.
	{ protection = "Anti Super Jump",             time = "Ban", webhook = "",       enabled = true },                     -- Takes action if a player is super jumping.
	{ protection = "Anti Noclip",                 time = "Ban", webhook = "",       enabled = true },                     -- Takes action if a player is using noclip.
	{ protection = "Anti Infinite Stamina",       time = "Ban", webhook = "",       enabled = true },                     -- Takes action if a has infinite stamina.
	{ protection = "Anti Play Sound",             time = "Ban", webhook = "",       enabled = true },                     -- Disables Sound Routing Event
	{ protection = "Anti AFK Injection",          time = "Ban", webhook = "",       enabled = true },                     -- Takes action if player uses afk injection usally used while dumping
	{ protection = "Anti Car Ram",                time = "Ban", webhook = "",       enabled = false },                    -- Takes action if player tries to ram player with a mod menu
	{ protection = "Anti Magic Bullet",           time = "Ban", webhook = "",       enabled = true, tolerance = 3 },      -- If the player kills more than the number of times you set and does not see it, they will be banned from the server
}

SecureServe.Webhooks.AntiInternal = ""
SecureServe.AntiInternal = { -- this will protect your server from cheaters when cheater will open any cheat RedEngine Skript GG Eulen after sometime in menu he will be banned
	{ detection = "Anti RedEngine", punishType = "Ban", enabled = true,  webhook = "" },
	{ detection = "Anti Internal",  punishType = "Ban", enabled = false,  webhook = "" }, -- it is also anti external may false ban but hgihly recommended
	{ detection = "Destroy Input",  punishType = "Ban", enabled = true, webhook = "" }
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
	"Butan Premium", "RAIDEN", "Give All Weapons", "Miscellaneous", "World Menu", "Sex Adanc", "Tapatio®"
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
    { id = 6, time = "Ban",  webhook = "", limit = 2, audio = true, scale = 1.0, invisible = false }, -- Hi Octane
    { id = 7, time = "Ban",  webhook = "", limit = 2, audio = true, scale = 1.0, invisible = false }, -- Car Explosions
    { id = 18, time = "Ban", webhook = "", limit = 12, audio = true, scale = 1.0, invisible = false }, -- Bullet Explosions
    { id = 19, time = "Ban", webhook = "", limit = 12, audio = true, scale = 1.0, invisible = false }, -- Smoke Grenade Launcher
    { id = 20, time = "Ban", webhook = "", limit = 5, audio = true, scale = 1.0, invisible = false }, -- Smoke Grenades
    { id = 21, time = "Ban", webhook = "", limit = 5, audio = true, scale = 1.0, invisible = false }, -- BZ Gas
    { id = 22, time = "Ban", webhook = "", limit = 5, audio = true, scale = 1.0, invisible = false }, -- Flares
    { id = 25, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Programmable AR
    { id = 36, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Railgun
    { id = 37, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Blimp 2
    { id = 38, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Fireworks
    { id = 40, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Proximity Mines
    { id = 43, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Pipe Bombs
    { id = 44, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Vehicle Mines
    { id = 45, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Explosive Ammo
    { id = 46, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- APC Shells
    { id = 47, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Cluster Bombs
    { id = 48, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Gas Bombs
    { id = 49, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Incendiary Bombs
    { id = 50, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Standard Bombs
    { id = 51, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Torpedoes
    { id = 52, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Underwater Torpedoes
    { id = 53, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Bombushka Cannon
    { id = 54, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Cluster Bomb Secondary Explosions
    { id = 55, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Hunter Barrage
    { id = 56, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Hunter Cannon
    { id = 57, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Rogue Cannon
    { id = 58, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Underwater Mines
    { id = 59, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Orbital Cannon
    { id = 60, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Wide Standard Bombs
    { id = 61, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Explosive Shotgun Ammo
    { id = 62, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Oppressor 2 Cannon
    { id = 63, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Kinetic Mortar
    { id = 64, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Kinetic Vehicle Mine
    { id = 65, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- EMP Vehicle Mine
    { id = 66, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Spike Vehicle Mine
    { id = 67, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Slick Vehicle Mine
    { id = 68, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Tar Vehicle Mine
    { id = 69, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Script Drone
    { id = 70, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Raygun
	{ id = 71, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Buried Mine
	{ id = 72, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Script Missle
	{ id = 82, time = "Ban", webhook = "", limit = 1, audio = true, scale = 1.0, invisible = false }, -- Submarine
}

SecureServe.Webhooks.BlacklistedCommands = ""
SecureServe.Protection.BlacklistedCommands = { -- Takes action if a blacklisted command is registered.
	{ command = "jd",                        time = "Ban", webhook = "" },
	{ command = "KP",                        time = "Ban", webhook = "" },
	{ command = "opk",                       time = "Ban", webhook = "" },
	{ command = "ham",                       time = "Ban", webhook = "" },
	{ command = "lol",                       time = "Ban", webhook = "" },
	{ command = "hoax",                      time = "Ban", webhook = "" },
	{ command = "vibes",                     time = "Ban", webhook = "" },
	{ command = "haha",                      time = "Ban", webhook = "" },
	{ command = "panik",                     time = "Ban", webhook = "" },
	{ command = "brutan",                    time = "Ban", webhook = "" },
	{ command = "panic",                     time = "Ban", webhook = "" },
	{ command = "hyra",                      time = "Ban", webhook = "" },
	{ command = "hydro",                     time = "Ban", webhook = "" },
	{ command = "lynx",                      time = "Ban", webhook = "" },
	{ command = "tiago",                     time = "Ban", webhook = "" },
	{ command = "desudo",                    time = "Ban", webhook = "" },
	{ command = "ssssss",                    time = "Ban", webhook = "" },
	{ command = "redstonia",                 time = "Ban", webhook = "" },
	{ command = "dopamine",                  time = "Ban", webhook = "" },
	{ command = "dopamina",                  time = "Ban", webhook = "" },
	{ command = "purgemenu",                 time = "Ban", webhook = "" },
	{ command = "WarMenu",                   time = "Ban", webhook = "" },
	{ command = "lynx9_fixed",               time = "Ban", webhook = "" },
	{ command = "injected",                  time = "Ban", webhook = "" },
	{ command = "hammafia",                  time = "Ban", webhook = "" },
	{ command = "hamhaxia",                  time = "Ban", webhook = "" },
	{ command = "chocolate",                 time = "Ban", webhook = "" },
	{ command = "Information",               time = "Ban", webhook = "" },
	{ command = "Maestro",                   time = "Ban", webhook = "" },
	{ command = "FunCtionOk",                time = "Ban", webhook = "" },
	{ command = "TiagoModz",                 time = "Ban", webhook = "" },
	{ command = "jolmany",                   time = "Ban", webhook = "" },
	{ command = "SovietH4X",                 time = "Ban", webhook = "" },
	{ command = "killmenu",                  time = "Ban", webhook = "" },
	{ command = "panickey",                  time = "Ban", webhook = "" },
	{ command = "d0pamine",                  time = "Ban", webhook = "" },
	{ command = "[dopamine]",                time = "Ban", webhook = "" },
	{ command = "brutanpremium",             time = "Ban", webhook = "" },
	{ command = "www.d0pamine.xyz",          time = "Ban", webhook = "" },
	{ command = "d0pamine v1.1 by Nertigel", time = "Ban", webhook = "" },
	{ command = "TiagoModz#1478",            time = "Ban", webhook = "" },
}

SecureServe.Webhooks.BlacklistedSprites = ""
SecureServe.Protection.BlacklistedSprites = { -- Takes action if a blacklisted sprite is detected.
	{ sprite = "deadline",           name = "Dopamine",            time = "Ban", webhook = "" },
	{ sprite = "Dopameme",           name = "Dopamine Menu",       time = "Ban", webhook = "" },
	{ sprite = "dopamine",           name = "Dopamine Menu",       time = "Ban", webhook = "" },
	{ sprite = "dopamemes",          name = "Dopameme Menu",       time = "Ban", webhook = "" },
	{ sprite = "wm2",                name = "WM Menu",             time = "Ban", webhook = "" },
	{ sprite = "KentasCheckboxDict", name = "Kentas Menu Synapse", time = "Ban", webhook = "" },
	{ sprite = "KentasMenu",         name = "Kentas Menu Synapse", time = "Ban", webhook = "" },
	{ sprite = "HydroMenuHeader",    name = "HydroMenu",           time = "Ban", webhook = "" },
	{ sprite = "godmenu",            name = "God Menu",            time = "Ban", webhook = "" },
	{ sprite = "redrum",             name = "Redrum Menu",         time = "Ban", webhook = "" },
	{ sprite = "beautiful",          name = "Beautiful Menu",      time = "Ban", webhook = "" },
	{ sprite = "Absolut",            name = "Absolute Menu",       time = "Ban", webhook = "" },
	{ sprite = "hoaxmenu",           name = "Hoax Menu",           time = "Ban", webhook = "" },
	{ sprite = "fendin",             name = "Fendinx Menu",        time = "Ban", webhook = "" },
	{ sprite = "Ham",                name = "Ham Menu",            time = "Ban", webhook = "" },
	{ sprite = "hammafia",           name = "Ham Mafia Menu",      time = "Ban", webhook = "" },
	{ sprite = "Fallout",            name = "Fallout",             time = "Ban", webhook = "" },
	{ sprite = "menu_bg",            name = "Fallout Menu",        time = "Ban", webhook = "" },
	{ sprite = "DefaultMenu",        name = "Default Menu",        time = "Ban", webhook = "" },
	{ sprite = "ISMMENUHeader",      name = "ISMMENU",             time = "Ban", webhook = "" },
	{ sprite = "fivesense",          name = "Fivesense Menu",      time = "Ban", webhook = "" },
	{ sprite = "maestro",            name = "Maestro Menu",        time = "Ban", webhook = "" },
	{ sprite = "kekhack",            name = "KekHack Menu",        time = "Ban", webhook = "" },
	{ sprite = "trolling",           name = "Trolling Menu",       time = "Ban", webhook = "" },
	{ sprite = "mm",                 name = "MM Menu",             time = "Ban", webhook = "" },
	{ sprite = "MmPremium",          name = "MM Premium Menu",     time = "Ban", webhook = "" },
	{ sprite = "Fallout",            name = "Fallout",             time = "Ban", webhook = "" },
	{ sprite = "dopatest",           name = "Dopa Menu",           time = "Ban", webhook = "" },
	{ sprite = "deadline",           name = "Dopamine",            time = "Ban", webhook = "" },
	{ sprite = "dopamine",           name = "Dopamine Menu",       time = "Ban", webhook = "" },
	{ sprite = "cat",                name = "Cat Menu",            time = "Ban", webhook = "" },
	{ sprite = "John2",              name = "SugarMenu",           time = "Ban", webhook = "" },
	{ sprite = "bartowmenu",         name = "Bartow Menu",         time = "Ban", webhook = "" },
	{ sprite = "duiTex",             name = "Copypaste Menu",      time = "Ban", webhook = "" },
	{ sprite = "Mafins",             name = "Mafins Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER24__",       name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER5__",        name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER7__",        name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER8__",        name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER10__",       name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER3__",        name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER2__",        name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER1__",        name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER23__",       name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "__REAPER17__",       name = "Repear Menu",         time = "Ban", webhook = "" },
	{ sprite = "skidmenu",           name = "Skid Menu",           time = "Ban", webhook = "" },
	{ sprite = "skidmenu",           name = "Skid Menu",           time = "Ban", webhook = "" },
	{ sprite = "Urubu3",             name = "Urubu Menu",          time = "Ban", webhook = "" },
	{ sprite = "Urubu",              name = "Urubu Menu",          time = "Ban", webhook = "" },
	{ sprite = "love",               name = "Love Menu",           time = "Ban", webhook = "" },
	{ sprite = "brutan",             name = "Brutan Menu",         time = "Ban", webhook = "" },
	{ sprite = "auttaja",            name = "Auttaja Menu",        time = "Ban", webhook = "" },
	{ sprite = "oblivious",          name = "Oblivious Menu",      time = "Ban", webhook = "" },
	{ sprite = "malossimenu",        name = "Malossi Menu",        time = "Ban", webhook = "" },
	{ sprite = "Memeeee",            name = "Memeeee Menu",        time = "Ban", webhook = "" },
	{ sprite = "Tiago",              name = "Tiago Menu",          time = "Ban", webhook = "" },
	{ sprite = "fantasy",            name = "Fantasy Menu",        time = "Ban", webhook = "" },
	{ sprite = "Vagos",              name = "Vagos Menu",          time = "Ban", webhook = "" },
	{ sprite = "simplicity",         name = "Simplicity Menu",     time = "Ban", webhook = "" },
	{ sprite = "WarMenu",            name = "War Menu",            time = "Ban", webhook = "" },
	{ sprite = "Darkside",           name = "Darkside Menu",       time = "Ban", webhook = "" },
	{ sprite = "antario",            name = "Antario Menu",        time = "Ban", webhook = "" },
	{ sprite = "kingpin",            name = "Kingpin Menu",        time = "Ban", webhook = "" },
	{ sprite = "Wave (alt.)",        name = "Wave (alt.)",         time = "Ban", webhook = "" },
	{ sprite = "Wave",               name = "Wave",                time = "Ban", webhook = "" },
	{ sprite = "Alokas66",           name = "Alokas66",            time = "Ban", webhook = "" },
	{ sprite = "Guest Menu",         name = "Guest Menu",          time = "Ban", webhook = "" },
}

SecureServe.Webhooks.BlacklistedAnimDicts = ""
SecureServe.Protection.BlacklistedAnimDicts = { -- Takes action if a blacklisted anim dict got loaded.
	{ dict = "rcmjosh2",       time = "Ban", webhook = "" },
	{ dict = "rcmpaparazzo_2", time = "Ban", webhook = "" },
}

SecureServe.Webhooks.BlacklistedWeapons = ""
SecureServe.Protection.BlacklistedWeapons = { -- Weapons Names can be found here: https://gtahash.ru/weapons/
	{ name = "weapon_rayminigun",      time = "Ban", webhook = "" },
	{ name = "weapon_raycarbine",      time = "Ban", webhook = "" },
	{ name = "weapon_rpg",             time = "Ban", webhook = "" },
	{ name = "weapon_grenadelauncher", time = "Ban", webhook = "" },
	{ name = "weapon_minigun",         time = "Ban", webhook = "" },
	{ name = "weapon_railgun",         time = "Ban", webhook = "" },
	{ name = "weapon_firework",        time = "Ban", webhook = "" },
	{ name = "weapon_hominglauncher",  time = "Ban", webhook = "" },
	{ name = "weapon_compactlauncher", time = "Ban", webhook = "" },
}

SecureServe.Webhooks.BlacklistedVehicles = ""
SecureServe.Protection.BlacklistedVehicles = { -- Vehicles List can be found here: https://wiki.rage.mp/index.php?title=Vehicles
	{ name = "dinghy5",       time = "Ban", webhook = "" },
	{ name = "kosatka",       time = "Ban", webhook = "" },
	{ name = "patrolboat",    time = "Ban", webhook = "" },
	{ name = "cerberus",      time = "Ban", webhook = "" },
	{ name = "cerberus2",     time = "Ban", webhook = "" },
	{ name = "cerberus3",     time = "Ban", webhook = "" },
	{ name = "phantom2",      time = "Ban", webhook = "" },
	{ name = "akula",         time = "Ban", webhook = "" },
	{ name = "annihilator",   time = "Ban", webhook = "" },
	{ name = "buzzard",       time = "Ban", webhook = "" },
	{ name = "savage",        time = "Ban", webhook = "" },
	{ name = "annihilator2",  time = "Ban", webhook = "" },
	{ name = "cutter",        time = "Ban", webhook = "" },
	{ name = "apc",           time = "Ban", webhook = "" },
	{ name = "barrage",       time = "Ban", webhook = "" },
	{ name = "chernobog",     time = "Ban", webhook = "" },
	{ name = "halftrack",     time = "Ban", webhook = "" },
	{ name = "khanjali",      time = "Ban", webhook = "" },
	{ name = "minitank",      time = "Ban", webhook = "" },
	{ name = "rhino",         time = "Ban", webhook = "" },
	{ name = "thruster",      time = "Ban", webhook = "" },
	{ name = "trailersmall2", time = "Ban", webhook = "" },
	{ name = "oppressor",     time = "Ban", webhook = "" },
	{ name = "oppressor2",    time = "Ban", webhook = "" },
	{ name = "dukes2",        time = "Ban", webhook = "" },
	{ name = "ruiner2",       time = "Ban", webhook = "" },
	{ name = "dune3",         time = "Ban", webhook = "" },
	{ name = "dune4",         time = "Ban", webhook = "" },
	{ name = "dune5",         time = "Ban", webhook = "" },
	{ name = "insurgent",     time = "Ban", webhook = "" },
	{ name = "insurgent3",    time = "Ban", webhook = "" },
	{ name = "menacer",       time = "Ban", webhook = "" },
	{ name = "rcbandito",     time = "Ban", webhook = "" },
	{ name = "technical3",    time = "Ban", webhook = "" },
	{ name = "technical2",    time = "Ban", webhook = "" },
	{ name = "technical",     time = "Ban", webhook = "" },
	{ name = "avenger",       time = "Ban", webhook = "" },
	{ name = "avenger2",      time = "Ban", webhook = "" },
	{ name = "bombushka",     time = "Ban", webhook = "" },
	{ name = "cargoplane",    time = "Ban", webhook = "" },
	{ name = "cargoplane2",   time = "Ban", webhook = "" },
	{ name = "hydra",         time = "Ban", webhook = "" },
	{ name = "lazer",         time = "Ban", webhook = "" },
	{ name = "molotok",       time = "Ban", webhook = "" },
	{ name = "nokota",        time = "Ban", webhook = "" },
	{ name = "pyro",          time = "Ban", webhook = "" },
	{ name = "rogue",         time = "Ban", webhook = "" },
	{ name = "starling",      time = "Ban", webhook = "" },
	{ name = "strikeforce",   time = "Ban", webhook = "" },
	{ name = "limo2",         time = "Ban", webhook = "" },
	{ name = "scramjet",      time = "Ban", webhook = "" },
	{ name = "vigilante",     time = "Ban", webhook = "" },
}

SecureServe.Webhooks.BlacklistedObjects = ""
SecureServe.Protection.BlacklistedObjects = {
	{ name = "prop_logpile_07b",                                               webhook = "" },
	{ name = "prop_logpile_07",                                                webhook = "" },
	{ name = "prop_logpile_06b",                                               webhook = "" },
	{ name = "prop_logpile_06",                                                webhook = "" },
	{ name = "prop_logpile_05",                                                webhook = "" },
	{ name = "prop_logpile_04",                                                webhook = "" },
	{ name = "prop_logpile_03",                                                webhook = "" },
	{ name = "prop_logpile_02",                                                webhook = "" },
	{ name = "prop_logpile_01",                                                webhook = "" },
	{ name = "hei_prop_carrier_radar_1_l1",                                    webhook = "" },
	{ name = "v_res_mexball",                                                  webhook = "" },
	{ name = "prop_rock_1_a",                                                  webhook = "" },
	{ name = "prop_rock_1_b",                                                  webhook = "" },
	{ name = "prop_rock_1_c",                                                  webhook = "" },
	{ name = "prop_rock_1_d",                                                  webhook = "" },
	{ name = "prop_player_gasmask",                                            webhook = "" },
	{ name = "prop_rock_1_e",                                                  webhook = "" },
	{ name = "prop_rock_1_f",                                                  webhook = "" },
	{ name = "prop_rock_1_g",                                                  webhook = "" },
	{ name = "prop_rock_1_h",                                                  webhook = "" },
	{ name = "prop_test_boulder_01",                                           webhook = "" },
	{ name = "prop_test_boulder_02",                                           webhook = "" },
	{ name = "prop_test_boulder_03",                                           webhook = "" },
	{ name = "prop_test_boulder_04",                                           webhook = "" },
	{ name = "apa_mp_apa_crashed_usaf_01a",                                    webhook = "" },
	{ name = "ex_prop_exec_crashdp",                                           webhook = "" },
	{ name = "apa_mp_apa_yacht_o1_rail_a",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_o1_rail_b",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_armchair_01",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_armchair_03",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_armchair_04",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_barstool_01",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_bed_01",                                          webhook = "" },
	{ name = "apa_mp_h_yacht_bed_02",                                          webhook = "" },
	{ name = "apa_mp_h_yacht_coffee_table_01",                                 webhook = "" },
	{ name = "apa_mp_h_yacht_coffee_table_02",                                 webhook = "" },
	{ name = "apa_mp_h_yacht_floor_lamp_01",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_side_table_01",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_side_table_02",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_sofa_01",                                         webhook = "" },
	{ name = "apa_mp_h_yacht_sofa_02",                                         webhook = "" },
	{ name = "apa_mp_h_yacht_stool_01",                                        webhook = "" },
	{ name = "apa_mp_h_yacht_strip_chair_01",                                  webhook = "" },
	{ name = "apa_mp_h_yacht_table_lamp_01",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_table_lamp_02",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_table_lamp_03",                                   webhook = "" },
	{ name = "prop_flag_columbia",                                             webhook = "" },
	{ name = "apa_mp_apa_yacht_o2_rail_a",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_o2_rail_b",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_o3_rail_a",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_o3_rail_b",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_option1",                                       webhook = "" },
	{ name = "proc_searock_01",                                                webhook = "" },
	{ name = "apa_mp_h_yacht_",                                                webhook = "" },
	{ name = "apa_mp_apa_yacht_option1_cola",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option2",                                       webhook = "" },
	{ name = "apa_mp_apa_yacht_option2_cola",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option2_colb",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3",                                       webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_cola",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_colb",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_colc",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_cold",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_cole",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_jacuzzi_cam",                                   webhook = "" },
	{ name = "apa_mp_apa_yacht_jacuzzi_ripple003",                             webhook = "" },
	{ name = "apa_mp_apa_yacht_jacuzzi_ripple1",                               webhook = "" },
	{ name = "apa_mp_apa_yacht_jacuzzi_ripple2",                               webhook = "" },
	{ name = "apa_mp_apa_yacht_radar_01a",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_win",                                           webhook = "" },
	{ name = "prop_crashed_heli",                                              webhook = "" },
	{ name = "apa_mp_apa_yacht_door",                                          webhook = "" },
	{ name = "prop_shamal_crash",                                              webhook = "" },
	{ name = "xm_prop_x17_shamal_crash",                                       webhook = "" },
	{ name = "apa_mp_apa_yacht_door2",                                         webhook = "" },
	{ name = "apa_mp_apa_yacht",                                               webhook = "" },
	{ name = "prop_flagpole_2b",                                               webhook = "" },
	{ name = "prop_flagpole_2c",                                               webhook = "" },
	{ name = "prop_flag_canada",                                               webhook = "" },
	{ name = "apa_prop_yacht_float_1a",                                        webhook = "" },
	{ name = "apa_prop_yacht_float_1b",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_01",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_02",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_03",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_04",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_05",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_06",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_07",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_08",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_09",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_10",                                        webhook = "" },
	{ name = "prop_flag_canada_s",                                             webhook = "" },
	{ name = "prop_flag_eu",                                                   webhook = "" },
	{ name = "prop_flag_eu_s",                                                 webhook = "" },
	{ name = "prop_target_blue_arrow",                                         webhook = "" },
	{ name = "prop_target_orange_arrow",                                       webhook = "" },
	{ name = "prop_target_purp_arrow",                                         webhook = "" },
	{ name = "prop_target_red_arrow",                                          webhook = "" },
	{ name = "apa_prop_flag_argentina",                                        webhook = "" },
	{ name = "apa_prop_flag_australia",                                        webhook = "" },
	{ name = "apa_prop_flag_austria",                                          webhook = "" },
	{ name = "apa_prop_flag_belgium",                                          webhook = "" },
	{ name = "apa_prop_flag_brazil",                                           webhook = "" },
	{ name = "apa_prop_flag_canadat_yt",                                       webhook = "" },
	{ name = "apa_prop_flag_china",                                            webhook = "" },
	{ name = "apa_prop_flag_columbia",                                         webhook = "" },
	{ name = "apa_prop_flag_croatia",                                          webhook = "" },
	{ name = "apa_prop_flag_czechrep",                                         webhook = "" },
	{ name = "apa_prop_flag_denmark",                                          webhook = "" },
	{ name = "apa_prop_flag_england",                                          webhook = "" },
	{ name = "apa_prop_flag_eu_yt",                                            webhook = "" },
	{ name = "apa_prop_flag_finland",                                          webhook = "" },
	{ name = "apa_prop_flag_france",                                           webhook = "" },
	{ name = "apa_prop_flag_german_yt",                                        webhook = "" },
	{ name = "apa_prop_flag_hungary",                                          webhook = "" },
	{ name = "apa_prop_flag_ireland",                                          webhook = "" },
	{ name = "apa_prop_flag_israel",                                           webhook = "" },
	{ name = "apa_prop_flag_italy",                                            webhook = "" },
	{ name = "apa_prop_flag_jamaica",                                          webhook = "" },
	{ name = "apa_prop_flag_japan_yt",                                         webhook = "" },
	{ name = "apa_prop_flag_canada_yt",                                        webhook = "" },
	{ name = "apa_prop_flag_lstein",                                           webhook = "" },
	{ name = "apa_prop_flag_malta",                                            webhook = "" },
	{ name = "apa_prop_flag_mexico_yt",                                        webhook = "" },
	{ name = "apa_prop_flag_netherlands",                                      webhook = "" },
	{ name = "apa_prop_flag_newzealand",                                       webhook = "" },
	{ name = "apa_prop_flag_nigeria",                                          webhook = "" },
	{ name = "apa_prop_flag_norway",                                           webhook = "" },
	{ name = "apa_prop_flag_palestine",                                        webhook = "" },
	{ name = "apa_prop_flag_poland",                                           webhook = "" },
	{ name = "apa_prop_flag_portugal",                                         webhook = "" },
	{ name = "apa_prop_flag_puertorico",                                       webhook = "" },
	{ name = "apa_prop_flag_russia_yt",                                        webhook = "" },
	{ name = "apa_prop_flag_scotland_yt",                                      webhook = "" },
	{ name = "apa_prop_flag_script",                                           webhook = "" },
	{ name = "apa_prop_flag_slovakia",                                         webhook = "" },
	{ name = "apa_prop_flag_slovenia",                                         webhook = "" },
	{ name = "apa_prop_flag_southafrica",                                      webhook = "" },
	{ name = "apa_prop_flag_southkorea",                                       webhook = "" },
	{ name = "apa_prop_flag_spain",                                            webhook = "" },
	{ name = "apa_prop_flag_sweden",                                           webhook = "" },
	{ name = "apa_prop_flag_switzerland",                                      webhook = "" },
	{ name = "apa_prop_flag_turkey",                                           webhook = "" },
	{ name = "apa_prop_flag_uk_yt",                                            webhook = "" },
	{ name = "apa_prop_flag_us_yt",                                            webhook = "" },
	{ name = "apa_prop_flag_wales",                                            webhook = "" },
	{ name = "prop_flag_uk",                                                   webhook = "" },
	{ name = "prop_flag_uk_s",                                                 webhook = "" },
	{ name = "prop_flag_us",                                                   webhook = "" },
	{ name = "prop_flag_usboat",                                               webhook = "" },
	{ name = "prop_flag_us_r",                                                 webhook = "" },
	{ name = "prop_flag_us_s",                                                 webhook = "" },
	{ name = "prop_flag_france",                                               webhook = "" },
	{ name = "prop_flag_france_s",                                             webhook = "" },
	{ name = "prop_flag_german",                                               webhook = "" },
	{ name = "prop_flag_german_s",                                             webhook = "" },
	{ name = "prop_flag_ireland",                                              webhook = "" },
	{ name = "prop_flag_ireland_s",                                            webhook = "" },
	{ name = "prop_flag_japan",                                                webhook = "" },
	{ name = "prop_flag_japan_s",                                              webhook = "" },
	{ name = "prop_flag_ls",                                                   webhook = "" },
	{ name = "prop_flag_lsfd",                                                 webhook = "" },
	{ name = "prop_flag_lsfd_s",                                               webhook = "" },
	{ name = "prop_flag_lsservices",                                           webhook = "" },
	{ name = "prop_flag_lsservices_s",                                         webhook = "" },
	{ name = "prop_flag_ls_s",                                                 webhook = "" },
	{ name = "prop_flag_mexico",                                               webhook = "" },
	{ name = "prop_flag_mexico_s",                                             webhook = "" },
	{ name = "prop_flag_russia",                                               webhook = "" },
	{ name = "prop_flag_russia_s",                                             webhook = "" },
	{ name = "prop_flag_s",                                                    webhook = "" },
	{ name = "prop_flag_sa",                                                   webhook = "" },
	{ name = "prop_flag_sapd",                                                 webhook = "" },
	{ name = "prop_flag_sapd_s",                                               webhook = "" },
	{ name = "prop_flag_sa_s",                                                 webhook = "" },
	{ name = "prop_flag_scotland",                                             webhook = "" },
	{ name = "prop_flag_scotland_s",                                           webhook = "" },
	{ name = "prop_flag_sheriff",                                              webhook = "" },
	{ name = "prop_flag_sheriff_s",                                            webhook = "" },
	{ name = "prop_flag_uk",                                                   webhook = "" },
	{ name = "prop_flag_uk_s",                                                 webhook = "" },
	{ name = "prop_flag_us",                                                   webhook = "" },
	{ name = "prop_flag_usboat",                                               webhook = "" },
	{ name = "prop_flag_us_r",                                                 webhook = "" },
	{ name = "prop_flag_us_s",                                                 webhook = "" },
	{ name = "prop_flamingo",                                                  webhook = "" },
	{ name = "prop_swiss_ball_01",                                             webhook = "" },
	{ name = "prop_air_bigradar_l1",                                           webhook = "" },
	{ name = "prop_air_bigradar_l2",                                           webhook = "" },
	{ name = "prop_air_bigradar_slod",                                         webhook = "" },
	{ name = "p_fib_rubble_s",                                                 webhook = "" },
	{ name = "prop_money_bag_01",                                              webhook = "" },
	{ name = "p_cs_mp_jet_01_s",                                               webhook = "" },
	{ name = "prop_poly_bag_money",                                            webhook = "" },
	{ name = "prop_air_radar_01",                                              webhook = "" },
	{ name = "hei_prop_carrier_radar_1",                                       webhook = "" },
	{ name = "prop_air_bigradar",                                              webhook = "" },
	{ name = "prop_carrier_radar_1_l1",                                        webhook = "" },
	{ name = "prop_asteroid_01",                                               webhook = "" },
	{ name = "prop_xmas_ext",                                                  webhook = "" },
	{ name = "p_oil_pjack_01_amo",                                             webhook = "" },
	{ name = "p_oil_pjack_01_s",                                               webhook = "" },
	{ name = "p_oil_pjack_02_amo",                                             webhook = "" },
	{ name = "p_oil_pjack_03_amo",                                             webhook = "" },
	{ name = "p_oil_pjack_02_s",                                               webhook = "" },
	{ name = "p_oil_pjack_03_s",                                               webhook = "" },
	{ name = "prop_aircon_l_03",                                               webhook = "" },
	{ name = "prop_med_jet_01",                                                webhook = "" },
	{ name = "p_med_jet_01_s",                                                 webhook = "" },
	{ name = "hei_prop_carrier_jet",                                           webhook = "" },
	{ name = "bkr_prop_biker_bblock_huge_01",                                  webhook = "" },
	{ name = "bkr_prop_biker_bblock_huge_02",                                  webhook = "" },
	{ name = "bkr_prop_biker_bblock_huge_04",                                  webhook = "" },
	{ name = "bkr_prop_biker_bblock_huge_05",                                  webhook = "" },
	{ name = "hei_prop_heist_emp",                                             webhook = "" },
	{ name = "prop_weed_01",                                                   webhook = "" },
	{ name = "prop_air_bigradar",                                              webhook = "" },
	{ name = "prop_juicestand",                                                webhook = "" },
	{ name = "prop_lev_des_barge_02",                                          webhook = "" },
	{ name = "hei_prop_carrier_defense_01",                                    webhook = "" },
	{ name = "prop_aircon_m_04",                                               webhook = "" },
	{ name = "prop_mp_ramp_03",                                                webhook = "" },
	{ name = "stt_prop_stunt_track_dwuturn",                                   webhook = "" },
	{ name = "ch3_12_animplane1_lod",                                          webhook = "" },
	{ name = "ch3_12_animplane2_lod",                                          webhook = "" },
	{ name = "hei_prop_hei_pic_pb_plane",                                      webhook = "" },
	{ name = "light_plane_rig",                                                webhook = "" },
	{ name = "prop_cs_plane_int_01",                                           webhook = "" },
	{ name = "prop_dummy_plane",                                               webhook = "" },
	{ name = "prop_mk_plane",                                                  webhook = "" },
	{ name = "v_44_planeticket",                                               webhook = "" },
	{ name = "prop_planer_01",                                                 webhook = "" },
	{ name = "ch3_03_cliffrocks03b_lod",                                       webhook = "" },
	{ name = "ch3_04_rock_lod_02",                                             webhook = "" },
	{ name = "csx_coastsmalrock_01_",                                          webhook = "" },
	{ name = "csx_coastsmalrock_02_",                                          webhook = "" },
	{ name = "csx_coastsmalrock_03_",                                          webhook = "" },
	{ name = "csx_coastsmalrock_04_",                                          webhook = "" },
	{ name = "mp_player_introck",                                              webhook = "" },
	{ name = "Heist_Yacht",                                                    webhook = "" },
	{ name = "csx_coastsmalrock_05_",                                          webhook = "" },
	{ name = "mp_player_int_rock",                                             webhook = "" },
	{ name = "mp_player_introck",                                              webhook = "" },
	{ name = "prop_flagpole_1a",                                               webhook = "" },
	{ name = "prop_flagpole_2a",                                               webhook = "" },
	{ name = "prop_flagpole_3a",                                               webhook = "" },
	{ name = "prop_a4_pile_01",                                                webhook = "" },
	{ name = "cs2_10_sea_rocks_lod",                                           webhook = "" },
	{ name = "cs2_11_sea_marina_xr_rocks_03_lod",                              webhook = "" },
	{ name = "prop_gold_cont_01",                                              webhook = "" },
	{ name = "prop_hydro_platform",                                            webhook = "" },
	{ name = "ch3_04_viewplatform_slod",                                       webhook = "" },
	{ name = "ch2_03c_rnchstones_lod",                                         webhook = "" },
	{ name = "proc_mntn_stone01",                                              webhook = "" },
	{ name = "prop_beachflag_le",                                              webhook = "" },
	{ name = "proc_mntn_stone02",                                              webhook = "" },
	{ name = "cs2_10_sea_shipwreck_lod",                                       webhook = "" },
	{ name = "des_shipsink_02",                                                webhook = "" },
	{ name = "prop_dock_shippad",                                              webhook = "" },
	{ name = "des_shipsink_03",                                                webhook = "" },
	{ name = "des_shipsink_04",                                                webhook = "" },
	{ name = "prop_mk_flag",                                                   webhook = "" },
	{ name = "prop_mk_flag_2",                                                 webhook = "" },
	{ name = "proc_mntn_stone03",                                              webhook = "" },
	{ name = "FreeModeMale01",                                                 webhook = "" },
	{ name = "rsn_os_specialfloatymetal_n",                                    webhook = "" },
	{ name = "rsn_os_specialfloatymetal",                                      webhook = "" },
	{ name = "cs1_09_sea_ufo",                                                 webhook = "" },
	{ name = "rsn_os_specialfloaty2_light2",                                   webhook = "" },
	{ name = "rsn_os_specialfloaty2_light",                                    webhook = "" },
	{ name = "rsn_os_specialfloaty2",                                          webhook = "" },
	{ name = "rsn_os_specialfloatymetal_n",                                    webhook = "" },
	{ name = "rsn_os_specialfloatymetal",                                      webhook = "" },
	{ name = "P_Spinning_Anus_S_Main",                                         webhook = "" },
	{ name = "P_Spinning_Anus_S_Root",                                         webhook = "" },
	{ name = "cs3_08b_rsn_db_aliencover_0001cs3_08b_rsn_db_aliencover_0001_a", webhook = "" },
	{ name = "sc1_04_rnmo_paintoverlaysc1_04_rnmo_paintoverlay_a",             webhook = "" },
	{ name = "rnbj_wallsigns_0001",                                            webhook = "" },
	{ name = "proc_sml_stones01",                                              webhook = "" },
	{ name = "proc_sml_stones02",                                              webhook = "" },
	{ name = "maverick",                                                       webhook = "" },
	{ name = "Miljet",                                                         webhook = "" },
	{ name = "proc_sml_stones03",                                              webhook = "" },
	{ name = "proc_stones_01",                                                 webhook = "" },
	{ name = "proc_stones_02",                                                 webhook = "" },
	{ name = "proc_stones_03",                                                 webhook = "" },
	{ name = "proc_stones_04",                                                 webhook = "" },
	{ name = "proc_stones_05",                                                 webhook = "" },
	{ name = "proc_stones_06",                                                 webhook = "" },
	{ name = "prop_coral_stone_03",                                            webhook = "" },
	{ name = "prop_coral_stone_04",                                            webhook = "" },
	{ name = "prop_gravestones_01a",                                           webhook = "" },
	{ name = "prop_gravestones_02a",                                           webhook = "" },
	{ name = "prop_gravestones_03a",                                           webhook = "" },
	{ name = "prop_gravestones_04a",                                           webhook = "" },
	{ name = "prop_gravestones_05a",                                           webhook = "" },
	{ name = "prop_gravestones_06a",                                           webhook = "" },
	{ name = "prop_gravestones_07a",                                           webhook = "" },
	{ name = "prop_gravestones_08a",                                           webhook = "" },
	{ name = "prop_gravestones_09a",                                           webhook = "" },
	{ name = "prop_gravestones_10a",                                           webhook = "" },
	{ name = "prop_prlg_gravestone_05a_l1",                                    webhook = "" },
	{ name = "prop_prlg_gravestone_06a",                                       webhook = "" },
	{ name = "test_prop_gravestones_04a",                                      webhook = "" },
	{ name = "test_prop_gravestones_05a",                                      webhook = "" },
	{ name = "test_prop_gravestones_07a",                                      webhook = "" },
	{ name = "test_prop_gravestones_08a",                                      webhook = "" },
	{ name = "test_prop_gravestones_09a",                                      webhook = "" },
	{ name = "prop_prlg_gravestone_01a",                                       webhook = "" },
	{ name = "prop_prlg_gravestone_02a",                                       webhook = "" },
	{ name = "prop_prlg_gravestone_03a",                                       webhook = "" },
	{ name = "prop_prlg_gravestone_04a",                                       webhook = "" },
	{ name = "prop_stoneshroom1",                                              webhook = "" },
	{ name = "prop_stoneshroom2",                                              webhook = "" },
	{ name = "v_res_fa_stones01",                                              webhook = "" },
	{ name = "test_prop_gravestones_01a",                                      webhook = "" },
	{ name = "test_prop_gravestones_02a",                                      webhook = "" },
	{ name = "prop_prlg_gravestone_05a",                                       webhook = "" },
	{ name = "FreemodeFemale01",                                               webhook = "" },
	{ name = "p_cablecar_s",                                                   webhook = "" },
	{ name = "stt_prop_stunt_tube_l",                                          webhook = "" },
	{ name = "stt_prop_stunt_track_dwuturn",                                   webhook = "" },
	{ name = "p_spinning_anus_s",                                              webhook = "" },
	{ name = "prop_windmill_01",                                               webhook = "" },
	{ name = "hei_prop_heist_tug",                                             webhook = "" },
	{ name = "prop_air_bigradar",                                              webhook = "" },
	{ name = "p_oil_slick_01",                                                 webhook = "" },
	{ name = "prop_dummy_01",                                                  webhook = "" },
	{ name = "hei_prop_heist_emp",                                             webhook = "" },
	{ name = "p_tram_cash_s",                                                  webhook = "" },
	{ name = "hw1_blimp_ce2",                                                  webhook = "" },
	{ name = "prop_fire_exting_1a",                                            webhook = "" },
	{ name = "prop_fire_exting_1b",                                            webhook = "" },
	{ name = "prop_fire_exting_2a",                                            webhook = "" },
	{ name = "prop_fire_exting_3a",                                            webhook = "" },
	{ name = "hw1_blimp_ce2_lod",                                              webhook = "" },
	{ name = "hw1_blimp_ce_lod",                                               webhook = "" },
	{ name = "hw1_blimp_cpr003",                                               webhook = "" },
	{ name = "hw1_blimp_cpr_null",                                             webhook = "" },
	{ name = "hw1_blimp_cpr_null2",                                            webhook = "" },
	{ name = "prop_lev_des_barage_02",                                         webhook = "" },
	{ name = "hei_prop_carrier_defense_01",                                    webhook = "" },
	{ name = "prop_juicestand",                                                webhook = "" },
	{ name = "S_M_M_MovAlien_01",                                              webhook = "" },
	{ name = "s_m_m_movalien_01",                                              webhook = "" },
	{ name = "s_m_m_movallien_01",                                             webhook = "" },
	{ name = "u_m_y_babyd",                                                    webhook = "" },
	{ name = "CS_Orleans",                                                     webhook = "" },
	{ name = "A_M_Y_ACult_01",                                                 webhook = "" },
	{ name = "S_M_M_MovSpace_01",                                              webhook = "" },
	{ name = "U_M_Y_Zombie_01",                                                webhook = "" },
	{ name = "s_m_y_blackops_01",                                              webhook = "" },
	{ name = "a_f_y_topless_01",                                               webhook = "" },
	{ name = "a_c_boar",                                                       webhook = "" },
	{ name = "a_c_cat_01",                                                     webhook = "" },
	{ name = "a_c_chickenhawk",                                                webhook = "" },
	{ name = "a_c_chimp",                                                      webhook = "" },
	{ name = "s_f_y_hooker_03",                                                webhook = "" },
	{ name = "a_c_chop",                                                       webhook = "" },
	{ name = "a_c_cormorant",                                                  webhook = "" },
	{ name = "a_c_cow",                                                        webhook = "" },
	{ name = "a_c_coyote",                                                     webhook = "" },
	{ name = "v_ilev_found_cranebucket",                                       webhook = "" },
	{ name = "p_cs_sub_hook_01_s",                                             webhook = "" },
	{ name = "a_c_crow",                                                       webhook = "" },
	{ name = "a_c_dolphin",                                                    webhook = "" },
	{ name = "a_c_fish",                                                       webhook = "" },
	{ name = "hei_prop_heist_hook_01",                                         webhook = "" },
	{ name = "prop_rope_hook_01",                                              webhook = "" },
	{ name = "prop_sub_crane_hook",                                            webhook = "" },
	{ name = "s_f_y_hooker_01",                                                webhook = "" },
	{ name = "prop_vehicle_hook",                                              webhook = "" },
	{ name = "prop_v_hook_s",                                                  webhook = "" },
	{ name = "prop_dock_crane_02_hook",                                        webhook = "" },
	{ name = "prop_winch_hook_long",                                           webhook = "" },
	{ name = "a_c_hen",                                                        webhook = "" },
	{ name = "a_c_humpback",                                                   webhook = "" },
	{ name = "a_c_husky",                                                      webhook = "" },
	{ name = "a_c_killerwhale",                                                webhook = "" },
	{ name = "a_c_mtlion",                                                     webhook = "" },
	{ name = "a_c_pigeon",                                                     webhook = "" },
	{ name = "a_c_poodle",                                                     webhook = "" },
	{ name = "prop_coathook_01",                                               webhook = "" },
	{ name = "prop_cs_sub_hook_01",                                            webhook = "" },
	{ name = "a_c_pug",                                                        webhook = "" },
	{ name = "a_c_rabbit_01",                                                  webhook = "" },
	{ name = "a_c_rat",                                                        webhook = "" },
	{ name = "a_c_retriever",                                                  webhook = "" },
	{ name = "a_c_rhesus",                                                     webhook = "" },
	{ name = "a_c_rottweiler",                                                 webhook = "" },
	{ name = "a_c_sharkhammer",                                                webhook = "" },
	{ name = "a_c_sharktiger",                                                 webhook = "" },
	{ name = "a_c_shepherd",                                                   webhook = "" },
	{ name = "a_c_stingray",                                                   webhook = "" },
	{ name = "a_c_westy",                                                      webhook = "" },
	{ name = "CS_Orleans",                                                     webhook = "" },
	{ name = "prop_windmill_01",                                               webhook = "" },
	{ name = "prop_Ld_ferris_wheel",                                           webhook = "" },
	{ name = "p_tram_crash_s",                                                 webhook = "" },
	{ name = "p_oil_slick_01",                                                 webhook = "" },
	{ name = "p_ld_stinger_s",                                                 webhook = "" },
	{ name = "p_ld_soc_ball_01",                                               webhook = "" },
	{ name = "p_parachute1_s",                                                 webhook = "" },
	{ name = "p_cablecar_s",                                                   webhook = "" },
	{ name = "prop_beach_fire",                                                webhook = "" },
	{ name = "prop_lev_des_barge_02",                                          webhook = "" },
	{ name = "prop_lev_des_barge_01",                                          webhook = "" },
	{ name = "prop_sculpt_fix",                                                webhook = "" },
	{ name = "prop_flagpole_2b",                                               webhook = "" },
	{ name = "prop_flagpole_2c",                                               webhook = "" },
	{ name = "prop_winch_hook_short",                                          webhook = "" },
	{ name = "prop_flag_canada",                                               webhook = "" },
	{ name = "prop_flag_canada_s",                                             webhook = "" },
	{ name = "prop_flag_eu",                                                   webhook = "" },
	{ name = "prop_flag_eu_s",                                                 webhook = "" },
	{ name = "prop_flag_france",                                               webhook = "" },
	{ name = "prop_flag_france_s",                                             webhook = "" },
	{ name = "prop_flag_german",                                               webhook = "" },
	{ name = "prop_ld_hook",                                                   webhook = "" },
	{ name = "prop_flag_german_s",                                             webhook = "" },
	{ name = "prop_flag_ireland",                                              webhook = "" },
	{ name = "prop_flag_ireland_s",                                            webhook = "" },
	{ name = "prop_flag_japan",                                                webhook = "" },
	{ name = "prop_flag_japan_s",                                              webhook = "" },
	{ name = "prop_flag_ls",                                                   webhook = "" },
	{ name = "prop_flag_lsfd",                                                 webhook = "" },
	{ name = "prop_flag_lsfd_s",                                               webhook = "" },
	{ name = "prop_cable_hook_01",                                             webhook = "" },
	{ name = "prop_flag_lsservices",                                           webhook = "" },
	{ name = "prop_flag_lsservices_s",                                         webhook = "" },
	{ name = "prop_flag_ls_s",                                                 webhook = "" },
	{ name = "prop_flag_mexico",                                               webhook = "" },
	{ name = "prop_flag_mexico_s",                                             webhook = "" },
	{ name = "csx_coastboulder_00",                                            webhook = "" },
	{ name = "des_tankercrash_01",                                             webhook = "" },
	{ name = "des_tankerexplosion_01",                                         webhook = "" },
	{ name = "des_tankerexplosion_02",                                         webhook = "" },
	{ name = "des_trailerparka_02",                                            webhook = "" },
	{ name = "des_trailerparkb_02",                                            webhook = "" },
	{ name = "des_trailerparkc_02",                                            webhook = "" },
	{ name = "des_trailerparkd_02",                                            webhook = "" },
	{ name = "des_traincrash_root2",                                           webhook = "" },
	{ name = "des_traincrash_root3",                                           webhook = "" },
	{ name = "des_traincrash_root4",                                           webhook = "" },
	{ name = "des_traincrash_root5",                                           webhook = "" },
	{ name = "des_finale_vault_end",                                           webhook = "" },
	{ name = "des_finale_vault_root001",                                       webhook = "" },
	{ name = "des_finale_vault_root002",                                       webhook = "" },
	{ name = "des_finale_vault_root003",                                       webhook = "" },
	{ name = "des_finale_vault_root004",                                       webhook = "" },
	{ name = "des_finale_vault_start",                                         webhook = "" },
	{ name = "des_vaultdoor001_root001",                                       webhook = "" },
	{ name = "des_vaultdoor001_root002",                                       webhook = "" },
	{ name = "des_vaultdoor001_root003",                                       webhook = "" },
	{ name = "des_vaultdoor001_root004",                                       webhook = "" },
	{ name = "des_vaultdoor001_root005",                                       webhook = "" },
	{ name = "des_vaultdoor001_root006",                                       webhook = "" },
	{ name = "des_vaultdoor001_skin001",                                       webhook = "" },
	{ name = "des_vaultdoor001_start",                                         webhook = "" },
	{ name = "des_traincrash_root6",                                           webhook = "" },
	{ name = "prop_ld_vault_door",                                             webhook = "" },
	{ name = "prop_vault_door_scene",                                          webhook = "" },
	{ name = "prop_vault_door_scene",                                          webhook = "" },
	{ name = "prop_vault_shutter",                                             webhook = "" },
	{ name = "p_fin_vaultdoor_s",                                              webhook = "" },
	{ name = "v_ilev_bk_vaultdoor",                                            webhook = "" },
	{ name = "prop_gold_vault_fence_l",                                        webhook = "" },
	{ name = "prop_gold_vault_fence_r",                                        webhook = "" },
	{ name = "prop_gold_vault_gate_01",                                        webhook = "" },
	{ name = "prop_bank_vaultdoor",                                            webhook = "" },
	{ name = "des_traincrash_root7",                                           webhook = "" },
	{ name = "prop_flag_russia",                                               webhook = "" },
	{ name = "prop_flag_russia_s",                                             webhook = "" },
	{ name = "prop_flag_s",                                                    webhook = "" },
	{ name = "ch2_03c_props_rrlwindmill_lod",                                  webhook = "" },
	{ name = "prop_flag_sa",                                                   webhook = "" },
	{ name = "prop_flag_sapd",                                                 webhook = "" },
	{ name = "prop_flag_sapd_s",                                               webhook = "" },
	{ name = "prop_flag_sa_s",                                                 webhook = "" },
	{ name = "prop_flag_scotland",                                             webhook = "" },
	{ name = "prop_flag_scotland_s",                                           webhook = "" },
	{ name = "prop_flag_sheriff",                                              webhook = "" },
	{ name = "prop_flag_sheriff_s",                                            webhook = "" },
	{ name = "prop_flag_uk",                                                   webhook = "" },
	{ name = "prop_yacht_lounger",                                             webhook = "" },
	{ name = "prop_yacht_seat_01",                                             webhook = "" },
	{ name = "prop_yacht_seat_02",                                             webhook = "" },
	{ name = "prop_yacht_seat_03",                                             webhook = "" },
	{ name = "marina_xr_rocks_02",                                             webhook = "" },
	{ name = "marina_xr_rocks_03",                                             webhook = "" },
	{ name = "prop_test_rocks01",                                              webhook = "" },
	{ name = "prop_test_rocks02",                                              webhook = "" },
	{ name = "prop_test_rocks03",                                              webhook = "" },
	{ name = "prop_test_rocks04",                                              webhook = "" },
	{ name = "marina_xr_rocks_04",                                             webhook = "" },
	{ name = "marina_xr_rocks_05",                                             webhook = "" },
	{ name = "marina_xr_rocks_06",                                             webhook = "" },
	{ name = "prop_yacht_table_01",                                            webhook = "" },
	{ name = "csx_searocks_02",                                                webhook = "" },
	{ name = "csx_searocks_03",                                                webhook = "" },
	{ name = "csx_searocks_04",                                                webhook = "" },
	{ name = "csx_searocks_05",                                                webhook = "" },
	{ name = "csx_searocks_06",                                                webhook = "" },
	{ name = "p_yacht_chair_01_s",                                             webhook = "" },
	{ name = "p_yacht_sofa_01_s",                                              webhook = "" },
	{ name = "prop_yacht_table_02",                                            webhook = "" },
	{ name = "csx_coastboulder_00",                                            webhook = "" },
	{ name = "csx_coastboulder_01",                                            webhook = "" },
	{ name = "csx_coastboulder_02",                                            webhook = "" },
	{ name = "csx_coastboulder_03",                                            webhook = "" },
	{ name = "csx_coastboulder_04",                                            webhook = "" },
	{ name = "csx_coastboulder_05",                                            webhook = "" },
	{ name = "csx_coastboulder_06",                                            webhook = "" },
	{ name = "csx_coastboulder_07",                                            webhook = "" },
	{ name = "csx_coastrok1",                                                  webhook = "" },
	{ name = "csx_coastrok2",                                                  webhook = "" },
	{ name = "csx_coastrok3",                                                  webhook = "" },
	{ name = "csx_coastrok4",                                                  webhook = "" },
	{ name = "csx_coastsmalrock_01",                                           webhook = "" },
	{ name = "csx_coastsmalrock_02",                                           webhook = "" },
	{ name = "csx_coastsmalrock_03",                                           webhook = "" },
	{ name = "csx_coastsmalrock_04",                                           webhook = "" },
	{ name = "csx_coastsmalrock_05",                                           webhook = "" },
	{ name = "prop_yacht_table_03",                                            webhook = "" },
	{ name = "prop_flag_uk_s",                                                 webhook = "" },
	{ name = "prop_flag_us",                                                   webhook = "" },
	{ name = "prop_flag_usboat",                                               webhook = "" },
	{ name = "prop_flag_us_r",                                                 webhook = "" },
	{ name = "prop_flag_us_s",                                                 webhook = "" },
	{ name = "p_gasmask_s",                                                    webhook = "" },
	{ name = "prop_flamingo",                                                  webhook = "" },
	{ name = "prop_gas_pump_1d",                                               webhook = "" },
	{ name = "prop_gas_pump_1a",                                               webhook = "" },
	{ name = "prop_gas_pump_1b",                                               webhook = "" },
	{ name = "prop_gas_pump_1c",                                               webhook = "" },
	{ name = "prop_vintage_pump",                                              webhook = "" },
	{ name = "prop_gas_pump_old2",                                             webhook = "" },
	{ name = "prop_gas_pump_old3",                                             webhook = "" },
	{ name = "prop_beach_fire",                                                webhook = "" },
	{ name = "stt_prop_stunt_track_dwslope30",                                 webhook = "" },
	{ name = "prop_cs_dildo_01",                                               webhook = "" },
	{ name = "cs4_lod_01_slod3",                                               webhook = "" },
	{ name = "p_spinning_anus_s",                                              webhook = "" },
	{ name = "sr_prop_stunt_tube_crn_15d_05a",                                 webhook = "" },
	{ name = "as_prop_as_dwslope30",                                           webhook = "" },
	{ name = "prop_carjack",                                                   webhook = "" },
	{ name = "ch_prop_gold_trolly_01a",                                        webhook = "" },
	{ name = "prop_el_guitar_03",                                              webhook = "" },
	{ name = "prop_security_case_01",                                          webhook = "" },
	{ name = "p_amb_brolly_01",                                                webhook = "" },
	{ name = "stt_prop_stunt_track_uturn",                                     webhook = "" },
	{ name = "stt_prop_stunt_track_turnice",                                   webhook = "" },
	{ name = "stt_prop_stunt_track_hill",                                      webhook = "" },
	{ name = "prop_gold_cont_01",                                              webhook = "" },
	{ name = "p_cablecar_s",                                                   webhook = "" },
	{ name = "stt_prop_stunt_tube_l",                                          webhook = "" },
	{ name = "stt_prop_stunt_track_dwuturn",                                   webhook = "" },
	{ name = "prop_fnclink_05crnr1",                                           webhook = "" },
	{ name = "prop_gascage01",                                                 webhook = "" },
	{ name = "prop_cs_dildo_01",                                               webhook = "" },
	{ name = "xs_prop_hamburgher_wl",                                          webhook = "" },
	{ name = "xs_prop_plastic_bottle_wl",                                      webhook = "" },
	{ name = "prop_windmill_01",                                               webhook = "" },
	{ name = "p_spinning_anus_s",                                              webhook = "" },
	{ name = "stt_prop_ramp_adj_flip_m",                                       webhook = "" },
	{ name = "stt_prop_ramp_adj_flip_mb",                                      webhook = "" },
	{ name = "stt_prop_ramp_adj_flip_s",                                       webhook = "" },
	{ name = "stt_prop_ramp_adj_flip_sb",                                      webhook = "" },
	{ name = "stt_prop_ramp_adj_hloop",                                        webhook = "" },
	{ name = "stt_prop_ramp_adj_loop",                                         webhook = "" },
	{ name = "stt_prop_ramp_jump_l",                                           webhook = "" },
	{ name = "stt_prop_ramp_jump_m",                                           webhook = "" },
	{ name = "stt_prop_ramp_jump_s",                                           webhook = "" },
	{ name = "stt_prop_ramp_jump_xl",                                          webhook = "" },
	{ name = "stt_prop_ramp_jump_xs",                                          webhook = "" },
	{ name = "stt_prop_ramp_jump_xxl",                                         webhook = "" },
	{ name = "stt_prop_ramp_multi_loop_rb",                                    webhook = "" },
	{ name = "stt_prop_ramp_spiral_l",                                         webhook = "" },
	{ name = "stt_prop_ramp_spiral_l_l",                                       webhook = "" },
	{ name = "stt_prop_ramp_spiral_l_m",                                       webhook = "" },
	{ name = "stt_prop_ramp_spiral_l_s",                                       webhook = "" },
	{ name = "stt_prop_ramp_spiral_l_xxl",                                     webhook = "" },
	{ name = "stt_prop_ramp_spiral_m",                                         webhook = "" },
	{ name = "stt_prop_ramp_spiral_s",                                         webhook = "" },
	{ name = "stt_prop_ramp_spiral_xxl",                                       webhook = "" },
	{ name = "stt_prop_stunt_track_dwslope30",                                 webhook = "" },
	{ name = "-145066854",                                                     webhook = "" },
	{ name = "stt_prop_stunt_track_start",                                     webhook = "" },
	{ name = "stt_prop_stunt_track_slope45",                                   webhook = "" },
	{ name = "stt_prop_stunt_track_slope30",                                   webhook = "" },
	{ name = "stt_prop_stunt_track_slope15",                                   webhook = "" },
	{ name = "stt_prop_stunt_track_short",                                     webhook = "" },
	{ name = "stt_prop_stunt_track_sh45_a",                                    webhook = "" },
	{ name = "stt_prop_stunt_track_sh45",                                      webhook = "" },
	{ name = "stt_prop_stunt_track_sh30",                                      webhook = "" },
	{ name = "stt_prop_stunt_track_sh15",                                      webhook = "" },
	{ name = "stt_prop_stunt_track_otake",                                     webhook = "" },
	{ name = "stt_prop_stunt_track_link",                                      webhook = "" },
	{ name = "stt_prop_stunt_track_jump",                                      webhook = "" },
	{ name = "stt_prop_stunt_track_hill2",                                     webhook = "" },
	{ name = "stt_prop_stunt_track_hill",                                      webhook = "" },
	{ name = "stt_prop_stunt_track_funnel",                                    webhook = "" },
	{ name = "stt_prop_stunt_track_funlng",                                    webhook = "" },
	{ name = "stt_prop_stunt_track_fork",                                      webhook = "" },
	{ name = "stt_prop_stunt_track_exshort",                                   webhook = "" },
	{ name = "stt_prop_stunt_track_dwuturn",                                   webhook = "" },
	{ name = "stt_prop_stunt_track_dwturn",                                    webhook = "" },
	{ name = "stt_prop_stunt_track_dwslope45",                                 webhook = "" },
	{ name = "stt_prop_stunt_track_dwslope30",                                 webhook = "" },
	{ name = "stt_prop_stunt_track_dwslope15",                                 webhook = "" },
	{ name = "stt_prop_stunt_track_dwshort",                                   webhook = "" },
	{ name = "stt_prop_stunt_track_dwsh15",                                    webhook = "" },
	{ name = "stt_prop_stunt_track_dwlink_02",                                 webhook = "" },
	{ name = "stt_prop_stunt_track_dwlink",                                    webhook = "" },
	{ name = "stt_prop_stunt_track_cutout",                                    webhook = "" },
	{ name = "stt_prop_stunt_track_bumps",                                     webhook = "" },
	{ name = "stt_prop_stunt_target_small",                                    webhook = "" },
	{ name = "stt_prop_stunt_target",                                          webhook = "" },
	{ name = "stt_prop_stunt_soccer_sball",                                    webhook = "" },
	{ name = "stt_prop_stunt_soccer_lball",                                    webhook = "" },
	{ name = "stt_prop_stunt_soccer_goal",                                     webhook = "" },
	{ name = "stt_prop_stunt_soccer_ball",                                     webhook = "" },
	{ name = "stt_prop_stunt_ramp",                                            webhook = "" },
	{ name = "stt_prop_stunt_landing_zone_01",                                 webhook = "" },
	{ name = "stt_prop_stunt_jump_sb",                                         webhook = "" },
	{ name = "stt_prop_stunt_jump_s",                                          webhook = "" },
	{ name = "stt_prop_stunt_jump_mb",                                         webhook = "" },
	{ name = "stt_prop_stunt_jump_m",                                          webhook = "" },
	{ name = "stt_prop_stunt_jump_loop",                                       webhook = "" },
	{ name = "stt_prop_stunt_jump_lb",                                         webhook = "" },
	{ name = "stt_prop_stunt_jump_l",                                          webhook = "" },
	{ name = "stt_prop_stunt_jump45",                                          webhook = "" },
	{ name = "stt_prop_stunt_jump30",                                          webhook = "" },
	{ name = "stt_prop_stunt_jump15",                                          webhook = "" },
	{ name = "stt_prop_stunt_track_start",                                     webhook = "" },
	{ name = "prop_container_01a",                                             webhook = "" },
	{ name = "prop_contnr_pile_01a",                                           webhook = "" },
	{ name = "ce_xr_ctr2",                                                     webhook = "" },
	{ name = "stt_prop_ramp_jump_xxl",                                         webhook = "" },
	{ name = "hei_prop_carrier_jet",                                           webhook = "" },
	{ name = "prop_parking_hut_2",                                             webhook = "" },
	{ name = "csx_seabed_rock3_",                                              webhook = "" },
	{ name = "db_apart_03_",                                                   webhook = "" },
	{ name = "db_apart_09_",                                                   webhook = "" },
	{ name = "stt_prop_stunt_tube_l",                                          webhook = "" },
	{ name = "stt_prop_stunt_track_dwuturn",                                   webhook = "" },
	{ name = "xs_prop_hamburgher_wl",                                          webhook = "" },
	{ name = "sr_prop_spec_tube_xxs_01a",                                      webhook = "" },
	{ name = "prop_air_bigradar",                                              webhook = "" },
	{ name = "p_tram_crash_s",                                                 webhook = "" },
	{ name = "prop_windmill_01",                                               webhook = "" },
	{ name = "prop_start_gate_01",                                             webhook = "" },
	{ name = "prop_trailer_01_new",                                            webhook = "" },
	{ name = "sr_prop_sr_track_block_01",                                      webhook = "" },
	{ name = "sr_prop_spec_tube_xxs_04a",                                      webhook = "" },
	{ name = "stt_prop_stunt_soccer_sball",                                    webhook = "" },
	{ name = "stt_prop_stunt_track_cutout",                                    webhook = "" },
	{ name = "stt_prop_stunt_target_small",                                    webhook = "" },
	{ name = "prop_cj_big_boat",                                               webhook = "" },
	{ name = "stt_prop_stunt_domino",                                          webhook = "" },
	{ name = "hei_prop_carrier_radar_1_l1",                                    webhook = "" },
	{ name = "v_res_mexball",                                                  webhook = "" },
	{ name = "prop_rock_1_a",                                                  webhook = "" },
	{ name = "prop_rock_1_b",                                                  webhook = "" },
	{ name = "prop_rock_1_c",                                                  webhook = "" },
	{ name = "prop_rock_1_d",                                                  webhook = "" },
	{ name = "prop_rock_1_e",                                                  webhook = "" },
	{ name = "prop_rock_1_f",                                                  webhook = "" },
	{ name = "prop_rock_1_g",                                                  webhook = "" },
	{ name = "prop_rock_1_h",                                                  webhook = "" },
	{ name = "prop_test_boulder_01",                                           webhook = "" },
	{ name = "prop_test_boulder_02",                                           webhook = "" },
	{ name = "prop_test_boulder_03",                                           webhook = "" },
	{ name = "prop_test_boulder_04",                                           webhook = "" },
	{ name = "apa_mp_apa_crashed_usaf_01a",                                    webhook = "" },
	{ name = "ex_prop_exec_crashdp",                                           webhook = "" },
	{ name = "apa_mp_apa_yacht_o1_rail_a",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_o1_rail_b",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_armchair_01",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_armchair_03",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_armchair_04",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_barstool_01",                                     webhook = "" },
	{ name = "apa_mp_h_yacht_bed_01",                                          webhook = "" },
	{ name = "apa_mp_h_yacht_bed_02",                                          webhook = "" },
	{ name = "apa_mp_h_yacht_coffee_table_01",                                 webhook = "" },
	{ name = "apa_mp_h_yacht_coffee_table_02",                                 webhook = "" },
	{ name = "apa_mp_h_yacht_floor_lamp_01",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_side_table_01",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_side_table_02",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_sofa_01",                                         webhook = "" },
	{ name = "apa_mp_h_yacht_sofa_02",                                         webhook = "" },
	{ name = "apa_mp_h_yacht_stool_01",                                        webhook = "" },
	{ name = "apa_mp_h_yacht_strip_chair_01",                                  webhook = "" },
	{ name = "apa_mp_h_yacht_table_lamp_01",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_table_lamp_02",                                   webhook = "" },
	{ name = "apa_mp_h_yacht_table_lamp_03",                                   webhook = "" },
	{ name = "prop_flag_columbia",                                             webhook = "" },
	{ name = "apa_mp_apa_yacht_o2_rail_a",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_o2_rail_b",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_o3_rail_a",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_o3_rail_b",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_option1",                                       webhook = "" },
	{ name = "apa_mp_apa_yacht_option1_cola",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option2",                                       webhook = "" },
	{ name = "apa_mp_apa_yacht_option2_cola",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option2_colb",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3",                                       webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_cola",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_colb",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_colc",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_cold",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_option3_cole",                                  webhook = "" },
	{ name = "apa_mp_apa_yacht_jacuzzi_cam",                                   webhook = "" },
	{ name = "apa_mp_apa_yacht_jacuzzi_ripple003",                             webhook = "" },
	{ name = "apa_mp_apa_yacht_jacuzzi_ripple1",                               webhook = "" },
	{ name = "apa_mp_apa_yacht_jacuzzi_ripple2",                               webhook = "" },
	{ name = "apa_mp_apa_yacht_radar_01a",                                     webhook = "" },
	{ name = "apa_mp_apa_yacht_win",                                           webhook = "" },
	{ name = "prop_crashed_heli",                                              webhook = "" },
	{ name = "apa_mp_apa_yacht_door",                                          webhook = "" },
	{ name = "prop_shamal_crash",                                              webhook = "" },
	{ name = "xm_prop_x17_shamal_crash",                                       webhook = "" },
	{ name = "apa_mp_apa_yacht_door2",                                         webhook = "" },
	{ name = "apa_mp_apa_yacht",                                               webhook = "" },
	{ name = "prop_flagpole_2b",                                               webhook = "" },
	{ name = "prop_flagpole_2c",                                               webhook = "" },
	{ name = "prop_flag_canada",                                               webhook = "" },
	{ name = "apa_prop_yacht_float_1a",                                        webhook = "" },
	{ name = "apa_prop_yacht_float_1b",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_01",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_02",                                        webhook = "" },
	{ name = "apa_prop_yacht_glass_03",                                        webhook = "" },
	{ name = "prop_beach_fire",                                                webhook = "" },
	{ name = "prop_rock_4_big2",                                               webhook = "" },
	{ name = "prop_beachflag_le",                                              webhook = "" },
	{ name = "freight",                                                        webhook = "" },
	{ name = "stt_prop_race_start_line_03b",                                   webhook = "" },
	{ name = "stt_prop_stunt_soccer_sball",                                    webhook = "" }
}
