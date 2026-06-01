---@class AntiCreateEntityModule
local AntiCreateEntity = {
    entityRegistry = {},
    allowedHashes = {},
    resourceWhitelist = {},
    grace_until = 0,
    grace_seconds = 30,
}

local config_manager = require("server/core/config_manager")
local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")

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

    local entry = AntiCreateEntity.resourceWhitelist[resourceName]
    if entry then
        -- Boolean true => unrestricted access for any model from this resource.
        if entry == true then
            return true
        end
        -- Array => list of allowed hashes.
        if type(entry) == "table" then
            for _, hash in pairs(entry) do
                if hash == modelHash then
                    return true
                end
            end
        end
    end

    if AntiCreateEntity.isHashAllowed(modelHash) then
        return true
    end

    return false
end

function AntiCreateEntity.initialize()
    AntiCreateEntity.grace_until = os.time() + AntiCreateEntity.grace_seconds

    if SecureServe and SecureServe.Module and SecureServe.Module.Entity and SecureServe.Module.Entity.SecurityWhitelist then
        for _, entry in ipairs(SecureServe.Module.Entity.SecurityWhitelist) do
            if entry and entry.resource then
                local wl = entry.whitelist
                if wl == true then
                    -- "allow everything from this resource"
                    AntiCreateEntity.resourceWhitelist[entry.resource] = true
                elseif type(wl) == "table" then
                    AntiCreateEntity.resourceWhitelist[entry.resource] = wl
                end
                -- Anything else (false / nil / number) is ignored intentionally.
            end
        end
        logger.info("Loaded " .. tostring(#SecureServe.Module.Entity.SecurityWhitelist) .. " whitelisted resources for entity security")
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
        
        local reg = AntiCreateEntity.entityRegistry[src]
        if reg and reg.entities then
            for entityId, _ in pairs(reg.entities) do
                if type(entityId) == "number" and DoesEntityExist(entityId) then
                    DeleteEntity(entityId)
                end
            end
        end
    end)

    RegisterNetEvent("SecureServe:Entity:ClearAll", function()
        local src = source
        if not src or src <= 0 then return end

        local reg = AntiCreateEntity.entityRegistry[src]
        if reg and reg.entities then
            for entityId, _ in pairs(reg.entities) do
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
        if type(entityId) ~= "number" or type(modelHash) ~= "number" then return end
        if type(resourceName) ~= "string" or #resourceName > 100 then return end
        -- Sanity: ensure the source still exists. Avoid the old "ping <= 0"
        -- check, which used to reject players that had just connected.
        if not GetPlayerName(tonumber(src)) then return end

        if not AntiCreateEntity.entityRegistry[src] then
            AntiCreateEntity.entityRegistry[src] = { entities = {}, hashes = {} }
        end
        local reg = AntiCreateEntity.entityRegistry[src]
        if not reg.entities then reg.entities = {} end
        if not reg.hashes then reg.hashes = {} end

        local serverEntityId = NetworkGetEntityFromNetworkId(entityId)
        if serverEntityId and DoesEntityExist(serverEntityId) then
            local owner = NetworkGetFirstEntityOwner(serverEntityId)
            if owner ~= src then
                return
            end
            reg.entities[serverEntityId] = {
                hash = modelHash,
                resource = resourceName,
                time = os.time()
            }
        end

        if not reg.hashes[modelHash] then
            reg.hashes[modelHash] = {
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

            local reg = AntiCreateEntity.entityRegistry[owner]
            local reg0 = AntiCreateEntity.entityRegistry[0]

            if reg and reg.entities and (reg.entities[entity] or (reg.hashes and reg.hashes[modelHash])) then
                return
            elseif reg0 and reg0.entities and (reg0.entities[entity] or (reg0.hashes and reg0.hashes[modelHash])) then
                return
            elseif owner and modelHash then
                if os.time() < AntiCreateEntity.grace_until then
                    AntiCreateEntity.allowHash(modelHash)
                    return
                end
                TriggerClientEvent("SecureServe:CheckEntityResource", owner, NetworkGetNetworkIdFromEntity(entity), modelHash)
            end
        end
    end)

    function AntiCreateEntity.getEntityData(playerId, entityId)
        local reg = AntiCreateEntity.entityRegistry[playerId]
        if reg and reg.entities and reg.entities[entityId] then
            return reg.entities[entityId]
        end
        return nil
    end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000)
            local currentTime = os.time()
            for playerId, reg in pairs(AntiCreateEntity.entityRegistry) do
                if type(reg) == "table" then
                    if reg.entities then
                        for entityId, data in pairs(reg.entities) do
                            if data.time and currentTime - data.time > 300 then
                                reg.entities[entityId] = nil
                            elseif type(entityId) == "number" and not DoesEntityExist(entityId) then
                                reg.entities[entityId] = nil
                            end
                        end
                    end
                    if reg.hashes then
                        for hash, data in pairs(reg.hashes) do
                            if data.time and currentTime - data.time > 300 then
                                reg.hashes[hash] = nil
                            end
                        end
                    end
                    if (not reg.entities or next(reg.entities) == nil)
                        and (not reg.hashes or next(reg.hashes) == nil)
                    then
                        AntiCreateEntity.entityRegistry[playerId] = nil
                    end
                end
            end
        end
    end)

    AddEventHandler("playerDropped", function()
        local src = source
        local reg = AntiCreateEntity.entityRegistry[src]
        if reg and reg.entities then
            for entityId, _ in pairs(reg.entities) do
                if type(entityId) == "number" and DoesEntityExist(entityId) then
                    DeleteEntity(entityId)
                end
            end
        end
        AntiCreateEntity.entityRegistry[src] = nil
    end)
end

return AntiCreateEntity
