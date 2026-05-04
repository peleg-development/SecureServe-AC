local ProtectionHelper = {}

local cache = {}

function ProtectionHelper.get_punish_args(name)
    local entry = cache[name]
    if entry and entry.ready then
        return entry.webhook, entry.time
    end

    local webhook = ConfigLoader.get_protection_setting(name, "webhook") or ""
    local time = ConfigLoader.get_protection_setting(name, "time")
    if type(time) ~= "number" then
        time = 2147483647
    end

    if ConfigLoader.is_loaded() then
        cache[name] = { webhook = webhook, time = time, ready = true }
    end

    return webhook, time
end

function ProtectionHelper.punish(name, reason, screenshot)
    local webhook, time = ProtectionHelper.get_punish_args(name)
    TriggerServerEvent("SecureServe:Server:Methods:PunishPlayer",
        screenshot, reason or name, webhook, time)
end

_G.ProtectionHelper = ProtectionHelper

return ProtectionHelper
