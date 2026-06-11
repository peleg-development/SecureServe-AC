---@class AntiCreateEntityModule
local AntiCreateEntity = {
    entityRegistry = {},
    allowedHashes = {},
    resourceWhitelist = {} 
}

local config_manager = require("server/core/config_manager")
local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")
local auto_config = require("server/core/auto_config")

---@param modelHash number Hash of the model to check
---@return boolean isAllowed Whether the model hash is allowed
function AntiCreateEntity.isHashAllowed(modelHash)
    return AntiCreateEntity.allowedHashes[modelHash] == true
end

---@param hash number Hash to allow
function AntiCreateEntity.allowHash(hash)
    AntiCreateEntity.allowedHashes[hash] = true
end

---@param resourceName string Name of the resource
---@param modelHash number Hash of the model
---@return boolean isWhitelisted Whether the resource is whitelisted for the model
function AntiCreateEntity.isResourceWhitelisted(resourceName, modelHash)
    if resourceName == GetCurrentResourceName() then
        return true
    end

    if config_manager.is_entity_resource_whitelisted and config_manager.is_entity_resource_whitelisted(resourceName) then
        return true
    end
    
    local resourceRules = AntiCreateEntity.resourceWhitelist[resourceName]
    if resourceRules == true then
        return true
    end

    if type(resourceRules) == "table" then
        for _, hash in pairs(resourceRules) do
            if hash == modelHash then
                return true
            end
        end
    end
    
    if AntiCreateEntity.isHashAllowed(modelHash) then
        return true
    end
    
    return false
end

