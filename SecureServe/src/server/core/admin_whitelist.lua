local AdminWhitelist = {}

local logger = require("server/core/logger")

-- Cache per source. Each entry has admin/whitelist flags and a timestamp
-- to softly invalidate if too much time passes. The real deletion happens
-- in playerDropped, but having a TTL is useful if ACE changes at runtime
-- (for example, the admin receives a new permission).
local CACHE_TTL = 60

local source_cache = {}
local pending_admin_checks = {}

local PERMISSION_GROUPS = {
    teleport         = "secure.bypass.teleport",
    visions          = "secure.bypass.visions",
    speedhack        = "secure.bypass.speedhack",
    spectate         = "secure.bypass.spectate",
    noclip           = "secure.bypass.noclip",
    ocr              = "secure.bypass.ocr",
    playerblips      = "secure.bypass.playerblips",
    invisible        = "secure.bypass.invisible",
    godmode          = "secure.bypass.godmode",
    freecam          = "secure.bypass.freecam",
    superjump        = "secure.bypass.superjump",
    noragdoll        = "secure.bypass.noragdoll",
    infinitestamina  = "secure.bypass.infinitestamina",
    magicbullet      = "secure.bypass.magicbullet",
    norecoil         = "secure.bypass.norecoil",
    aimassist        = "secure.bypass.aimassist",
    all              = "secure.bypass.all",
}

local PERMISSION_LIST = {
    "teleport", "visions", "speedhack", "spectate", "noclip",
    "ocr", "playerblips", "invisible", "godmode", "freecam",
    "superjump", "noragdoll", "infinitestamina", "magicbullet",
    "norecoil", "aimassist",
}


-- //[Helpers]\\ --

local function normalize_identifier(identifier)
    if type(identifier) ~= "string" then return nil end
    local s = identifier:gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if s == "" then return nil end
    return s
end

local function normalize_license(license)
    local s = normalize_identifier(license)
    if not s then return nil end
    local token = s:match("^license2?:(%x+)$")
    if token then return token end
    if s:match("^[%x]+$") then return s end
    return nil
end

local function get_or_init_cache(src)
    local entry = source_cache[src]
    if not entry or (os.time() - entry.created_at) > CACHE_TTL then
        entry = {
            created_at      = os.time(),
            identifiers     = nil,   -- lazy
            is_admin        = nil,
            is_whitelisted  = nil,
            permissions     = nil,   -- resolved permissions table
        }
        source_cache[src] = entry
    end
    return entry
end

local function get_identifiers(src)
    local entry = get_or_init_cache(src)
    if entry.identifiers then return entry.identifiers end
    entry.identifiers = GetPlayerIdentifiers(src) or {}
    return entry.identifiers
end


-- //[ACE Permissions]\ --

function AdminWhitelist.hasAcePermission(source, permission)
    if not source or source <= 0 or not IsPlayerAceAllowed then
        return false
    end
    return IsPlayerAceAllowed(source, permission)
end


-- //[Manual Admin (license list and admins)]\ --

function AdminWhitelist.getManualAdmin(source)
    if not _G.SecureServe then return false end

    local identifiers = get_identifiers(source)
    local licenses    = (_G.SecureServe.AdminMenu and _G.SecureServe.AdminMenu.Licenses) or {}
    local manualAdmins = _G.SecureServe.Admins or {}

    local manualAdminLookup = {}
    local licenseLookup = {}

    for _, admin in pairs(manualAdmins) do
        local n = normalize_identifier(admin and admin.identifier)
        if n then manualAdminLookup[n] = true end
    end

    for _, lic in ipairs(licenses) do
        local n = normalize_license(lic)
        if n then licenseLookup[n] = true end
    end

    for _, identifier in pairs(identifiers) do
        local n = normalize_identifier(identifier)
        if n and manualAdminLookup[n] then return true end

        local lic = normalize_license(identifier)
        if lic and licenseLookup[lic] then return true end
    end

    return false
end

function AdminWhitelist.getTxAdminPerm(source)
    if not source or source <= 0 then return false end
    return IsPlayerAceAllowed(source, "command.tx")
        or IsPlayerAceAllowed(source, "command")
end


-- //[Admin/whitelist resolution (with cache)]\ --

function AdminWhitelist.isAdmin(source)
    if not source or source <= 0 or not GetPlayerName(source) then
        source_cache[source] = nil
        return false
    end

    local entry = get_or_init_cache(source)
    if entry.is_admin ~= nil then
        return entry.is_admin
    end

    local result = false

    if AdminWhitelist.getManualAdmin(source) then
        result = true
    elseif AdminWhitelist.hasAcePermission(source, "secure.bypass.all") then
        result = true
    elseif AdminWhitelist.getTxAdminPerm(source) then
        result = true
    end

    entry.is_admin = result
    return result
end

function AdminWhitelist.isWhitelisted(source)
    if not source or source <= 0 or not GetPlayerName(source) then
        return false
    end

    local entry = get_or_init_cache(source)
    if entry.is_whitelisted ~= nil then
        return entry.is_whitelisted
    end

    local result = AdminWhitelist.isAdmin(source)

    if not result and _G.SecureServe and _G.SecureServe.Whitelisted then
        local src = tonumber(source)
        for _, id in ipairs(_G.SecureServe.Whitelisted) do
            if tonumber(id) == src then
                result = true
                break
            end
        end
    end

    entry.is_whitelisted = result
    return result
