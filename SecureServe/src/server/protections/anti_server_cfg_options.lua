local logger = require("server/core/logger")
local ban_manager = require("server/core/ban_manager")

local AntiServerCfgOptions = {}

function AntiServerCfgOptions.initialize()
    
    if not SecureServe.ServerSecurity or not SecureServe.ServerSecurity.Enabled then
        logger.info("[SecureServe] Server security configuration not enabled")
        return
    end
    
    if SecureServe.ServerSecurity.Connection then
        
        SetConvar("sv_kick_players_cnl_timeout_sec", tostring(SecureServe.ServerSecurity.Connection.KickTimeout or 600))
        SetConvar("sv_kick_players_cnl_update_rate_sec", tostring(SecureServe.ServerSecurity.Connection.UpdateRate or 60))
        SetConvar("sv_kick_players_cnl_consecutive_failures", tostring(SecureServe.ServerSecurity.Connection.ConsecutiveFailures or 2))
        
        SetConvar("sv_authMaxVariance", tostring(SecureServe.ServerSecurity.Connection.AuthMaxVariance or 1))
        SetConvar("sv_authMinTrust", tostring(SecureServe.ServerSecurity.Connection.AuthMinTrust or 5))
        
        SetConvar("sv_pure_verify_client_settings", SecureServe.ServerSecurity.Connection.VerifyClientSettings and "1" or "0")
    end
    
    if SecureServe.ServerSecurity.NetworkEvents then
        
        SetConvar("sv_filterRequestControl", tostring(SecureServe.ServerSecurity.NetworkEvents.FilterRequestControl or 0))
        
        SetConvar("sv_enableNetworkedSounds", SecureServe.ServerSecurity.NetworkEvents.DisableNetworkedSounds and "false" or "true")
        
        SetConvar("sv_enableNetworkedPhoneExplosions", SecureServe.ServerSecurity.NetworkEvents.DisablePhoneExplosions and "false" or "true")
        
        SetConvar("sv_enableNetworkedScriptEntityStates", SecureServe.ServerSecurity.NetworkEvents.DisableScriptEntityStates and "false" or "true")
    end
    
    if SecureServe.ServerSecurity.ClientProtection then
        
        SetConvar("sv_pureLevel", tostring(SecureServe.ServerSecurity.ClientProtection.PureLevel or 2))
        
        SetConvar("sv_disableClientReplays", SecureServe.ServerSecurity.ClientProtection.DisableClientReplays and "1" or "0")
        
        SetConvar("sv_scriptHookAllowed", SecureServe.ServerSecurity.ClientProtection.ScriptHookAllowed and "1" or "0")
    end
    
    if SecureServe.ServerSecurity.Misc then
        
        SetConvar("sv_enableChatTextSanitization", SecureServe.ServerSecurity.Misc.EnableChatSanitization and "1" or "0")
        
        if SecureServe.ServerSecurity.Misc.ResourceKvRateLimit then
            SetConvar("sv_defaultResourceKvRateLimit", tostring(SecureServe.ServerSecurity.Misc.ResourceKvRateLimit))
        end
        
        if SecureServe.ServerSecurity.Misc.EntityKvRateLimit then
            SetConvar("sv_defaultEntityKvRateLimit", tostring(SecureServe.ServerSecurity.Misc.EntityKvRateLimit))
        end
    end
    
    logger.info("[SecureServe] Server security configuration applied successfully")
end

return AntiServerCfgOptions
