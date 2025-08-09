local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiGodmodeModule
local AntiGodmode = {
    debug = false,
    flags = {
        NO_HEALTH_DECREASE = 1,
        HEALTH_INCREASE = 2,
        NO_ARMOR_DECREASE = 4,
        ARMOR_INCREASE = 8,
        DAMAGE_IMMUNITY = 16,
        SUSPICIOUS_HEALING = 32,
        INSTANT_RECOVERY = 64
    },
    current_flags = 0,
    flag_threshold = 8,
    flag_weight = {
        [1] = 4,   -- No health decrease (high weight)
        [2] = 2,   -- Health increase
        [4] = 3,   -- No armor decrease
        [8] = 2,   -- Armor increase
        [16] = 5,  -- Damage immunity (highest weight)
        [32] = 3,  -- Suspicious healing
        [64] = 4   -- Instant recovery
    },
    cooldown = 10000,
    last_detection_time = 0,
    
    -- Health tracking
    health_history = {},
    armor_history = {},
    history_size = 10,
    expected_damage = 0,
    damage_events = {},
    last_health = 0,
    last_armor = 0,
    
    -- Detection parameters
    max_health = 200,
    max_armor = 100,
    healing_threshold = 20, -- Suspicious if healed more than this instantly
    damage_immunity_threshold = 3, -- Number of damage events to ignore before flagging
}

---@description Track damage events
local function track_damage_event(damage_amount, health_before, armor_before)
    local current_time = GetGameTimer()
    
    table.insert(AntiGodmode.damage_events, {
        time = current_time,
        damage = damage_amount,
        health_before = health_before,
        armor_before = armor_before
    })
    
    -- Clean old events (older than 10 seconds)
    for i = #AntiGodmode.damage_events, 1, -1 do
        if current_time - AntiGodmode.damage_events[i].time > 10000 then
            table.remove(AntiGodmode.damage_events, i)
        end
    end
end

---@description Check health-related flags
local function check_health_flags(current_health, previous_health)
    local flags = 0
    
    -- Track health history
    table.insert(AntiGodmode.health_history, {health = current_health, time = GetGameTimer()})
    if #AntiGodmode.health_history > AntiGodmode.history_size then
        table.remove(AntiGodmode.health_history, 1)
    end
    
    -- Check for suspicious health increases
    if current_health > previous_health then
        local increase = current_health - previous_health
        
        if increase >= AntiGodmode.healing_threshold then
            flags = flags | AntiGodmode.flags.INSTANT_RECOVERY
            if AntiGodmode.debug then
                print(string.format("[AntiGodmode] Instant recovery detected: +%d health", increase))
            end
        end
        
        -- General health increase flag
        flags = flags | AntiGodmode.flags.HEALTH_INCREASE
    end
    
    -- Check if damage was taken but health didn't decrease
    if Cache.Get("damageTaken") and current_health >= previous_health and previous_health > 0 then
        flags = flags | AntiGodmode.flags.NO_HEALTH_DECREASE
        if AntiGodmode.debug then
            print("[AntiGodmode] No health decrease despite damage taken")
        end
    end
    
    -- Check for health values above maximum
    if current_health > AntiGodmode.max_health then
        flags = flags | AntiGodmode.flags.HEALTH_INCREASE
        if AntiGodmode.debug then
            print(string.format("[AntiGodmode] Health above maximum: %d > %d", current_health, AntiGodmode.max_health))
        end
    end
    
    return flags
end

---@description Check armor-related flags
local function check_armor_flags(current_armor, previous_armor)
    local flags = 0
    
    -- Track armor history
    table.insert(AntiGodmode.armor_history, {armor = current_armor, time = GetGameTimer()})
    if #AntiGodmode.armor_history > AntiGodmode.history_size then
        table.remove(AntiGodmode.armor_history, 1)
    end
    
    -- Check for suspicious armor increases
    if current_armor > previous_armor then
        local increase = current_armor - previous_armor
        
        if increase >= AntiGodmode.healing_threshold then
            flags = flags | AntiGodmode.flags.INSTANT_RECOVERY
        end
        
        flags = flags | AntiGodmode.flags.ARMOR_INCREASE
    end
    
    -- Check if damage was taken but armor didn't decrease (when armor should take damage first)
    if Cache.Get("damageTaken") and current_armor >= previous_armor and previous_armor > 0 then
        flags = flags | AntiGodmode.flags.NO_ARMOR_DECREASE
        if AntiGodmode.debug then
            print("[AntiGodmode] No armor decrease despite damage taken")
        end
    end
    
    -- Check for armor values above maximum
    if current_armor > AntiGodmode.max_armor then
        flags = flags | AntiGodmode.flags.ARMOR_INCREASE
    end
    
    return flags
