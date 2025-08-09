local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader = require("client/core/config_loader")
local Cache = require("client/core/cache")

---@class AntiFreecamModule
local AntiFreecam = {
    debug = false,
    flags = {
        DISTANCE_EXCEEDED = 1,
        ANGLE_SUSPICIOUS = 2,
        THROUGH_WALL = 4,
        STATIC_PLAYER = 8,
        MOVING_CAMERA = 16,
        RAPID_MOVEMENT = 32,
        HEIGHT_ABUSE = 64
    },
    current_flags = 0,
    check_interval = 1500,
    flag_threshold = 12,
    flag_weight = {
        [1] = 3,   -- Distance exceeded (high weight)
        [2] = 2,   -- Angle suspicious
        [4] = 4,   -- Through wall (very high weight)
        [8] = 2,   -- Static player
        [16] = 3,  -- Moving camera
        [32] = 3,  -- Rapid movement
        [64] = 4   -- Height abuse
    },
    cooldown = 15000,
    last_detection_time = 0,
    
    -- Detection parameters
    position_history = {},
    camera_history = {},
    history_size = 8,
    distance_threshold = 25.0,
    interior_distance_threshold = 15.0,
    height_threshold = 100.0,
    angle_threshold = 90.0,
    movement_speed_threshold = 50.0,
    
    -- State tracking
    last_player_pos = nil,
    last_camera_pos = nil,
    last_camera_rot = nil,
    static_count = 0,
    camera_move_count = 0
}

---@description Check if camera is going through walls
local function is_camera_through_wall(player_pos, camera_pos)
    local raycast = StartShapeTestRay(
        player_pos.x, player_pos.y, player_pos.z,
        camera_pos.x, camera_pos.y, camera_pos.z,
        -1, Cache.Get("ped"), 0
    )
    local _, hit, _, _, _ = GetShapeTestResult(raycast)
    return hit == 1
end

---@description Check camera distance from player
local function check_distance_flags(player_pos, camera_pos)
    local distance = #(player_pos - camera_pos)
    local is_interior = GetInteriorFromEntity(Cache.Get("ped")) ~= 0
    local threshold = is_interior and AntiFreecam.interior_distance_threshold or AntiFreecam.distance_threshold
    
    local flags = 0
    
    -- Distance check
    if distance > threshold then
        flags = flags | AntiFreecam.flags.DISTANCE_EXCEEDED
        if AntiFreecam.debug then
            print(string.format("[AntiFreecam] Distance exceeded: %.2f > %.2f", distance, threshold))
        end
    end
    
    -- Height abuse check
    local height_diff = math.abs(camera_pos.z - player_pos.z)
    if height_diff > AntiFreecam.height_threshold then
        flags = flags | AntiFreecam.flags.HEIGHT_ABUSE
        if AntiFreecam.debug then
            print(string.format("[AntiFreecam] Height abuse: %.2f", height_diff))
        end
    end
    
    -- Through wall check
    if distance > 5.0 and is_camera_through_wall(player_pos, camera_pos) then
        flags = flags | AntiFreecam.flags.THROUGH_WALL
        if AntiFreecam.debug then
            print("[AntiFreecam] Camera through wall detected")
        end
    end
    
    return flags
end

