local ProtectionManager = require("client/protections/protection_manager")
local ProtectionHelper  = require("client/core/protection_helper")
local Cache             = require("client/core/cache")

---@class AntiESPModule
local AntiESP = {}

local detections      = 0
local STRIKE_THRESHOLD = 25
local PROXIMITY       = 50.0

local function is_near_other_player(pos)
    if not pos then return false end
    local players  = GetActivePlayers()
    local local_id = PlayerId()
    for _, pid in ipairs(players) do
        if pid ~= local_id then
            local ped = GetPlayerPed(pid)
            if ped ~= 0 and DoesEntityExist(ped) then
                local ppos = GetEntityCoords(ped)
                local dist = #(vector3(pos.x, pos.y, pos.z) - ppos)
                if dist < PROXIMITY then
                    return true
                end
            end
        end
    end
    return false
end

function AntiESP.initialize()
    if not ConfigLoader.get_protection_setting("Anti ESP", "enabled") then return end

    -- Permite al operador desactivar el wrap de natives Draw* manteniendo el
    -- resto de la deteccion. Util si tienes otros recursos que tambien wrappean
    -- esos natives y prefieres evitar conflictos.
    local wrap_natives = true
    if SecureServe and SecureServe.Detections
        and SecureServe.Detections.ClientProtections
        and SecureServe.Detections.ClientProtections["Anti ESP"]
        and SecureServe.Detections.ClientProtections["Anti ESP"].wrap_natives == false
    then
        wrap_natives = false
    end
    if not wrap_natives then return end

    -- Guard contra doble aplicacion. Si SecureServe se reinicia en caliente,
    -- este archivo se vuelve a ejecutar; sin guard volveriamos a wrapear las
    -- natives ya wrapeadas, duplicando los checks y rompiendo composicion con
    -- otros resources.
    if _G.__SecureServe_ESPWrapsApplied then
        return
    end
    _G.__SecureServe_ESPWrapsApplied = true

    -- Capturamos la version actual de las natives, NO la nativa "original".
    -- De este modo si otro resource (panel admin, ESP de DBG, etc) ya las
    -- habia wrappeado, conservamos su wrap. Y los proximos wraps despues del
    -- nuestro tambien se respetan.
    local _DrawLine     = _G.DrawLine
    local _DrawMarker   = _G.DrawMarker
    local _DrawSprite3D = _G.DrawSprite3D
    local _DrawPoly     = _G.DrawPoly

    local frame_draws = 0
    local last_reset  = GetGameTimer()

    local function check_draw(pos)
        if Cache.Get("hasPermission", "esp")
            or Cache.Get("hasPermission", "all")
            or Cache.Get("isAdmin")
        then
            return
        end

        local now = GetGameTimer()
        if now - last_reset > 1000 then
            frame_draws = 0
            last_reset  = now
        end

        if is_near_other_player(pos) then
            frame_draws = frame_draws + 1
            if frame_draws > 200 then
                detections  = detections + 1
                frame_draws = 0
                if detections >= STRIKE_THRESHOLD then
                    detections = 0
                    ProtectionHelper.punish('Anti ESP', "Native ESP draw detected")
                end
            end
        end
    end

    if _DrawLine then
        _G.DrawLine = function(x1, y1, z1, x2, y2, z2, r, g, b, a)
            check_draw({ x = x1, y = y1, z = z1 })
            return _DrawLine(x1, y1, z1, x2, y2, z2, r, g, b, a)
        end
    end

    if _DrawMarker then
        _G.DrawMarker = function(t, x, y, z, ...)
            check_draw({ x = x, y = y, z = z })
            return _DrawMarker(t, x, y, z, ...)
        end
    end

    if _DrawSprite3D then
        _G.DrawSprite3D = function(tex, name, x, y, z, ...)
            check_draw({ x = x, y = y, z = z })
            return _DrawSprite3D(tex, name, x, y, z, ...)
        end
    end

    if _DrawPoly then
        _G.DrawPoly = function(x1, y1, z1, ...)
            check_draw({ x = x1, y = y1, z = z1 })
            return _DrawPoly(x1, y1, z1, ...)
        end
    end
end

ProtectionManager.register_protection("esp", AntiESP.initialize)

return AntiESP
