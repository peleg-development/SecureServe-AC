local ProtectionHelper = {}

function ProtectionHelper.punish(name, reason, screenshot)
    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer",
        screenshot, reason or name)
end

_G.ProtectionHelper = ProtectionHelper

return ProtectionHelper
