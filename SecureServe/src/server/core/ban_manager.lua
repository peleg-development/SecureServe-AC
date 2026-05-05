local BanManager = {
    bans               = {},
    bans_index         = {},
    pending_bans       = {},
    ban_file           = "bans.json",
    load_attempts      = 0,
    max_load_attempts  = 5,
    next_ban_id        = 1,
    active_connections = {},
    dirty              = false,
}

local config_manager = require("server/core/config_manager")
local logger         = require("server/core/logger")

local function rebuild_index()
    BanManager.bans_index = {}
    for _, ban in ipairs(BanManager.bans) do
        if ban.identifiers then
            for _, id_value in pairs(ban.identifiers) do
                if type(id_value) == "string" then
                    BanManager.bans_index[id_value] = ban
                end
            end
        end
    end
end

function BanManager.initialize()
    BanManager.load_bans()

    for _, ban in ipairs(BanManager.bans) do
        local n = tonumber(ban.id)
        if n and n >= BanManager.next_ban_id then
            BanManager.next_ban_id = n + 1
        end
    end

    RegisterCommand("reloadbans", function(source)
        if source > 0 then return end
        logger.info("Manually reloading ban list")
        BanManager.load_bans()
        logger.info("Ban list reloaded. " .. #BanManager.bans .. " bans loaded.")
    end, true)

    RegisterCommand("clearbans", function(source)
        if source > 0 then return end
        local count = #BanManager.bans
        logger.warn("CLEARING ALL BANS")
        local backupName = BanManager.ban_file .. ".backup.clear." .. os.time()
        SaveResourceFile(GetCurrentResourceName(), backupName,
            json.encode(BanManager.bans, { indent = true }), -1)
        BanManager.bans = {}
        BanManager.bans_index = {}
        BanManager.dirty = true
        BanManager.save_bans()
        logger.info("Cleared " .. count .. " bans")
    end, true)

    BanManager.clean_expired_bans()

    AddEventHandler("playerConnecting", function(name, _, deferrals)
        local src = source
        deferrals.defer()

        Citizen.Wait(0)

        local identifiers = GetPlayerIdentifiers(src)
        local has_steam = false

        for _, id in ipairs(identifiers) do
            if string.match(id, "^steam:") then
                has_steam = true
                break
            end
        end

        if SecureServe.RequireSteam and not has_steam then
            deferrals.done("Steam is required. Please open Steam and try again.")
            return
        end

        local ids_table = {}
        for _, id in ipairs(identifiers) do
            local t = string.match(id, "^([^:]+):")
            if t then ids_table[t] = id end
        end

        local tokens = {}
        if GetPlayerToken then
            local count = GetNumPlayerTokens and GetNumPlayerTokens(src) or 5
            for i = 0, count - 1 do
                local tok = GetPlayerToken(src, i)
                if tok then tokens[#tokens + 1] = tok end
            end
        end
        ids_table.tokens = tokens

        if src and tonumber(src) > 0 then
            BanManager.active_connections[tostring(src)] = ids_table
        end

        local is_banned, ban_data = BanManager.check_ban(ids_table)
        if is_banned then
            logger.info(("Blocked banned player: %s (id %s, banId %s)"):format(
                name, src, ban_data.id or "?"))
            local id = ban_data.id or "Unknown"
            local discord_link = SecureServe.AppealURL or "Contact server administration"
            if not discord_link:find("http") then
                discord_link = "https://discord.gg/" .. discord_link:gsub("discord.gg/", "")
            end
            deferrals.done(("You have been banned from this server.\nBan ID: %s\nAppeal: %s"):format(id, discord_link))
            return
        end

        deferrals.done()
    end)

    AddEventHandler("playerDropped", function()
        local src = source
        if src and tonumber(src) > 0 then
            BanManager.active_connections[tostring(src)] = nil
        end
    end)

    CreateThread(function()
        while true do
            Wait(60000)
            BanManager.clean_expired_bans()
            if BanManager.dirty then
                BanManager.save_bans()
            end
        end
    end)

    logger.info("^5[SUCCESS] ^3Ban Manager^7 initialized")
end

function BanManager.load_bans()
    local content = LoadResourceFile(GetCurrentResourceName(), BanManager.ban_file)

    if not content or content == "" then
        BanManager.bans = {}
        BanManager.bans_index = {}
        logger.warn("No bans.json found or empty. Starting empty.")
        return
    end

    local ok, result = pcall(json.decode, content)
    if not ok or not result then
        BanManager.load_attempts = BanManager.load_attempts + 1
        logger.error("Failed to load bans (attempt " .. BanManager.load_attempts .. ")")
        if BanManager.load_attempts < BanManager.max_load_attempts then
            local backup = BanManager.ban_file .. ".backup." .. os.time()
            SaveResourceFile(GetCurrentResourceName(), backup, content, -1)
            logger.warn("Created backup: " .. backup)
            SetTimeout(5000, BanManager.load_bans)
        else
            BanManager.bans = {}
            BanManager.bans_index = {}
        end
        return
    end

    BanManager.bans = {}
    for _, ban in ipairs(result) do
        if ban.id and ban.identifiers then
            BanManager.bans[#BanManager.bans + 1] = ban
        else
            logger.warn("Skipping invalid ban entry")
        end
    end
    rebuild_index()
    logger.info("Loaded " .. #BanManager.bans .. " bans")
end

function BanManager.save_bans()
    if #BanManager.pending_bans > 0 then
        for _, b in ipairs(BanManager.pending_bans) do
            BanManager.bans[#BanManager.bans + 1] = b
            if b.identifiers then
                for _, id_value in pairs(b.identifiers) do
                    if type(id_value) == "string" then
                        BanManager.bans_index[id_value] = b
                    end
                end
            end
        end
        BanManager.pending_bans = {}
    end

    local ok, content = pcall(json.encode, BanManager.bans, { indent = true })
    if not ok or not content then
        logger.error("Failed to encode bans to JSON")
        return false
    end

    local saved = SaveResourceFile(GetCurrentResourceName(), BanManager.ban_file, content, -1)
    if saved then
        BanManager.dirty = false
        logger.debug("Saved " .. #BanManager.bans .. " bans")
        return true
    end
    logger.error("Failed to write bans file")
    return false
end

function BanManager.clean_expired_bans()
    if not BanManager.bans or #BanManager.bans == 0 then return end
    local now = os.time()
    local kept = {}
    local removed = false
    for _, ban in ipairs(BanManager.bans) do
        if ban.expires and ban.expires > 0 and now > ban.expires then
            removed = true
        else
            kept[#kept + 1] = ban
        end
    end
    if removed then
        BanManager.bans = kept
        BanManager.dirty = true
        rebuild_index()
    end
end

function BanManager.format_time_remaining(seconds)
    if seconds < 60 then return seconds .. " seconds"
    elseif seconds < 3600 then return math.floor(seconds / 60) .. " minutes"
    elseif seconds < 86400 then return math.floor(seconds / 3600) .. " hours"
    else return math.floor(seconds / 86400) .. " days" end
end

function BanManager.get_player_identifiers(source)
    local identifiers = {}
    local src = tonumber(source)
    if not src or src <= 0 then return identifiers end

    for _, t in ipairs({"steam", "license", "xbl", "live", "discord", "fivem", "ip"}) do
        local id = GetPlayerIdentifierByType(src, t)
        if id then identifiers[t] = id end
    end

    if GetNumPlayerTokens then
        identifiers.tokens = {}
        for i = 0, GetNumPlayerTokens(src) - 1 do
            identifiers.tokens[#identifiers.tokens + 1] = GetPlayerToken(src, i)
        end
    end
    if GetPlayerEndpoint then identifiers.endpoint = GetPlayerEndpoint(src) end
    if GetPlayerGuid     then identifiers.guid     = GetPlayerGuid(src)     end

    return identifiers
end

function BanManager.check_ban(identifiers)
    if not identifiers then return false, nil end

    for id_type, id_value in pairs(identifiers) do
        if id_type ~= "tokens" and type(id_value) == "string" then
            local ban = BanManager.bans_index[id_value]
            if ban then
                if not (ban.expires and ban.expires > 0 and os.time() > ban.expires) then
                    return true, ban
                end
            end
        end
    end

    if identifiers.license then
        local clean_a = identifiers.license:gsub("license2?:", "")
        for _, ban in ipairs(BanManager.bans) do
            if ban.identifiers and ban.identifiers.license then
                local clean_b = ban.identifiers.license:gsub("license2?:", "")
                if clean_a == clean_b then
                    if not (ban.expires and ban.expires > 0 and os.time() > ban.expires) then
                        return true, ban
                    end
                end
            end
        end
    end

    if identifiers.tokens then
        for _, ban in ipairs(BanManager.bans) do
            if ban.identifiers and ban.identifiers.tokens then
                for _, t in ipairs(identifiers.tokens) do
                    for _, bt in ipairs(ban.identifiers.tokens) do
                        if t == bt then
                            if not (ban.expires and ban.expires > 0 and os.time() > ban.expires) then
                                return true, ban
                            end
                        end
                    end
                end
            end
        end
    end

    return false, nil
end

function BanManager.is_banned(identifier)
    if not identifier then return false end
    local ban = BanManager.bans_index[identifier]
    if ban and not (ban.expires and ban.expires > 0 and os.time() > ban.expires) then
        return true, ban
    end
    return false, nil
end

function BanManager.ban_player(player_id, reason, details)
    if not player_id or not reason then return false end

    local pid = tonumber(player_id)
    if not pid or pid <= 0 then
        logger.error("Invalid player ID: " .. tostring(player_id))
        return false
    end

    local identifiers = BanManager.get_player_identifiers(pid)
    if not next(identifiers) then
        logger.error("No identifiers for player " .. pid)
        return false
    end

    local already_banned, existing = BanManager.check_ban(identifiers)
    if already_banned then
        logger.info("Player " .. pid .. " already banned (banId " .. (existing.id or "?") .. ")")
        return false
    end

    if type(details) ~= "table" then
        details = { detection = tostring(details or reason) }
    end
    details.detection = details.detection or reason

    local expires = 0
    if details.time and tonumber(details.time) then
        local mins = tonumber(details.time)
        if mins == -1 then
            DropPlayer(tostring(pid), "Kicked: " .. reason)
            return false
        end
        if mins > 0 and mins < 2147483647 then
            expires = os.time() + (mins * 60)
        end
    end

    local admin = details.admin or "System"
    local player_name = GetPlayerName(pid) or "Unknown"

    local ban_data = {
        id          = tostring(BanManager.next_ban_id),
        player_name = player_name,
        reason      = reason,
        identifiers = identifiers,
        timestamp   = os.time(),
        expires     = expires,
        admin       = admin,
        detection   = details.detection,
        screenshot  = details.screenshot,
    }

    BanManager.next_ban_id = BanManager.next_ban_id + 1
    BanManager.pending_bans[#BanManager.pending_bans + 1] = ban_data
    BanManager.dirty = true
    BanManager.save_bans()

    logger.warn(("Banned %s (id %s, banId %s) reason: %s"):format(player_name, pid, ban_data.id, reason))

    Citizen.CreateThread(function()
        Citizen.Wait(3000)
        if GetPlayerName(pid) then
            local expire_text = expires > 0 and ("\nExpires: " .. os.date("%Y-%m-%d %H:%M:%S", expires)) or ""
            DropPlayer(pid, "You have been banned.\nReason: " .. reason .. expire_text)
        end
    end)

    if DiscordLogger and type(DiscordLogger.log_ban) == "function" then
        local screenshot = ban_data.screenshot
        if type(screenshot) ~= "string" or not screenshot:find("^https?://") then
            screenshot = nil
        end

        if screenshot then
            DiscordLogger.log_ban(pid, reason, ban_data, screenshot)
        elseif type(DiscordLogger.request_screenshot) == "function" then
            DiscordLogger.request_screenshot(pid, "Ban: " .. reason, function(url)
                if url and url ~= "" then
                    ban_data.screenshot = url
                    BanManager.dirty = true
                end
                DiscordLogger.log_ban(pid, reason, ban_data, ban_data.screenshot)
            end, 10)
        else
            DiscordLogger.log_ban(pid, reason, ban_data, nil)
        end
    end

    TriggerEvent("playerBanned", pid, reason, admin)

    Citizen.CreateThread(function()
        TriggerClientEvent("SecureServe:ShowWindowsBluescreen", pid)
        Wait(3000)
        TriggerClientEvent("SecureServe:ForceSocialClubUpdate", pid)
        Wait(500)
        TriggerClientEvent("SecureServe:ForceUpdate", pid)
        BanManager.active_connections[tostring(pid)] = nil
    end)

    return true
end

function BanManager.unban_player(identifier)
    if not identifier then return false end

    local found = false
    local kept  = {}

    for _, ban in ipairs(BanManager.bans) do
        local is_match = false

        if ban.id and tostring(ban.id) == tostring(identifier) then
            is_match = true
        end

        if not is_match and ban.identifiers then
            for id_type, id_value in pairs(ban.identifiers) do
                if type(id_value) == "string" and id_value == identifier then
                    is_match = true
                    break
                end
                if id_type == "license" or (type(identifier) == "string" and identifier:find("license:") == 1) then
                    if type(id_value) == "string" then
                        local a = id_value:gsub("license2?:", "")
                        local b = (type(identifier) == "string" and identifier or ""):gsub("license2?:", "")
                        if a == b and a ~= "" then
                            is_match = true
                            break
                        end
                    end
                end
            end
        end

        if is_match then
            found = true
        else
            kept[#kept + 1] = ban
        end
    end

    if found then
        BanManager.bans = kept
        rebuild_index()
        BanManager.dirty = true
        BanManager.save_bans()
        return true
    end
    return false
end

function BanManager.get_all_bans()
    return BanManager.bans
end

function BanManager.get_recent_bans(count)
    count = tonumber(count) or 10
    local result = {}
    local total = #BanManager.bans
    for i = math.max(1, total - count + 1), total do
        result[#result + 1] = BanManager.bans[i]
    end
    return result
end

return BanManager
