---@class AdminWhitelistModule
local AdminWhitelist = {}

--- huge thx to @zinvera for fixing the memory leak!

local config_manager = require("server/core/config_manager")
local logger = require("server/core/logger")

local detectedFramework = nil
local cachedAdmins = {}
local pendingAdminChecks = {}
local adminCheckCooldown = {}

---@description Initialize the admin whitelist module
function AdminWhitelist.initialize()
    logger.info("^3[INFO] ^7InitialiSecureg Admin Whitelist module")
    
    CreateThread(function()
        while true do
            collectgarbage("collect")
            Wait(600000)
        end
    end)
    
    AdminWhitelist.detectFramework()
    AdminWhitelist.setupAdminSync()
    
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
        local currentTime = os.time()
        
        
        local isWhitelisted = AdminWhitelist.isWhitelisted(src)
        TriggerClientEvent("SecureServe:WhitelistResponse", src, isWhitelisted)
    end)
    
    RegisterNetEvent("SecureServe:RequestAdminList", function()
        local src = source
        local currentTime = os.time()
        
        
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
    
    logger.info("^5[SUCCESS] ^3Admin Whitelist^7 initialized. Framework detected: " .. (detectedFramework or "None"))
end

---@description Detect which framework is being used
function AdminWhitelist.detectFramework()
    local frameworks = {
        { name = "ESX", resource = "es_extended" },
        { name = "QBCore", resource = "qb-core" },
        { name = "vRP", resource = "vrp" },
        { name = "ox_core", resource = "ox_core" }
    }
    
    for _, fw in ipairs(frameworks) do
        if GetResourceState(fw.resource) == "started" then
            detectedFramework = fw.name
            logger.info("^3[INFO] ^7" .. fw.name .. " framework detected")
            return
        end
    end
    

    
    logger.info("^3[INFO] ^7No framework detected, will use manual whitelist")
end

---@description Set up events to synchronize admin list
function AdminWhitelist.setupAdminSync()
    CreateThread(function()
        while true do
            Wait(300000) 
            AdminWhitelist.refreshAdminList()
        end
    end)
    
    RegisterCommand("Secureadmins", function(source)
        if source ~= 0 then 
            return
        end
        
        AdminWhitelist.refreshAdminList()
        logger.info("^2[SUCCESS] Admin whitelist refreshed^7")
    end, true)
end

---@description Get admin status from ESX
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getESXAdmin(source)
    local status, result = pcall(function()
        if not _G.exports or not _G.exports["es_extended"] then
            return false
        end
        
        local ESX = _G.exports["es_extended"]:getSharedObject()
        if not ESX then return false end
        
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        
        local adminGroups = {"admin", "superadmin", "mod", "moderator", "owner", "dev", "staff"}
        
        local playerGroup = nil
        
        if xPlayer.getGroup then 
            playerGroup = xPlayer.getGroup()
        elseif xPlayer.group then
            playerGroup = xPlayer.group
        elseif xPlayer.permission_level then
            return xPlayer.permission_level >= 1
        end
        
        if playerGroup then
            for _, adminGroup in ipairs(adminGroups) do
                if playerGroup == adminGroup then
                    return true
                end
            end
        end
        
        if xPlayer.isAdmin then
            return xPlayer.isAdmin()
        end
        
        if ESX.IsPlayerAdmin then
            return ESX.IsPlayerAdmin(source)
        end
        
        return false
    end)
    
    return status and result or false
end

---@description Get admin status from QBCore
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getQBCoreAdmin(source)
    local status, result = pcall(function()
        if not _G.exports or not _G.exports["qb-core"] then
            return false
        end
        
        local QBCore = _G.exports["qb-core"]:GetCoreObject()
        if not QBCore then return false end
        
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end

        if QBCore.Functions.HasPermission then
            return QBCore.Functions.HasPermission(source, "admin") or
                   QBCore.Functions.HasPermission(source, "god") or
                   QBCore.Functions.HasPermission(source, "mod")
        end
        
        if Player.PlayerData.group then
            local adminGroups = {"admin", "superadmin", "god", "mod"}
            for _, group in pairs(adminGroups) do
                if Player.PlayerData.group == group then
                    return true
                end
            end
        end
        
        if QBCore.Functions.IsPlayerAdmin then
            return QBCore.Functions.IsPlayerAdmin(source)
        end
        
        return false
    end)
    
    return status and result or false
end

---@description Get admin status from vRP
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getVRPAdmin(source)
    local status, result = pcall(function()
        if not _G.exports or not _G.exports.vrp then
            if not vRP then
                return false
            end
        end
        
        local vRPInstance = nil
        
        if _G.exports and _G.exports.vrp then
            vRPInstance = _G.exports.vrp:getSharedObject()
        elseif vRP then
            vRPInstance = vRP
        end
        
        if not vRPInstance then return false end
        
        local user_id = nil
        
        if vRPInstance.getUserId and type(vRPInstance.getUserId) == "function" then
            if pcall(function() return vRPInstance.getUserId(source) end) then
                user_id = vRPInstance.getUserId(source)
            elseif pcall(function() return vRPInstance.getUserId({source}) end) then
                user_id = vRPInstance.getUserId({source})
            end
        end
        
        if not user_id and vRPInstance.users and vRPInstance.users[source] then
            user_id = vRPInstance.users[source]
        end
        
        if not user_id then return false end
        
        local adminGroups = {"admin", "superadmin", "moderator", "owner", "staff", "founder", "headadmin", "senior_admin"}
        
        for _, group in ipairs(adminGroups) do
            if vRPInstance.hasGroup and type(vRPInstance.hasGroup) == "function" then
                if pcall(function() return vRPInstance.hasGroup(user_id, group) end) and vRPInstance.hasGroup(user_id, group) then
                    return true
                elseif pcall(function() return vRPInstance.hasGroup({user_id, group}) end) and vRPInstance.hasGroup({user_id, group}) then
                    return true
                end
            elseif vRPInstance.hasPermission and vRPInstance.hasPermission(user_id, "admin") then
                return true
            elseif vRPInstance.isUserAdmin and vRPInstance.isUserAdmin(user_id) then
                return true
            end
            
            if vRPInstance.users and vRPInstance.users[user_id] and vRPInstance.users[user_id].groups and vRPInstance.users[user_id].groups[group] then
                return true
            end
        end
        
        return false
    end)
    
    return status and result or false
end

---@description Get admin status from txAdmin
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getTxAdminPerm(source)
    local status, result = pcall(function()
        local adminPrincipal = "txAdmin.permissions"
        return IsPlayerAceAllowed(source, adminPrincipal)
    end)
    
    return status and result or false
end

---@description Get admin status from ox_core
---@param source number The player source
---@return boolean isAdmin Whether the player is an admin
function AdminWhitelist.getOxAdmin(source)
    local status, result = pcall(function()
        if not _G.exports or not _G.exports.ox_core then
            return false
        end
        
        local hasGroup, hasPermission, getPlayer
        
        if _G.exports.ox_core.GetPlayerGroup then
            hasGroup = _G.exports.ox_core.GetPlayerGroup
        elseif _G.exports.ox_core.hasGroup then
            hasGroup = _G.exports.ox_core.hasGroup
        end
        
        if _G.exports.ox_core.HasPermission then
            hasPermission = _G.exports.ox_core.HasPermission
        elseif _G.exports.ox_core.hasPermission then
            hasPermission = _G.exports.ox_core.hasPermission
        end
        
        if _G.exports.ox_core.GetPlayer then
            getPlayer = _G.exports.ox_core.GetPlayer
        end
        
        local adminGroups = {"admin", "superadmin", "moderator", "owner", "staff", "developer"}
        
        if hasGroup then
            for _, group in ipairs(adminGroups) do
                local success, result = pcall(function()
                    return hasGroup(source, group)
                end)
                
                if success and result then
                    return true
                end
            end
        end
        
        if hasPermission then
            local permissionChecks = {"admin", "admin.join", "admin.commands", "command.*"}
            
            for _, perm in ipairs(permissionChecks) do
                local success, result = pcall(function()
                    return hasPermission(source, perm)
                end)
                
                if success and result then
                    return true
                end
            end
        end
        
        if getPlayer then
            local player = getPlayer(source)
            
            if player and player.group then
                for _, group in ipairs(adminGroups) do
                    if player.group == group then
                        return true
                    end
                end
            end
            
            if player and player.isAdmin and type(player.isAdmin) == "function" then
                local success, result = pcall(function()
                    return player:isAdmin()
                end)
                
                if success and result then
                    return true
                end
            end
        end
        
        if IsPlayerAceAllowed then
            local acePermissions = {"ox.admin", "ox.command", "ox.moderate", "admin"}
            
            for _, ace in ipairs(acePermissions) do
                if IsPlayerAceAllowed(source, ace) then
                    return true
                end
            end
        end
        
        return false
    end)
    
    return status and result or false
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
    
    if detectedFramework == "ESX" then
        isAdmin = AdminWhitelist.getESXAdmin(source)
    elseif detectedFramework == "QBCore" then
        
        isAdmin = AdminWhitelist.getQBCoreAdmin(source)
    elseif detectedFramework == "vRP" then
        isAdmin = AdminWhitelist.getVRPAdmin(source)
    elseif detectedFramework == "ox_core" then
        isAdmin = AdminWhitelist.getOxAdmin(source)
    end
    
    cachedAdmins[source] = isAdmin
    return isAdmin or AdminWhitelist.getTxAdminPerm(source)
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
    local src = tonumber(source)
    if not src or src <= 0 or not GetPlayerName(src) then
        return
    end

    if not _G.SecureServe then _G.SecureServe = {} end
    if not _G.SecureServe.Whitelisted then _G.SecureServe.Whitelisted = {} end
    
    if AdminWhitelist.isAdmin(src) then
        local alreadyWhitelisted = false
        for _, id in ipairs(_G.SecureServe.Whitelisted) do
            if tonumber(id) == src then
                alreadyWhitelisted = true
                break
            end
        end
        
        if not alreadyWhitelisted then
            table.insert(_G.SecureServe.Whitelisted, src)
            local playerName = GetPlayerName(src) or "Unknown"
            logger.info("Auto-whitelisted admin player: " .. playerName .. " (ID: " .. src .. ")")
        end
    end
end

---@description Refresh the admin list for all players
function AdminWhitelist.refreshAdminList()
    cachedAdmins = {}
    
    local players = GetPlayers()
    local batchSize = 5
    
    CreateThread(function()
        for i = 1, #players, batchSize do
            local endIdx = math.min(i + batchSize - 1, #players)
            
            for j = i, endIdx do
                local src = tonumber(players[j])
                if src then
                    AdminWhitelist.checkAndAddAdmin(src)
                end
            end
            
            Wait(100) 
        end
        
        logger.info("Admin whitelist refresh completed")
    end)
end

return AdminWhitelist