end

function AdminWhitelist.hasPermission(source, permission)
    if not source or source <= 0 or not GetPlayerName(source) then
        return false
    end

    if AdminWhitelist.isAdmin(source) then
        return true
    end

    if AdminWhitelist.hasAcePermission(source, "secure.bypass.all") then
        return true
    end

    local ace = PERMISSION_GROUPS[permission]
    if ace then
        return AdminWhitelist.hasAcePermission(source, ace)
    end

    return false
end

function AdminWhitelist.getPlayerPermissions(source)
    if not source or source <= 0 or not GetPlayerName(source) then
        return {}
    end

    local entry = get_or_init_cache(source)
    if entry.permissions then
        return entry.permissions
    end

    local permissions = {}

    if AdminWhitelist.isAdmin(source)
        or AdminWhitelist.hasAcePermission(source, "secure.bypass.all")
    then
        for _, p in ipairs(PERMISSION_LIST) do permissions[p] = true end
        permissions.all = true
    else
        for _, p in ipairs(PERMISSION_LIST) do
            permissions[p] = AdminWhitelist.hasAcePermission(source, "secure.bypass." .. p)
        end
    end

    entry.permissions = permissions
    return permissions
end


-- //[List synchronization]\ --

function AdminWhitelist.checkAndAddAdmin(source)
    if not source or source <= 0 then return end
    local playerName = GetPlayerName(source)
    if not playerName then return end

    if AdminWhitelist.isAdmin(source) then
        if _G.SecureServe and _G.SecureServe.Whitelisted then
            local src = tonumber(source)
            for _, id in ipairs(_G.SecureServe.Whitelisted) do
                if tonumber(id) == src then return end
            end
            table.insert(_G.SecureServe.Whitelisted, src)
            logger.debug("Added admin to whitelist: " .. playerName .. " (ID: " .. source .. ")")
        end
    end
end

function AdminWhitelist.refreshAdminList()
    for src in pairs(source_cache) do
        source_cache[src] = nil
    end
    for _, playerSrc in ipairs(GetPlayers()) do
        AdminWhitelist.checkAndAddAdmin(tonumber(playerSrc))
    end
end

function AdminWhitelist.invalidate(source)
    source_cache[source] = nil
end

function AdminWhitelist.setupAdminSync()
    CreateThread(function()
        while true do
            Wait(300000)
            AdminWhitelist.refreshAdminList()
        end
    end)

    RegisterCommand("secureadmins", function(source)
        if source ~= 0 then return end
        AdminWhitelist.refreshAdminList()
        logger.info("^2[SUCCESS] Admin whitelist refreshed^7")
    end, true)
end


-- //[Inicializacion]\\ --

function AdminWhitelist.initialize()
    logger.info("^3[INFO] ^7Initializing Admin Whitelist module with ACE permissions")

    CreateThread(function()
        while true do
            Wait(600000)
            collectgarbage("step", 200)
        end
    end)

    if not _G.SecureServe then _G.SecureServe = {} end
    if not _G.SecureServe.Whitelisted then _G.SecureServe.Whitelisted = {} end

    AddEventHandler("playerJoining", function(source)
        local src = tonumber(source)
        if src then
            pending_admin_checks[src] = true
        end
    end)

    CreateThread(function()
        while true do
            local processed = false

            for src in pairs(pending_admin_checks) do
                processed = true
                pending_admin_checks[src] = nil
                if GetPlayerName(src) then
                    AdminWhitelist.checkAndAddAdmin(src)
                end
            end

            Wait(processed and 1000 or 5000)
        end
    end)

    RegisterNetEvent("SecureServe:CheckWhitelist", function()
        local src = source
        TriggerClientEvent("SecureServe:WhitelistResponse", src, AdminWhitelist.isWhitelisted(src))
    end)

    RegisterNetEvent("SecureServe:RequestAdminList", function()
        local src = source
        local adminList = {}

        if _G.SecureServe and _G.SecureServe.Whitelisted then
            for _, adminId in ipairs(_G.SecureServe.Whitelisted) do
                adminList[tostring(adminId)] = true
            end
        end

        if AdminWhitelist.isWhitelisted(src) then
            adminList[tostring(src)] = true
        end

        TriggerClientEvent("SecureServe:ReceiveAdminList", src, adminList)
    end)

    AddEventHandler("playerDropped", function()
        local src = source
        source_cache[src] = nil
        pending_admin_checks[src] = nil

        if _G.SecureServe and _G.SecureServe.Whitelisted then
            for i = #_G.SecureServe.Whitelisted, 1, -1 do
                if tonumber(_G.SecureServe.Whitelisted[i]) == tonumber(src) then
                    table.remove(_G.SecureServe.Whitelisted, i)
                    break
                end
            end
        end
    end)

    AdminWhitelist.setupAdminSync()

    logger.info("^5[SUCCESS] ^3Admin Whitelist^7 initialized with ACE permissions")
end

RegisterNetEvent("SecureServe:RequestPermissions", function()
    local src = source
    if not src or src <= 0 or not GetPlayerName(src) then return end
    TriggerClientEvent("SecureServe:ReceivePermissions", src, AdminWhitelist.getPlayerPermissions(src))
end)

return AdminWhitelist