function AntiCreateEntity.initialize()
        if SecureServe and SecureServe.Module and SecureServe.Module.Entity and SecureServe.Module.Entity.SecurityWhitelist then
            for _, entry in ipairs(SecureServe.Module.Entity.SecurityWhitelist) do
                if entry and entry.resource and entry.whitelist then
                    AntiCreateEntity.resourceWhitelist[entry.resource] = entry.whitelist
                end
            end
            logger.info("Loaded " .. tostring(#SecureServe.Module.Entity.SecurityWhitelist) .. " whitelisted resources for entity security")
        end


    RegisterNetEvent("SecureServe:Server:Methods:ModulePunish", function(screenshot, reason, webhook, time)
        local src = source
        if not src or src <= 0 then return end

        -- Fix: reason comes from the client, so we bound it and force a string (anti-injection, and limits abuse of the auto-whitelist via a forged reason).
        if type(reason) ~= "string" or reason == "" then reason = "Entity Security Detection" end
        if #reason > 200 then reason = reason:sub(1, 200) end

        logger.warn(string.format("[SecureServe] Entity Security: Player %s (%s) %s",
            GetPlayerName(src) or "Unknown",
            GetPlayerIdentifier(src, 0) or "Unknown",
            reason))

        if auto_config.process_auto_whitelist(src, reason) then
            logger.info("Auto-config handled entity security detection: " .. reason)
            return
        end

        -- Fix: ban duration is resolved server-side (the client must not be able to shorten its own ban via time).
        local details = {
            detection = reason,
            time = config_manager.resolve_ban_time(reason),
            screenshot = screenshot
        }
        
        print("[SecureServe] Incase this is a false ban go to config.lua and in it search SecureServe.Module incase this is an event ban go to Events and then to whitelist and add the event")
        print("[SecureServe] Incase its an entity ban go to Entity and SecurityWhitelist and add the resource name")
        if not screenshot and SecureServe.Module.Entity.TakeScreenshot then
            TriggerClientCallback({
                source    = src,
                eventName = 'SecureServe:CaptureClientScreenshot',
                args      = { 'jpg', 0.85 },
                timeout   = 15,
                timedout  = function()
                    ban_manager.ban_player(src, reason, details)
                end,
                callback  = function(data)
                    if data then details.screenshot = data end
                    ban_manager.ban_player(src, reason, details)
                end,
            })
        else
            ban_manager.ban_player(src, reason, details)
        end
        
        if AntiCreateEntity.entityRegistry[src] then
            for entityId, _ in pairs(AntiCreateEntity.entityRegistry[src]) do
                if type(entityId) == "number" and DoesEntityExist(entityId) then
                    DeleteEntity(entityId)
                end
            end
        end
    end)

    RegisterNetEvent("clearall", function()
        local src = source
        if not src or src <= 0 then return end
        
        if AntiCreateEntity.entityRegistry[src] then
            for entityId, _ in pairs(AntiCreateEntity.entityRegistry[src]) do
                if type(entityId) == "number" and DoesEntityExist(entityId) then
                    DeleteEntity(entityId)
                end
            end
        end
    end)
    
    AddEventHandler("SecureServe:Server:Methods:Entity:CreateServer", function(entityId, resourceName, modelHash)
        if source and tonumber(source) and tonumber(source) > 0 then return end
        if not modelHash then return end
        AntiCreateEntity.allowHash(modelHash)
    end)

    RegisterNetEvent("SecureServe:Server:Methods:Entity:Create", function(entityId, resourceName, modelHash)
        local src = source
        if not src or src <= 0 then return end
        if GetPlayerPing(src) <= 0 then return end
        if not AntiCreateEntity.entityRegistry[src] then
            AntiCreateEntity.entityRegistry[src] = {}
        end

        -- Fix: we no longer trust the modelHash announced by the client (it allowed pre-whitelisting any blacklisted hash). We resolve the real entity and read its actual model server-side; if it does not exist yet we register nothing (the entityCreated check takes over).
        local serverEntityId = NetworkGetEntityFromNetworkId(entityId)
        if not serverEntityId or not DoesEntityExist(serverEntityId) then return end

        local realHash = GetEntityModel(serverEntityId)
        AntiCreateEntity.entityRegistry[src][serverEntityId] = {
            hash = realHash,
            resource = resourceName,
            time = os.time()
        }
        AntiCreateEntity.entityRegistry[src][realHash] = {
            hash = realHash,
            resource = resourceName,
            time = os.time()
        }
    end)

    AddEventHandler('entityCreated', function(entity)
        if not entity or not DoesEntityExist(entity) then return end

        local owner = NetworkGetFirstEntityOwner(entity)
        local population = GetEntityPopulationType(entity)
        local modelHash = GetEntityModel(entity)
        
        if (population == 7 or population == 0) and owner ~= 0 and owner ~= -1 then
            if AntiCreateEntity.isHashAllowed(modelHash) then
                return
            end
            
            if config_manager.is_debug_mode_enabled() then
                logger.info(json.encode(AntiCreateEntity.entityRegistry[owner]))
            end
            
            if AntiCreateEntity.entityRegistry[owner] and (AntiCreateEntity.entityRegistry[owner][entity] or AntiCreateEntity.entityRegistry[owner][modelHash]) then 
                return
            elseif AntiCreateEntity.entityRegistry[0] and (AntiCreateEntity.entityRegistry[0][entity] or AntiCreateEntity.entityRegistry[0][modelHash]) then
                return
            elseif owner and modelHash then
                TriggerClientEvent("SecureServe:CheckEntityResource", owner, NetworkGetNetworkIdFromEntity(entity), modelHash)
            end
        end
    end)

    -- Function to get server entity data from registry
    ---@param playerId number The ID of the player
    ---@param entityId number The entity ID to look up
    ---@return table|nil entityData The entity data or nil if not found
    function AntiCreateEntity.getEntityData(playerId, entityId)
        if AntiCreateEntity.entityRegistry[playerId] and AntiCreateEntity.entityRegistry[playerId][entityId] then
            return AntiCreateEntity.entityRegistry[playerId][entityId]
        end
        return nil
    end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) 
            local currentTime = os.time()
            for playerId, entities in pairs(AntiCreateEntity.entityRegistry) do
                for entityId, data in pairs(entities) do
                    if type(data) == "table" and data.time and currentTime - data.time > 300 then
                        entities[entityId] = nil
                    end
                    
                    if type(entityId) == "number" and not DoesEntityExist(entityId) then
                        entities[entityId] = nil
                    end
                end
                
                if next(entities) == nil then
                    AntiCreateEntity.entityRegistry[playerId] = nil
                end
            end
        end
    end)
    
    AddEventHandler("playerDropped", function()
        local src = source
        if AntiCreateEntity.entityRegistry[src] then
            for entityId, _ in pairs(AntiCreateEntity.entityRegistry[src]) do
                if type(entityId) == "number" and DoesEntityExist(entityId) then
                    DeleteEntity(entityId)
                end
            end
            
            AntiCreateEntity.entityRegistry[src] = nil
        end
    end)
end

return AntiCreateEntity