---@description Check camera movement patterns
local function check_movement_flags(camera_pos, camera_rot)
    local flags = 0
    
    -- Track camera position history
    table.insert(AntiFreecam.camera_history, {pos = camera_pos, rot = camera_rot, time = GetGameTimer()})
    if #AntiFreecam.camera_history > AntiFreecam.history_size then
        table.remove(AntiFreecam.camera_history, 1)
    end
    
    if #AntiFreecam.camera_history >= 3 then
        local recent = AntiFreecam.camera_history[#AntiFreecam.camera_history]
        local previous = AntiFreecam.camera_history[#AntiFreecam.camera_history - 2]
        
        -- Check for rapid camera movement
        local distance = #(recent.pos - previous.pos)
        local time_diff = (recent.time - previous.time) / 1000.0
        
        if time_diff > 0 then
            local speed = distance / time_diff
            if speed > AntiFreecam.movement_speed_threshold then
                flags = flags | AntiFreecam.flags.RAPID_MOVEMENT
                if AntiFreecam.debug then
                    print(string.format("[AntiFreecam] Rapid camera movement: %.2f units/sec", speed))
                end
            end
        end
        
        -- Check for suspicious angle changes
        if AntiFreecam.last_camera_rot then
            local angle_diff = math.abs(camera_rot.z - AntiFreecam.last_camera_rot.z)
            if angle_diff > AntiFreecam.angle_threshold then
                flags = flags | AntiFreecam.flags.ANGLE_SUSPICIOUS
                if AntiFreecam.debug then
                    print(string.format("[AntiFreecam] Suspicious angle change: %.2f", angle_diff))
                end
            end
        end
    end
    
    AntiFreecam.last_camera_rot = camera_rot
    return flags
end

---@description Check player movement patterns
local function check_player_flags(player_pos)
    local flags = 0
    
    -- Track player position history
    table.insert(AntiFreecam.position_history, {pos = player_pos, time = GetGameTimer()})
    if #AntiFreecam.position_history > AntiFreecam.history_size then
        table.remove(AntiFreecam.position_history, 1)
    end
    
    -- Check if player is static while camera moves
    if AntiFreecam.last_player_pos then
        local player_moved = #(player_pos - AntiFreecam.last_player_pos) > 1.0
        local camera_moved = AntiFreecam.last_camera_pos and 
                            #(GetGameplayCamCoords() - AntiFreecam.last_camera_pos) > 2.0
        
        if not player_moved and camera_moved then
            AntiFreecam.static_count = AntiFreecam.static_count + 1
            if AntiFreecam.static_count >= 3 then
                flags = flags | AntiFreecam.flags.STATIC_PLAYER
            end
        else
            AntiFreecam.static_count = 0
        end
    end
    
    AntiFreecam.last_player_pos = player_pos
    return flags
end

---@description Calculate total flag weight
local function calculate_flag_weight(flags)
    local total_weight = 0
    for flag, weight in pairs(AntiFreecam.flag_weight) do
        if (flags & flag) ~= 0 then
            total_weight = total_weight + weight
        end
    end
    return total_weight
end

---@description Main freecam detection logic
local function detect_freecam()
    local current_time = GetGameTimer()
    
    -- Cooldown check
    if current_time - AntiFreecam.last_detection_time < AntiFreecam.cooldown then
        return
    end
    
    local player_pos = Cache.Get("coords")
    local camera_pos = GetGameplayCamCoords()
    local camera_rot = GetGameplayCamRot(2)
    
    AntiFreecam.current_flags = 0
    
    -- Run all detection checks
    AntiFreecam.current_flags = AntiFreecam.current_flags | check_distance_flags(player_pos, camera_pos)
    AntiFreecam.current_flags = AntiFreecam.current_flags | check_movement_flags(camera_pos, camera_rot)
    AntiFreecam.current_flags = AntiFreecam.current_flags | check_player_flags(player_pos)
    
    -- Calculate weighted score
    local flag_weight = calculate_flag_weight(AntiFreecam.current_flags)
    
    if flag_weight >= AntiFreecam.flag_threshold then
        AntiFreecam.last_detection_time = current_time
        
        local violation_data = {
            type = "freecam",
            flags = AntiFreecam.current_flags,
            weight = flag_weight,
            player_pos = player_pos,
            camera_pos = camera_pos,
            distance = #(player_pos - camera_pos)
        }
        
        TriggerServerEvent("SecureServe:ViolationDetected", violation_data)
        
        if AntiFreecam.debug then
            print(string.format("[AntiFreecam] VIOLATION DETECTED - Flags: %d, Weight: %d", 
                  AntiFreecam.current_flags, flag_weight))
        end
    end
    
    AntiFreecam.last_camera_pos = camera_pos
end

---@description Initialize Anti Freecam protection
function AntiFreecam.initialize()
    if not ConfigLoader.get_protection_setting("Anti Freecam", "enabled") then return end
    
    if AntiFreecam.debug then print("[AntiFreecam] Protection initialized with advanced detection") end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(AntiFreecam.check_interval)
            
            if Cache.Get("hasPermission", "freecam") or Cache.Get("hasPermission", "all") or Cache.Get("isAdmin") then
                goto continue
            end
            
            detect_freecam()
            
            ::continue::
        end
    end)
end

ProtectionManager.register_protection("freecam", AntiFreecam.initialize)
return AntiFreecam