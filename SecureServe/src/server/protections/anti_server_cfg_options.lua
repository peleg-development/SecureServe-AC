---@class AntiServerCfgOptionsModule
local AntiServerCfgOptions = {}

---@return void
function AntiServerCfgOptions.initialize()
    -- Timeout at which the server will kick players (10 minutes)
    SetConvarReplicated("sv_kick_players_cnl_timeout_sec", "600")
    
    -- Frequency at which CnL is queried with player list
    SetConvarReplicated("sv_kick_players_cnl_update_rate_sec", "60")
    
    -- Verify client settings through adhesive<->svadhesive connection
    SetConvarReplicated("sv_pure_verify_client_settings", "1")
    
    -- Number of consecutive failures before kicking (default 2)
    SetConvarReplicated("sv_kick_players_cnl_consecutive_failures", "2")
    
    -- Max variance for user identity per provider (lowering increases security)
    SetConvarReplicated("sv_authMaxVariance", "1")
    
    -- Min trust level for identity verification (increasing improves security)
    SetConvarReplicated("sv_authMinTrust", "5")
    
    -- Block REQUEST_CONTROL_EVENT routing based on policy
    SetConvarReplicated("sv_filterRequestControl", "1")
    
    -- Disable client replays to reduce cheating options (disables Rockstar Editor)
    SetConvarReplicated("sv_disableClientReplays", "1")
    
    -- Sound and network event security settings
    SetConvarReplicated("sv_enableNetworkedSounds", "false")  -- Prevent routing of NETWORK_PLAY_SOUND_EVENT
    SetConvarReplicated("sv_enableNetworkedPhoneExplosions", "false")  -- Prevent phone explosion events
    SetConvarReplicated("sv_enableNetworkedScriptEntityStates", "false")  -- Prevent SCRIPT_ENTITY_STATE_CHANGE_EVENT
    
    -- Additional security measures
    SetConvarReplicated("sv_scriptHookAllowed", "0")  -- Disallow Script Hook
    SetConvarReplicated("sv_enableChatTextSanitization", "1")  -- Enable chat sanitization
    
    -- Set resource kv rate limits to prevent resource flooding
    SetConvarReplicated("sv_defaultResourceKvRateLimit", "20")
    SetConvarReplicated("sv_defaultEntityKvRateLimit", "20")
end

return AntiServerCfgOptions
