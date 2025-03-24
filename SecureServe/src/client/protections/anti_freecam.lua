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
        MOVING_CAMERA = 16
    },
    current_flags = 0,
    check_interval = 2000,
    flag_threshold = 3,
    flag_weight = {
        [1] = 1,    -- DISTANCE_EXCEEDED
        [2] = 1,    -- ANGLE_SUSPICIOUS  
        [4] = 2,    -- THROUGH_WALL
        [8] = 1,    -- STATIC_PLAYER
        [16] = 1    -- MOVING_CAMERA
    },
    cooldown = 9000,
    last_detection_time = 0,
    position_history = {},
    history_size = 5,
    distance_threshold = 20.0,
    interior_distance_threshold = 10.0
}

---@description Initialize Anti Freecam protection
function AntiFreecam.initialize()
    if not Anti_Freecam_enabled then 
        if AntiFreecam.debug then print("[AntiFreecam] Protection disabled") end
        return 
    end
    
    if AntiFreecam.debug then print("[AntiFreecam] Protection initialized with flag-based detection") end
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(AntiFreecam.check_interval) 
            
            local playerPed = Cache.Get("ped")
            local playerCoord = Cache.Get("coords")
            local camCoord = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local current_time = GetGameTimer()
            
            if ConfigLoader.is_whitelisted(GetPlayerServerId(PlayerId())) then
                if AntiFreecam.debug then print("[AntiFreecam] Player is whitelisted, skipping checks") end
                goto continue
            end
            
            if (current_time - AntiFreecam.last_detection_time) < AntiFreecam.cooldown then
                if AntiFreecam.debug then print("[AntiFreecam] In cooldown period, resetting flags") end
                AntiFreecam.current_flags = 0
                goto continue
            end
            
            if IsCutsceneActive() or IsPlayerSwitchInProgress() or IsPauseMenuActive() or
               IsFirstPersonAimCamActive() or IsPedInAnyVehicle(playerPed, false) then
                if AntiFreecam.debug then print("[AntiFreecam] Excluded state detected, skipping checks") end
                AntiFreecam.current_flags = 0
                goto continue
            end
            
            -- Store position history
            table.insert(AntiFreecam.position_history, {
                cam = camCoord,
                player = playerCoord,
                time = current_time
            })
            
            if #AntiFreecam.position_history > AntiFreecam.history_size then
                table.remove(AntiFreecam.position_history, 1)
            end
            
            -- Reset flags for new check
            AntiFreecam.current_flags = 0
            
            -- Flag 1: Distance Check
            local distance = #(camCoord - playerCoord)
            local distance_threshold = AntiFreecam.distance_threshold
            
            if GetInteriorFromEntity(playerPed) ~= 0 then
                distance_threshold = AntiFreecam.interior_distance_threshold
                if AntiFreecam.debug then print("[AntiFreecam] Interior detected - using adjusted threshold: " .. distance_threshold) end
            end
            
            if AntiFreecam.debug then print("[AntiFreecam] Distance check: " .. distance .. " / " .. distance_threshold) end
            
            if distance > distance_threshold then
                AntiFreecam.current_flags = AntiFreecam.current_flags | AntiFreecam.flags.DISTANCE_EXCEEDED
                if AntiFreecam.debug then print("[AntiFreecam] Flag added: DISTANCE_EXCEEDED") end
            end
            
            -- Flag 2: Camera Angle Check
            local playerToCam = vector3(camCoord.x - playerCoord.x, camCoord.y - playerCoord.y, camCoord.z - playerCoord.z)
            local camForward = AntiFreecam.GetCamForwardVector(camRot)
            local dotProduct = AntiFreecam.DotProduct(playerToCam, camForward)
            local angle = math.acos(dotProduct / (#playerToCam * #camForward)) * 180 / math.pi
            
            if AntiFreecam.debug then print("[AntiFreecam] Camera angle relative to player: " .. angle) end
            
            if angle > 160 or angle < 20 then
                AntiFreecam.current_flags = AntiFreecam.current_flags | AntiFreecam.flags.ANGLE_SUSPICIOUS
                if AntiFreecam.debug then print("[AntiFreecam] Flag added: ANGLE_SUSPICIOUS") end
            end
            
            -- Flag 3: Through Wall Check
            local ray = StartShapeTestRay(playerCoord.x, playerCoord.y, playerCoord.z, camCoord.x, camCoord.y, camCoord.z, -1, playerPed, 0)
            local _, hit, endCoords, _, _ = GetShapeTestResult(ray)
            
            if hit == 1 then
                local obstacle_distance = #(playerCoord - endCoords)
                local cam_distance = #(playerCoord - camCoord)
                
                if AntiFreecam.debug then 
                    print("[AntiFreecam] Ray hit - Obstacle at: " .. obstacle_distance .. ", Camera at: " .. cam_distance) 
                end
                
                if obstacle_distance < cam_distance and cam_distance > 5.0 then
                    local playerInterior = GetInteriorFromEntity(playerPed)
                    local camInterior = GetInteriorAtCoords(camCoord.x, camCoord.y, camCoord.z)
                    
                    if AntiFreecam.debug then 
                        print("[AntiFreecam] Interior check - Player: " .. playerInterior .. ", Camera: " .. camInterior) 
                    end
                    
                    if playerInterior ~= camInterior then
                        AntiFreecam.current_flags = AntiFreecam.current_flags | AntiFreecam.flags.THROUGH_WALL
                        if AntiFreecam.debug then print("[AntiFreecam] Flag added: THROUGH_WALL") end
                    end
                end
            end
            
            -- Flags 4 & 5: Movement Checks (requires history)
            if #AntiFreecam.position_history >= 3 then
                local newest = AntiFreecam.position_history[#AntiFreecam.position_history]
                local oldest = AntiFreecam.position_history[1]
                
                local cam_movement = #(newest.cam - oldest.cam)
                local player_movement = #(newest.player - oldest.player)
                
                if AntiFreecam.debug then 
                    print("[AntiFreecam] Movement check - Cam: " .. cam_movement .. ", Player: " .. player_movement) 
                end
                
                if player_movement < 0.5 then
                    AntiFreecam.current_flags = AntiFreecam.current_flags | AntiFreecam.flags.STATIC_PLAYER
                    if AntiFreecam.debug then print("[AntiFreecam] Flag added: STATIC_PLAYER") end
                end
                
                if cam_movement > 3.0 and player_movement < 1.0 then
                    AntiFreecam.current_flags = AntiFreecam.current_flags | AntiFreecam.flags.MOVING_CAMERA
                    if AntiFreecam.debug then print("[AntiFreecam] Flag added: MOVING_CAMERA") end
                end
            end
            
            -- Calculate total flag weight
            local flag_weight = 0
            for flag, weight in pairs(AntiFreecam.flag_weight) do
                if AntiFreecam.HasFlag(AntiFreecam.current_flags, flag) then
                    flag_weight = flag_weight + weight
                end
            end
            
            if AntiFreecam.debug then print("[AntiFreecam] Total flag weight: " .. flag_weight .. "/" .. AntiFreecam.flag_threshold) end
            
            -- Check if threshold is exceeded
            if flag_weight >= AntiFreecam.flag_threshold then
                local detection_info = string.format(
                    "Freecam detected - Distance: %.1f, Flags: %d, Weight: %d", 
                    distance, AntiFreecam.current_flags, flag_weight
                )
                
                if AntiFreecam.debug then print("[AntiFreecam] VIOLATION DETECTED: " .. detection_info) end
                
                TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer", nil, 
                    detection_info, 
                    Anti_Freecam_webhook, 
                    2147483647) 
                
                AntiFreecam.current_flags = 0
                AntiFreecam.last_detection_time = current_time
            end
            
            ::continue::
        end
    end)
end

---@description Check if a flag is set in the current flags
---@param flags number The flags value to check
---@param flag number The specific flag to test for
---@return boolean True if the flag is set
function AntiFreecam.HasFlag(flags, flag)
    return (flags & flag) == flag
end

---@description Calculate the dot product of two vectors
---@param v1 vector3 First vector
---@param v2 vector3 Second vector
---@return number The dot product result
function AntiFreecam.DotProduct(v1, v2)
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

---@description Convert rotation to a forward vector
---@param rotation vector3 The rotation to convert
---@return vector3 The resulting forward vector
function AntiFreecam.GetCamForwardVector(rotation)
    local rotationRadians = vector3(
        math.rad(rotation.x),
        math.rad(rotation.y),
        math.rad(rotation.z)
    )
    
    local forward = vector3(
        -math.sin(rotationRadians.z) * math.abs(math.cos(rotationRadians.x)),
        math.cos(rotationRadians.z) * math.abs(math.cos(rotationRadians.x)),
        math.sin(rotationRadians.x)
    )
    
    return forward
end

ProtectionManager.register_protection("freecam", AntiFreecam.initialize)

return AntiFreecam 

