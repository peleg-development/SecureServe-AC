---@class AntiFakeDeathModule
local AntiFakeDeath = {}

local ban_manager = require("server/core/ban_manager")
local logger = require("server/core/logger")

local playerDeaths = {}
local playerHealthHistory = {}

local DEATH_SPAM_THRESHOLD = 5         -- Max deaths in time window
local DEATH_SPAM_WINDOW = 30000        -- Time window in ms (30 seconds)
local HEALTH_CHECK_INTERVAL = 1000     -- Check health every second

---@description Check if player is spamming death events
local function checkDeathSpam(playerId)
    if not playerDeaths[playerId] then
        playerDeaths[playerId] = {}
    end
    
    local currentTime = os.time() * 1000
    local deaths = playerDeaths[playerId]
    
    -- Add current timestamp
    table.insert(deaths, currentTime)
    
    -- Remove old timestamps outside the window
    for i = #deaths, 1, -1 do
        if currentTime - deaths[i] > DEATH_SPAM_WINDOW then
            table.remove(deaths, i)
        end
    end
    
    -- Check if too many deaths
    if #deaths >= DEATH_SPAM_THRESHOLD then
        return true, #deaths
    end
    
    return false, #deaths
end

---@description Initialize anti-fake death protection
function AntiFakeDeath.initialize()
    -- Track player death events
    RegisterNetEvent('baseevents:onPlayerDied', function(killerType, coords)
        local playerId = source
        if not playerId or playerId <= 0 then return end
        
        -- Check for death spam
        local isSpam, deathCount = checkDeathSpam(playerId)
        if isSpam then
            logger.warn(string.format("[AntiFakeDeath] Player %s death spam: %d deaths in %d seconds", 
                GetPlayerName(playerId), deathCount, DEATH_SPAM_WINDOW / 1000))
            
            ban_manager.ban_player(playerId, "Fake Death", 
                string.format("Death event spam: %d deaths in %d seconds", 
                deathCount, DEATH_SPAM_WINDOW / 1000))
            return
        end
        
        -- Track legitimate death
        logger.debug(string.format("[AntiFakeDeath] Player %s died at %s", 
            GetPlayerName(playerId), coords))
    end)
    
    -- Monitor player health for inconsistencies
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(HEALTH_CHECK_INTERVAL)
            
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdNum = tonumber(playerId)
                if playerIdNum and GetPlayerPing(playerIdNum) > 0 then
                    local ped = GetPlayerPed(playerIdNum)
                    if ped and DoesEntityExist(ped) then
                        local health = GetEntityHealth(ped)
                        local maxHealth = GetEntityMaxHealth(ped)
                        
                        -- Initialize health history
                        if not playerHealthHistory[playerIdNum] then
                            playerHealthHistory[playerIdNum] = {
                                current = health,
                                previous = health,
                                suspicious = 0
                            }
                        end
                        
                        local history = playerHealthHistory[playerIdNum]
                        
                        -- Check for impossible health changes (instant full heal)
                        if history.previous <= 100 and health >= maxHealth then
                            history.suspicious = history.suspicious + 1
                            
                            if history.suspicious >= 3 then
                                logger.warn(string.format("[AntiFakeDeath] Player %s suspicious health change: %d -> %d", 
                                    GetPlayerName(playerIdNum), history.previous, health))
                                
                                ban_manager.ban_player(playerIdNum, "Fake Death", 
                                    string.format("Suspicious health manipulation: %d -> %d", 
                                    history.previous, health))
                                
                                history.suspicious = 0
                            end
                        end
                        
                        -- Check for health above max (godmode indicator)
                        if health > maxHealth + 50 then
                            logger.warn(string.format("[AntiFakeDeath] Player %s health above maximum: %d/%d", 
                                GetPlayerName(playerIdNum), health, maxHealth))
                            
                            ban_manager.ban_player(playerIdNum, "Fake Death", 
                                string.format("Health above maximum: %d/%d", health, maxHealth))
                        end
                        
                        -- Update history
                        history.previous = history.current
                        history.current = health
                    end
                end
            end
        end
    end)
    
    -- Monitor respawn events
    RegisterNetEvent('baseevents:onPlayerWasted', function()
        local playerId = source
        if not playerId or playerId <= 0 then return end
        
        -- Check for rapid respawn (possible exploit)
        if playerDeaths[playerId] and #playerDeaths[playerId] > 0 then
            local lastDeath = playerDeaths[playerId][#playerDeaths[playerId]]
            local currentTime = os.time() * 1000
            
            if currentTime - lastDeath < 1000 then
                logger.warn(string.format("[AntiFakeDeath] Player %s rapid respawn detected", 
                    GetPlayerName(playerId)))
                
                ban_manager.ban_player(playerId, "Fake Death", 
                    "Rapid respawn exploit detected")
            end
        end
    end)
    
    -- Cleanup on player disconnect
    AddEventHandler('playerDropped', function()
        local playerId = source
        playerDeaths[playerId] = nil
        playerHealthHistory[playerId] = nil
    end)
    
    -- Periodic cleanup
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(DEATH_SPAM_WINDOW * 2)
            
            -- Reset suspicious counts periodically
            for playerId, history in pairs(playerHealthHistory) do
                if GetPlayerPing(playerId) <= 0 then
                    playerHealthHistory[playerId] = nil
                else
                    history.suspicious = math.max(0, history.suspicious - 1)
                end
            end
        end
    end)
    
    logger.info("[AntiFakeDeath] Protection initialized")
end

return AntiFakeDeath
