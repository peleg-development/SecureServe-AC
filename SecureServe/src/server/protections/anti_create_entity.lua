---@class AntiCreateEntityModule
local AntiCreateEntity = {
    entityRegistry = {},
    allowedHashes = {},
    resourceWhitelist = {} 
}

local config_manager = require("server/core/config_manager")
local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")
local DiscordLogger = require("server/core/discord_logger")

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
    
    if AntiCreateEntity.resourceWhitelist[resourceName] then
        for _, hash in pairs(AntiCreateEntity.resourceWhitelist[resourceName]) do
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
            AntiCreateEntity.resourceWhitelist[entry.resource] = entry.whitelist
        end
        logger.info("Loaded " .. #SecureServe.Module.Entity.SecurityWhitelist .. " whitelisted resources for entity security")
    end

    RegisterNetEvent("SecureServe:Server:Methods:ModulePunish", function(screenshot, reason, webhook, time)
        local src = source
        if not src or src <= 0 then return end
        
        logger.warn(string.format("[SecureServe] Entity Security: Player %s (%s) %s", 
            GetPlayerName(src) or "Unknown", 
            GetPlayerIdentifier(src, 0) or "Unknown", 
            reason))
        
        local details = {
            detection = reason,
            time = time or 0,
            screenshot = screenshot
        }
        
        print("[SecureServe] Incase this is a false ban go to config.lua and in it search SecureServe.Module incase this is an event ban go to Events and then to whitelist and add the event")
        print("[SecureServe] Incase its an entity ban go to Entity and SecurityWhitelist and add the resource name")
        if not screenshot and SecureServe.Module.Entity.TakeScreenshot then
            exports['screenshot-basic']:requestClientScreenshot(src, {
                fileName = 'entity_' .. src .. '_' .. os.time() .. '.jpg'
            }, function(err, data)
                details.screenshot = data
                ban_manager.ban_player(src, reason, details)
            end)
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
    
    RegisterNetEvent("SecureServe:Server:Methods:Entity:CreateServer", function(entityId, resourceName, modelHash)
        local src = source
        AntiCreateEntity.allowHash(modelHash)
    end)

    RegisterNetEvent("SecureServe:Server:Methods:Entity:Create", function(entityId, resourceName, modelHash)
        local src = source
        if GetPlayerPing(tonumber(src)) <= tonumber(0) then return end
        if not AntiCreateEntity.entityRegistry[src] then
            AntiCreateEntity.entityRegistry[src] = {}
        end
        
        local serverEntityId = NetworkGetEntityFromNetworkId(entityId)
        if serverEntityId and DoesEntityExist(serverEntityId) then
            AntiCreateEntity.entityRegistry[src][serverEntityId] = {
                hash = modelHash,
                resource = resourceName,
                time = os.time()
            }
        end
        
        if not AntiCreateEntity.entityRegistry[src][modelHash] then
            AntiCreateEntity.entityRegistry[src][modelHash] = {
                hash = modelHash,
                resource = resourceName,
                time = os.time()
            }
        end
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