end

---@description Check damage immunity patterns
local function check_damage_immunity()
    local flags = 0
    local recent_damage_events = 0
    local current_time = GetGameTimer()
    
    -- Count recent damage events
    for _, event in ipairs(AntiGodmode.damage_events) do
        if current_time - event.time <= 5000 then -- Last 5 seconds
            recent_damage_events = recent_damage_events + 1
        end
    end
    
    -- If multiple damage events occurred but no health/armor loss
    if recent_damage_events >= AntiGodmode.damage_immunity_threshold then
        flags = flags | AntiGodmode.flags.DAMAGE_IMMUNITY
        if AntiGodmode.debug then
            print(string.format("[AntiGodmode] Damage immunity detected: %d events ignored", recent_damage_events))
        end
    end
    
    return flags
end

---@description Calculate total flag weight
local function calculate_flag_weight(flags)
    local total_weight = 0
    for flag, weight in pairs(AntiGodmode.flag_weight) do
        if (flags & flag) ~= 0 then
            total_weight = total_weight + weight
        end
    end
    return total_weight
end

---@description Main godmode detection logic
local function detect_godmode()
    local current_time = GetGameTimer()
    
    -- Cooldown check
    if current_time - AntiGodmode.last_detection_time < AntiGodmode.cooldown then
        return
    end
    
    local current_health = Cache.Get("health")
    local current_armor = Cache.Get("armor")
    local previous_health = AntiGodmode.last_health
    local previous_armor = AntiGodmode.last_armor
    
    -- Skip first check (no previous values)
    if previous_health == 0 then
        AntiGodmode.last_health = current_health
        AntiGodmode.last_armor = current_armor
        return
    end
    
    AntiGodmode.current_flags = 0
    
    -- Run all detection checks
    AntiGodmode.current_flags = AntiGodmode.current_flags | check_health_flags(current_health, previous_health)
    AntiGodmode.current_flags = AntiGodmode.current_flags | check_armor_flags(current_armor, previous_armor)
    AntiGodmode.current_flags = AntiGodmode.current_flags | check_damage_immunity()
    
    -- Calculate weighted score
    local flag_weight = calculate_flag_weight(AntiGodmode.current_flags)
    
    if flag_weight >= AntiGodmode.flag_threshold then
        AntiGodmode.last_detection_time = current_time
        
        local violation_data = {
            type = "godmode",
            flags = AntiGodmode.current_flags,
            weight = flag_weight,
            current_health = current_health,
            previous_health = previous_health,
            current_armor = current_armor,
            previous_armor = previous_armor,
            damage_events = #AntiGodmode.damage_events
        }
        
        TriggerServerEvent("SecureServe:ViolationDetected", violation_data)
        
        if AntiGodmode.debug then
            print(string.format("[AntiGodmode] VIOLATION DETECTED - Flags: %d, Weight: %d", 
                  AntiGodmode.current_flags, flag_weight))
        end
    end
    
    -- Update previous values
    AntiGodmode.last_health = current_health
    AntiGodmode.last_armor = current_armor
    
    -- Reset damage taken flag after check
    if Cache.Values.damageTaken then
        Cache.Values.damageTaken = false
    end
end

---@description Initialize Anti Godmode protection
function AntiGodmode.initialize()
    if not ConfigLoader.get_protection_setting("Anti Godmode", "enabled") then return end
    
    if AntiGodmode.debug then print("[AntiGodmode] Protection initialized with damage tracking") end
    
    -- Initialize values
    AntiGodmode.last_health = Cache.Get("health")
    AntiGodmode.last_armor = Cache.Get("armor")
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000) -- Check every second for godmode
            
            if Cache.Get("hasPermission", "godmode") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end
            
            detect_godmode()
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("godmode", AntiGodmode.initialize)
return AntiGodmode