---@class AdminWhitelistModule
local AdminWhitelist = {}

local logger = require("server/core/logger")
local ban_manager = require("server/core/ban_manager")

local cachedAdmins = {}
local pendingAdminChecks = {}

---@description Initialize the admin whitelist module
function AdminWhitelist.initialize()
    logger.info("^3[INFO] ^7Initializing Admin Whitelist module with ACE permissions")
    
    -- Garbage collection thread
    CreateThread(function()
        while true do
            collectgarbage("collect")
            Wait(600000)
        end
    end)
    
    if not _G.SecureServe then _G.SecureServe = {} end
    if not _G.SecureServe.Whitelisted then _G.SecureServe.Whitelisted = {} end
    
    AddEventHandler("playerJoining", function(source)
        local src = tonumber(source)
        if src then
            pendingAdminChecks[src] = true
        end
    end)
    
    CreateThread(function()
        while true do
            local processed = false
            
            for src, _ in pairs(pendingAdminChecks) do
                processed = true
                pendingAdminChecks[src] = nil
                
                if GetPlayerName(src) then 
                    AdminWhitelist.checkAndAddAdmin(src)
                end
            end

            Wait(processed and 1000 or 5000)
        end
    end)
    
    RegisterNetEvent("SecureServe:CheckWhitelist", function()
        local src = source
        local isWhitelisted = AdminWhitelist.isWhitelisted(src)
        TriggerClientEvent("SecureServe:WhitelistResponse", src, isWhitelisted)
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
        logger.debug("Sent admin list to player: " .. src)
    end)
    
    AddEventHandler("playerDropped", function()
        local src = source
        cachedAdmins[src] = nil

        if _G.SecureServe and _G.SecureServe.Whitelisted then
            for i = #_G.SecureServe.Whitelisted, 1, -1 do
                if tonumber(_G.SecureServe.Whitelisted[i]) == tonumber(src) then
                    table.remove(_G.SecureServe.Whitelisted, i)
                    break
                end
            end
        end
    end)
    
    -- Set up admin list refresh
    AdminWhitelist.setupAdminSync()
    
    logger.info("^5[SUCCESS] ^3Admin Whitelist^7 initialized with ACE permissions")
end

---@description Set up events to synchronize admin list
function AdminWhitelist.setupAdminSync()
    CreateThread(function()
        while true do
            Wait(300000)
            AdminWhitelist.refreshAdminList()
        end
    end)
    
    RegisterCommand("secureadmins", function(source)
        if source ~= 0 then 
            return
        end
        
        AdminWhitelist.refreshAdminList()
        logger.info("^2[SUCCESS] Admin whitelist refreshed^7")
    end, true)
end

---@description Check if a player has the specified ACE permission
---@param source number The player source
---@param permission string The ACE permission to check
---@return boolean hasPermission Whether the player has the permission
function AdminWhitelist.hasAcePermission(source, permission)
    if not source or source <= 0 or not IsPlayerAceAllowed then
        return false
    end
    
    return IsPlayerAceAllowed(source, permission)
end

---@description Check if a player has an admin permission based on ACE
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.isAdmin(source)
    if not source or source <= 0 or not GetPlayerName(source) then
        cachedAdmins[source] = nil
        return false
    end
    
    if cachedAdmins[source] ~= nil then
        return cachedAdmins[source]
    end
    
    if AdminWhitelist.getManualAdmin(source) then
        cachedAdmins[source] = true
        return true
    end
    
    local isAdmin = false
    
    if SecureServe.Permissions.Enabled then
        if AdminWhitelist.hasAcePermission(source, SecureServe.Permissions.DefaultAce) then
            isAdmin = true
        else
            for group, ace in pairs(SecureServe.Permissions.GroupAces) do
                if AdminWhitelist.hasAcePermission(source, ace) then
                    isAdmin = true
                    break
                end
            end
        end
    end
    
    -- Check txAdmin permission as a fallback
    if not isAdmin then
        isAdmin = AdminWhitelist.getTxAdminPerm(source)
    end
    
    cachedAdmins[source] = isAdmin
    return isAdmin
end

---@description Check if a player has txAdmin permission
---@param source number The player source
---@return boolean hasTxAdmin Whether the player has txAdmin permission
function AdminWhitelist.getTxAdminPerm(source)
    if not source or source <= 0 then return false end
    
    return IsPlayerAceAllowed(source, "command.tx")
        or IsPlayerAceAllowed(source, "command")
end

---@description Check if player is an admin based on manual list
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getManualAdmin(source)
    if not _G.SecureServe or not _G.SecureServe.Admins then
        return false
    end
    
    local identifiers = GetPlayerIdentifiers(source)
    
    for _, identifier in pairs(identifiers) do
        for _, admin in pairs(_G.SecureServe.Admins) do
            if identifier == admin.identifier then
                return true
            end
        end
    end
    
    return false
end

