local Perms = {}

function Perms.IsMenuAdmin(server_id)
    if not ConfigLoader.is_loaded() then
        ConfigLoader.initialize()
        Citizen.Wait(50)
    end

    local target_id = server_id or GetPlayerServerId(PlayerId())
    if _G.SecureServeAdminList and _G.SecureServeAdminList[tostring(target_id)] then
        return true
    end
    return ConfigLoader.is_menu_admin(target_id) == true
end

_G.IsMenuAdmin = Perms.IsMenuAdmin

return Perms
