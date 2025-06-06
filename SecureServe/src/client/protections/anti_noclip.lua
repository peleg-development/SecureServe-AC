local ProtectionManager = require("client/protections/protection_manager")
local ConfigLoader      = require("client/core/config_loader")
local Cache             = require("client/core/cache")

---@class AntiNoclipModule
local AntiNoclip = {}

---Checks if the ped is genuinely falling based on vertical speed and ground gap.
---@param ped number
---@param coords vector3
---@return boolean
local function is_real_fall(ped, coords)
    local vel = GetEntityVelocity(ped)
    ---@type boolean Check vertical velocity threshold
    if vel.z > -2.5 then
        return false
    end
    ---@type boolean found Ground detection result
    ---@type number groundZ Z-coordinate of the ground
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, 0)
    if not found then
        return false
    end
    ---@type number Height above ground
    if (coords.z - groundZ) < 3.0 then
        return false
    end
    return true
end

---Checks if the ped is genuinely swimming based on submerged level.
---@param ped number
---@return boolean
local function is_real_swim(ped)
    if not IsEntityInWater(ped) then
        return false
    end
    return GetEntitySubmergedLevel(ped) > 0.25
end

---Checks if the ped is genuinely parachuting based on parachute state and vertical velocity.
---@param ped number
---@param vel vector3
---@return boolean
local function is_real_parachute(ped, vel)
    if GetPedParachuteState(ped) == 0 then
        return false
    end
    return vel.z < -3.0 or vel.z > 3.0
end

---Initializes the Anti-Noclip protection if enabled in configuration.
function AntiNoclip.initialize()
    if not ConfigLoader.get_protection_setting("Anti Noclip", "enabled") then
        return
    end

    ---@section Tunables
    ---@field CHECK_INTERVAL number ms between samples
    ---@field DIST_THRESHOLD number maximum distance (meters) on foot in one interval
    ---@field STRIKES_REQUIRED integer consecutive violations required to punish
    ---@field VEHICLE_EXIT_GRACE_MS integer grace period after exiting a vehicle (ms)
    local CHECK_INTERVAL        = 1500
    local DIST_THRESHOLD        = 16.0
    local STRIKES_REQUIRED      = 3
    local VEHICLE_EXIT_GRACE_MS = 2000

    ---@type vector3? Last recorded player coordinates
    local lastPos = nil
    ---@type integer Last recorded game timer
    local lastTime = 0
    ---@type integer Strike counter for consecutive violations
    local strikes = 0
    ---@type boolean Tracks whether the player was previously in a vehicle
    local lastVehicleState = false
    ---@type integer Timestamp of last vehicle exit
    local lastVehicleExit = 0

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(CHECK_INTERVAL)

            ---@section Privileged bypass
            if Cache.Get("hasPermission", "noclip")
               or Cache.Get("hasPermission", "all")
               or Cache.Get("isAdmin") then
                lastPos = nil
                strikes = 0
                goto continue
            end

            ---@section Gather state
            ---@type number Ped identifier
            local ped = Cache.Get("ped")
            ---@type vector3 Current player coordinates
            local coords = Cache.Get("coords")
            ---@type integer Current game timer
            local now = GetGameTimer()
            ---@type boolean Player in vehicle state
            local inVeh = Cache.Get("isInVehicle")

            ---@section Vehicle exit grace
            if lastVehicleState and not inVeh then
                lastVehicleExit = now
            end
            lastVehicleState = inVeh

            ---@section Skip checks if in vehicle or within grace window
            if inVeh or (now - lastVehicleExit) < VEHICLE_EXIT_GRACE_MS then
                lastPos = nil
                strikes = 0
                goto continue
            end

            ---@section Core distance test
            if lastPos then
                ---@type number Distance moved since last sample
                local dist = #(coords - lastPos)

                if dist > DIST_THRESHOLD then
                    ---@type vector3 Current velocity
                    local vel = GetEntityVelocity(ped)
                    ---@type boolean Determines if movement is legitimate
                    local legit = is_real_fall(ped, coords)
                               or is_real_swim(ped)
                               or is_real_parachute(ped, vel)

                    if legit then
                        strikes = 0
                    else
                        strikes = strikes + 1
                    end

                    if strikes >= STRIKES_REQUIRED then
                        TriggerServerEvent(
                            "SecureServe:Server:Methods:PunishPlayer",
                            nil,
                            "Anti Noclip",
                            webhook, -- external variable
                            time     -- external variable
                        )
                        strikes = 0
                    end
                else
                    strikes = 0
                end
            end

            ---@section Book-keeping
            lastPos = coords
            lastTime = now

            ::continue::
        end
    end)
end

ProtectionManager.register_protection("noclip", AntiNoclip.initialize)
return AntiNoclip