---@description Check if a player is whitelisted (combines admin and manual whitelist)
---@param source number The player source
---@return boolean isWhitelisted Whether the player is whitelisted
function AdminWhitelist.isWhitelisted(source)
    if not source or source <= 0 or not GetPlayerName(source) then
        return false
    end

    if AdminWhitelist.isAdmin(source) then
        return true
    end
    
    if _G.SecureServe and _G.SecureServe.Whitelisted then
        local src = tonumber(source)
        for _, id in ipairs(_G.SecureServe.Whitelisted) do
            if tonumber(id) == src then
                return true
            end
        end
    end
    
    return false
end

---@description Check and add player to whitelist if they're an admin
---@param source number The player source
function AdminWhitelist.checkAndAddAdmin(source)
    if not source or source <= 0 then return end
    
    local playerName = GetPlayerName(source)
    if not playerName then return end
    
    if AdminWhitelist.isAdmin(source) then
        if _G.SecureServe and _G.SecureServe.Whitelisted then
            local alreadyWhitelisted = false
            local src = tonumber(source)
            
            for _, id in ipairs(_G.SecureServe.Whitelisted) do
                if tonumber(id) == src then
                    alreadyWhitelisted = true
                    break
                end
            end
            
            if not alreadyWhitelisted then
                table.insert(_G.SecureServe.Whitelisted, src)
                logger.debug("Added admin to whitelist: " .. playerName .. " (ID: " .. source .. ")")
            end
        end
    end
end

---@description Refresh the admin whitelist
function AdminWhitelist.refreshAdminList()
    local players = GetPlayers()
    
    for _, playerSrc in ipairs(players) do
        AdminWhitelist.checkAndAddAdmin(tonumber(playerSrc))
    end
end

---@description Get specific permission for a player
---@param source number The player source
---@param permission string The permission to check
---@return boolean hasPermission Whether the player has the permission
function AdminWhitelist.hasPermission(source, permission)
    if not source or source <= 0 or not GetPlayerName(source) then
        return false
    end
    
    if AdminWhitelist.isAdmin(source) then
        return true
    end
    
    local permGroups = {
        ["teleport"] = "secure.bypass.teleport",
        ["visions"] = "secure.bypass.visions",
        ["speedhack"] = "secure.bypass.speedhack",
        ["spectate"] = "secure.bypass.spectate",
        ["noclip"] = "secure.bypass.noclip",
        ["ocr"] = "secure.bypass.ocr",
        ["playerblips"] = "secure.bypass.playerblips",
        ["invisible"] = "secure.bypass.invisible",
        ["godmode"] = "secure.bypass.godmode",
        ["freecam"] = "secure.bypass.freecam",
        ["superjump"] = "secure.bypass.superjump", 
        ["noragdoll"] = "secure.bypass.noragdoll",
        ["infinitestamina"] = "secure.bypass.infinitestamina",
        ["magicbullet"] = "secure.bypass.magicbullet",
        ["norecoil"] = "secure.bypass.norecoil",
        ["aimassist"] = "secure.bypass.aimassist",
        ["all"] = "secure.bypass.all"
    }
    
    if AdminWhitelist.hasAcePermission(source, "secure.bypass.all") then
        return true
    end
    
    local permissionAce = permGroups[permission]
    if permissionAce then
        return AdminWhitelist.hasAcePermission(source, permissionAce)
    end
    
    return false
end

---@description Get all permissions for a player
---@param source number The player source
---@return table permissions Table of permissions the player has
function AdminWhitelist.getPlayerPermissions(source)
    if not source or source <= 0 or not GetPlayerName(source) then
        return {}
    end
    
    local permissions = {}
    local isAdmin = AdminWhitelist.isAdmin(source)
    
    if isAdmin then
        permissions = {
            teleport = true,
            visions = true,
            speedhack = true,
            spectate = true,
            noclip = true,
            ocr = true,
            playerblips = true,
            invisible = true,
            godmode = true,
            freecam = true,
            superjump = true,
            noragdoll = true,
            infinitestamina = true,
            magicbullet = true,
            norecoil = true,
            aimassist = true,
            all = true
        }
        return permissions
    end
    
    if AdminWhitelist.hasAcePermission(source, "secure.bypass.all") then
        permissions = {
            teleport = true,
            visions = true,
            speedhack = true,
            spectate = true,
            noclip = true,
            ocr = true,
            playerblips = true,
            invisible = true,
            godmode = true,
            freecam = true,
            superjump = true,
            noragdoll = true,
            infinitestamina = true,
            magicbullet = true,
            norecoil = true,
            aimassist = true,
            all = true
        }
        return permissions
    end
    
    local permList = {
        "teleport", "visions", "speedhack", "spectate", "noclip", 
        "ocr", "playerblips", "invisible", "godmode", "freecam",
        "superjump", "noragdoll", "infinitestamina", "magicbullet",
        "norecoil", "aimassist"
    }
    
    for _, perm in ipairs(permList) do
        permissions[perm] = AdminWhitelist.hasAcePermission(source, "secure.bypass." .. perm)
    end
    
    return permissions
end

RegisterNetEvent("SecureServe:RequestPermissions", function()
    local src = source
    if not src or src <= 0 or not GetPlayerName(src) then return end
    
    local permissions = AdminWhitelist.getPlayerPermissions(src)
    TriggerClientEvent("SecureServe:ReceivePermissions", src, permissions)
end)

return AdminWhitelist