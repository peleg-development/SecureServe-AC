local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiInvisibleModule
local AntiInvisible = {
    debug = false,
    flags = {
        ENTITY_INVISIBLE = 1,
        ALPHA_MODIFIED = 2,
        COLLISION_DISABLED = 4,
        RENDERING_DISABLED = 8,
        PERSISTENT_INVISIBLE = 16
    },
    current_flags = 0,
    flag_threshold = 3,
    flag_weight = {
        [1] = 3,   -- Entity invisible
        [2] = 2,   -- Alpha modified
        [4] = 2,   -- Collision disabled
        [8] = 3,   -- Rendering disabled
        [16] = 4   -- Persistent invisible (highest weight)
    },
    cooldown = 8000,
    last_detection_time = 0,
    
    -- Detection tracking
    invisible_count = 0,
    max_invisible_count = 3, -- Allow some brief invisibility
    check_interval = 3000,
    alpha_threshold = 50 -- Below this alpha value is considered suspicious
}

---@description Check entity visibility flags
local function check_visibility_flags()
    local flags = 0
    local ped = Cache.Get("ped")
    
    -- Check if entity is invisible
    if not IsEntityVisible(ped) then
        flags = flags | AntiInvisible.flags.ENTITY_INVISIBLE
        AntiInvisible.invisible_count = AntiInvisible.invisible_count + 1
        
        if AntiInvisible.debug then
            print("[AntiInvisible] Entity invisible detected")
        end
    else
        AntiInvisible.invisible_count = 0
    end
    
    -- Check entity alpha
    local alpha = GetEntityAlpha(ped)
    if alpha < AntiInvisible.alpha_threshold then
        flags = flags | AntiInvisible.flags.ALPHA_MODIFIED
        if AntiInvisible.debug then
            print(string.format("[AntiInvisible] Low alpha detected: %d", alpha))
        end
    end
    
    -- Check if collision is disabled (can indicate invisibility exploits)
    if not DoesEntityHavePhysics(ped) and GetEntityType(ped) == 1 then -- Type 1 = Ped
        flags = flags | AntiInvisible.flags.COLLISION_DISABLED
        if AntiInvisible.debug then
            print("[AntiInvisible] Collision disabled detected")
        end
    end
    
    -- Check persistent invisibility
    if AntiInvisible.invisible_count >= AntiInvisible.max_invisible_count then
        flags = flags | AntiInvisible.flags.PERSISTENT_INVISIBLE
        if AntiInvisible.debug then
            print(string.format("[AntiInvisible] Persistent invisibility: %d counts", AntiInvisible.invisible_count))
        end
    end
    
    return flags
end

---@description Check advanced invisibility methods
local function check_advanced_invisibility()
    local flags = 0
    local ped = Cache.Get("ped")
    
    -- Check if ped is being rendered
    if IsEntityOnScreen(ped) then
        -- Entity is on screen but check if it's actually being rendered
        local coords = Cache.Get("coords")
        local _, isOnScreen = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
        
        if not isOnScreen and IsEntityVisible(ped) then
            -- This could indicate rendering manipulation
            flags = flags | AntiInvisible.flags.RENDERING_DISABLED
            if AntiInvisible.debug then
                print("[AntiInvisible] Rendering manipulation detected")
            end
        end
    end
    
    return flags
end

---@description Calculate total flag weight
local function calculate_flag_weight(flags)
    local total_weight = 0
    for flag, weight in pairs(AntiInvisible.flag_weight) do
        if (flags & flag) ~= 0 then
            total_weight = total_weight + weight
        end
    end
    return total_weight
end

---@description Main invisibility detection logic
local function detect_invisibility()
    local current_time = GetGameTimer()
    
    -- Cooldown check
    if current_time - AntiInvisible.last_detection_time < AntiInvisible.cooldown then
        return
    end
    
    AntiInvisible.current_flags = 0
    
    -- Run all detection checks
    AntiInvisible.current_flags = AntiInvisible.current_flags | check_visibility_flags()
    AntiInvisible.current_flags = AntiInvisible.current_flags | check_advanced_invisibility()
    
    -- Calculate weighted score
    local flag_weight = calculate_flag_weight(AntiInvisible.current_flags)
    
    if flag_weight >= AntiInvisible.flag_threshold then
        AntiInvisible.last_detection_time = current_time
        
        local ped = Cache.Get("ped")
        local violation_data = {
            type = "invisibility",
            flags = AntiInvisible.current_flags,
            weight = flag_weight,
            entity_visible = IsEntityVisible(ped),
            entity_alpha = GetEntityAlpha(ped),
            invisible_count = AntiInvisible.invisible_count,
            coords = Cache.Get("coords")
        }
        
        TriggerServerEvent("SecureServe:ViolationDetected", violation_data)
        
        if AntiInvisible.debug then
            print(string.format("[AntiInvisible] VIOLATION DETECTED - Flags: %d, Weight: %d, Alpha: %d", 
                  AntiInvisible.current_flags, flag_weight, GetEntityAlpha(ped)))
        end
    end
end

---@description Initialize Anti Invisible protection
function AntiInvisible.initialize()
    if not ConfigLoader.get_protection_setting("Anti Invisible", "enabled") then return end
    
    if AntiInvisible.debug then print("[AntiInvisible] Protection initialized with visibility tracking") end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(AntiInvisible.check_interval)
            
            if Cache.Get("hasPermission", "invisible") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                -- Reset counters for permitted users
                AntiInvisible.invisible_count = 0
                goto continue
            end
            
            detect_invisibility()
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("invisible", AntiInvisible.initialize)
return AntiInvisible