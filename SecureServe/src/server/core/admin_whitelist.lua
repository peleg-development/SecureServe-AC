---@class AdminWhitelistModule
local AdminWhitelist = {}

local config_manager = require("server/core/config_manager")
local logger = require("server/core/logger")

local detectedFramework = nil
local cachedAdmins = {}

---@description Initialize the admin whitelist module
function AdminWhitelist.initialize()
    print("^3[INFO] ^7Initializing Admin Whitelist module")
    
    AdminWhitelist.detectFramework()
    
    AdminWhitelist.setupAdminSync()
    
    AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
        local source = source
        AdminWhitelist.checkAndAddAdmin(source)
    end)
    
    print("^5[SUCCESS] ^3Admin Whitelist^7 initialized. Framework detected: " .. (detectedFramework or "None"))
end

---@description Detect which framework is being used
function AdminWhitelist.detectFramework()
    if GetResourceState("es_extended") == "started" then
        detectedFramework = "ESX"
        print("^3[INFO] ^7ESX framework detected")
        return
    end
    
    if GetResourceState("qb-core") == "started" then
        detectedFramework = "QBCore"
        print("^3[INFO] ^7QBCore framework detected")
        return
    end
    
    if GetResourceState("vrp") == "started" then
        detectedFramework = "vRP"
        print("^3[INFO] ^7vRP framework detected")
        return
    end
    
    if GetConvar("txAdmin-version", "none") ~= "none" then
        detectedFramework = "txAdmin"
        print("^3[INFO] ^7txAdmin detected")
        return
    end
    
    if GetResourceState("ox_core") == "started" then
        detectedFramework = "ox_core"
        print("^3[INFO] ^7ox_core framework detected")
        return
    end
    
    print("^3[INFO] ^7No framework detected, will use manual whitelist")
end

---@description Set up events to synchronize admin list
function AdminWhitelist.setupAdminSync()
    CreateThread(function()
        while true do
            Wait(60000) -- Check every minute
            AdminWhitelist.refreshAdminList()
        end
    end)
    
    exports("refreshAdminWhitelist", function()
        AdminWhitelist.refreshAdminList()
        return true
    end)
    
    RegisterCommand("secureadmins", function(source, args)
        if source ~= 0 then 
            return
        end
        
        AdminWhitelist.refreshAdminList()
        print("^2[SUCCESS] Admin whitelist refreshed^7")
    end, true)
end

---@description Get admin status from ESX
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getESXAdmin(source)
    local ESX = exports["es_extended"]:getSharedObject()
    if not ESX then return false end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    local adminGroups = {"admin", "superadmin", "mod", "moderator", "owner"}
    local playerGroup = xPlayer.getGroup()
    
    for _, adminGroup in ipairs(adminGroups) do
        if playerGroup == adminGroup then
            return true
        end
    end
    
    return false
end

---@description Get admin status from QBCore
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getQBCoreAdmin(source)
    local QBCore = exports["qb-core"]:GetCoreObject()
    if not QBCore then return false end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local adminPermissions = {"admin", "god"}
    local playerPermission = Player.PlayerData.permission
    
    if type(playerPermission) == "string" then
        for _, perm in ipairs(adminPermissions) do
            if playerPermission == perm then
                return true
            end
        end
    elseif type(playerPermission) == "table" then
        for _, perm in ipairs(adminPermissions) do
            for _, playerPerm in ipairs(playerPermission) do
                if playerPerm == perm then
                    return true
                end
            end
        end
    end
    
    return false
end

---@description Get admin status from vRP
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getVRPAdmin(source)
    local vRP = exports.vrp:getSharedObject()
    if not vRP then return false end
    
    local user_id = vRP.getUserId({source})
    if not user_id then return false end
    
    local adminGroups = {"admin", "superadmin", "moderator", "owner", "staff"}
    
    for _, group in ipairs(adminGroups) do
        if vRP.hasGroup({user_id, group}) then
            return true
        end
    end
    
    return false
end

