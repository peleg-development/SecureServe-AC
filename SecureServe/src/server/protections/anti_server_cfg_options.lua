local logger = require("server/core/logger")
local ban_manager = require("server/core/ban_manager")

---@class AntiServerCfgOptionsModule
local AntiServerCfgOptions = {}

---@return void This function will apply the server security settings to the server
function AntiServerCfgOptions.initialize()
    -- Check if server security settings are enabled
    if not SecureServe.ServerSecurity or not SecureServe.ServerSecurity.Enabled then
        logger.info("[SecureServe] Server security configuration not enabled")
        return
    end
    
    -- CONNECTION & AUTHENTICATION SETTINGS
    if SecureServe.ServerSecurity.Connection then
        -- Timeout settings
        SetConvar("sv_kick_players_cnl_timeout_sec", tostring(SecureServe.ServerSecurity.Connection.KickTimeout or 600))
        SetConvar("sv_kick_players_cnl_update_rate_sec", tostring(SecureServe.ServerSecurity.Connection.UpdateRate or 60))
        SetConvar("sv_kick_players_cnl_consecutive_failures", tostring(SecureServe.ServerSecurity.Connection.ConsecutiveFailures or 2))
        
        -- Authentication settings
        SetConvar("sv_authMaxVariance", tostring(SecureServe.ServerSecurity.Connection.AuthMaxVariance or 1))
        SetConvar("sv_authMinTrust", tostring(SecureServe.ServerSecurity.Connection.AuthMinTrust or 5))
        
        -- Client verification
        SetConvar("sv_pure_verify_client_settings", SecureServe.ServerSecurity.Connection.VerifyClientSettings and "1" or "0")
    end
    
    -- NETWORK EVENT SECURITY
    if SecureServe.ServerSecurity.NetworkEvents then
        -- Block REQUEST_CONTROL_EVENT routing (supports values -1 to 4, 2 recommended for your use case)
        SetConvar("sv_filterRequestControl", tostring(SecureServe.ServerSecurity.NetworkEvents.FilterRequestControl or 0))
        
        -- Block NETWORK_PLAY_SOUND_EVENT routing
        SetConvar("sv_enableNetworkedSounds", SecureServe.ServerSecurity.NetworkEvents.DisableNetworkedSounds and "false" or "true")
        
        -- Block REQUEST_PHONE_EXPLOSION_EVENT
        SetConvar("sv_enableNetworkedPhoneExplosions", SecureServe.ServerSecurity.NetworkEvents.DisablePhoneExplosions and "false" or "true")
        
        -- Block SCRIPT_ENTITY_STATE_CHANGE_EVENT
        SetConvar("sv_enableNetworkedScriptEntityStates", SecureServe.ServerSecurity.NetworkEvents.DisableScriptEntityStates and "false" or "true")
    end
    
    -- CLIENT MODIFICATION PROTECTION
    if SecureServe.ServerSecurity.ClientProtection then
        -- Pure level setting
        SetConvar("sv_pureLevel", tostring(SecureServe.ServerSecurity.ClientProtection.PureLevel or 2))
        
        -- Disable client replays
        SetConvar("sv_disableClientReplays", SecureServe.ServerSecurity.ClientProtection.DisableClientReplays and "1" or "0")
        
        -- Script hook settings
        SetConvar("sv_scriptHookAllowed", SecureServe.ServerSecurity.ClientProtection.ScriptHookAllowed and "1" or "0")
    end
    
    -- MISC SECURITY SETTINGS
    if SecureServe.ServerSecurity.Misc then
        -- Enable chat sanitization
        SetConvar("sv_enableChatTextSanitization", SecureServe.ServerSecurity.Misc.EnableChatSanitization and "1" or "0")
        
        -- Rate limits
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