---@description Get admin status from txAdmin
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getTxAdminPerm(source)
    local identifiers = GetPlayerIdentifiers(source)
    
    for _, id in pairs(identifiers) do
        if string.find(id, "license:") then
            local license = string.gsub(id, "license:", "")
            local adminPrincipal = "txAdmin.permissions"
            
            if IsPlayerAceAllowed(source, adminPrincipal) then
                return true
            end
        end
    end
    
    return false
end

---@description Get admin status from ox_core
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getOxAdmin(source)
    local hasGroup = exports.ox_core.GetPlayerGroup
    if not hasGroup then return false end
    
    local adminGroups = {"admin", "superadmin", "moderator", "owner", "staff"}
    
    for _, group in ipairs(adminGroups) do
        if hasGroup(source, group) then
            return true
        end
    end
    
    return false
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

---@description Check if a player is an admin through any method
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.isAdmin(source)
    if cachedAdmins[source] ~= nil then
        return cachedAdmins[source]
    end
    
    if AdminWhitelist.getManualAdmin(source) then
        cachedAdmins[source] = true
        return true
    end
    
    local isAdmin = false
    
    if detectedFramework == "ESX" then
        isAdmin = AdminWhitelist.getESXAdmin(source)
    elseif detectedFramework == "QBCore" then
        isAdmin = AdminWhitelist.getQBCoreAdmin(source)
    elseif detectedFramework == "vRP" then
        isAdmin = AdminWhitelist.getVRPAdmin(source)
    elseif detectedFramework == "txAdmin" then
        isAdmin = AdminWhitelist.getTxAdminPerm(source)
    elseif detectedFramework == "ox_core" then
        isAdmin = AdminWhitelist.getOxAdmin(source)
    end
    
    cachedAdmins[source] = isAdmin
    return isAdmin
end

---@description Check if a player is whitelisted (combines admin and manual whitelist)
---@param source number The player source
---@return boolean isWhitelisted Whether the player is whitelisted
function AdminWhitelist.isWhitelisted(source)
    if AdminWhitelist.isAdmin(source) then
        return true
    end
    
    -- Check if player is manually whitelisted
    if _G.SecureServe and _G.SecureServe.Whitelisted then
        for _, id in ipairs(_G.SecureServe.Whitelisted) do
            if tonumber(id) == tonumber(source) then
                return true
            end
        end
    end
    
    return false
end

---@description Check and add player to whitelist if they're an admin
---@param source number The player source
function AdminWhitelist.checkAndAddAdmin(source)
    if not _G.SecureServe then
        _G.SecureServe = {}
    end
    
    if not _G.SecureServe.Whitelisted then
        _G.SecureServe.Whitelisted = {}
    end
    
    if AdminWhitelist.isAdmin(source) then
        local alreadyWhitelisted = false
        
        for _, id in ipairs(_G.SecureServe.Whitelisted) do
            if tonumber(id) == tonumber(source) then
                alreadyWhitelisted = true
                break
            end
        end
        
        if not alreadyWhitelisted then
            table.insert(_G.SecureServe.Whitelisted, source)
            local playerName = GetPlayerName(source) or "Unknown"
            logger.info("Auto-whitelisted admin player: " .. playerName .. " (ID: " .. source .. ")")
        end
    end
end

---@description Refresh the admin list for all players
function AdminWhitelist.refreshAdminList()
    cachedAdmins = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        AdminWhitelist.checkAndAddAdmin(tonumber(playerId))
    end
    
    logger.info("Admin whitelist refreshed")
end

AddEventHandler("playerDropped", function()
    local source = source
    cachedAdmins[source] = nil
end)

RegisterNetEvent("SecureServe:CheckWhitelist", function()
    local source = source
    local isWhitelisted = AdminWhitelist.isWhitelisted(source)
    TriggerClientEvent("SecureServe:WhitelistResponse", source, isWhitelisted)
end)

exports("isPlayerWhitelisted", function(source)
    return AdminWhitelist.isWhitelisted(source)
end)

return AdminWhitelist 