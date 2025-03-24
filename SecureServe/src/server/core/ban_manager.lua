---@class BanManagerModule

-- This is really bad, but it works for now. it will be improved and fixed in the future.

local BanManager = {
    bans = {},
    pending_bans = {},
    ban_file = "bans.json",
    load_attempts = 0,
    max_load_attempts = 5,
    next_ban_id = 1, 
    active_connections = {},
    last_file_modified = 0
}

local config_manager = require("server/core/config_manager")
local logger = require("server/core/logger")
local discord_logger = require("server/core/discord_logger")

---@description Initialize the ban manager
function BanManager.initialize()
    BanManager.load_bans()
    
    for _, ban in ipairs(BanManager.bans) do
        local numeric_id = tonumber(ban.id)
        if numeric_id and numeric_id >= BanManager.next_ban_id then
            BanManager.next_ban_id = numeric_id + 1
        end
    end
    
    RegisterCommand("reloadbans", function(source, args, rawCommand)
        if source > 0 then 
            return
        end
        
        logger.info("Manually reloading ban list...")
        BanManager.load_bans()
        logger.info("Ban list reloaded. " .. #BanManager.bans .. " bans loaded.")
    end, true)
    
    RegisterCommand("clearbans", function(source, args, rawCommand)
        if source > 0 then 
            return
        end
        
        local count = #BanManager.bans
        logger.warn("CLEARING ALL BANS FROM THE SERVER!")
        
        local backupName = BanManager.ban_file .. ".backup.clear." .. os.time()
        SaveResourceFile(GetCurrentResourceName(), backupName, json.encode(BanManager.bans, { indent = true }), -1)
        logger.info("Created backup of bans before clearing: " .. backupName)
        
        BanManager.bans = {}
        BanManager.save_bans()
        
        logger.info("Cleared " .. count .. " bans from the server")
    end, true)
    
    BanManager.clean_expired_bans()
    
    AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
        local src = source
        deferrals.defer()
        
        BanManager.load_bans()
        
        logger.debug("Player connecting: " .. name .. " (ID: " .. src .. ")")
    
        local tokens = {}
        for i = 1, 5 do
            if GetPlayerToken then
                table.insert(tokens, GetPlayerToken(src, i))
            end
        end
        
        Citizen.Wait(0)
        
        local identifiers = GetPlayerIdentifiers(src)
        local hasSteam = false
        
        for _, identifier in ipairs(identifiers) do
            if string.match(identifier, "steam:") then
                hasSteam = true
                break
            end
        end
        
        if SecureServe.RequireSteam and not hasSteam then
            local steamCard = [[
                {
                    "type": "AdaptiveCard",
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "version": "1.3",
                    "backgroundImage": {
                        "url": "https://www.transparenttextures.com/patterns/black-linen.png"
                    },
                    "body": [
                        {
                            "type": "Container",
                            "style": "emphasis",
                            "bleed": true,
                            "items": [
                                {
                                    "type": "Image",
                                    "url": "https://img.icons8.com/color/452/error.png",
                                    "horizontalAlignment": "Center",
                                    "size": "Large",
                                    "spacing": "Large"
                                },
                                {
                                    "type": "TextBlock",
                                    "text": "Steam Account Required",
                                    "wrap": true,
                                    "horizontalAlignment": "Center",
                                    "size": "ExtraLarge",
                                    "weight": "Bolder",
                                    "color": "Attention",
                                    "spacing": "Medium"
                                },
                                {
                                    "type": "TextBlock",
                                    "text": "You need to have Steam open and linked to your FiveM account to join this server.",
                                    "wrap": true,
                                    "horizontalAlignment": "Center",
                                    "size": "Large",
                                    "weight": "Bolder",
                                    "color": "Attention",
                                    "spacing": "Small"
                                },
                                {
                                    "type": "TextBlock",
                                    "text": "Make sure Steam is running before launching FiveM, then try again.",
                                    "wrap": true,
                                    "horizontalAlignment": "Center",
                                    "size": "Medium",
                                    "spacing": "Medium"
                                }
                            ]
                        }
                    ]
                }
            ]]
            deferrals.presentCard(steamCard)
            deferrals.done("You need to have Steam open and linked to your FiveM account to join this server.")
            return
        end
        
        local identifiersTable = {}
        for _, identifier in ipairs(identifiers) do
            local idType = string.match(identifier, "^([^:]+):")
            if idType then
                identifiersTable[idType] = identifier
            end
        end
        
        identifiersTable.tokens = tokens
        
        if src and tonumber(src) > 0 then
            BanManager.active_connections[tostring(src)] = identifiersTable
        end
        
        local is_banned, ban_data = BanManager.check_ban(identifiersTable)
        
        if is_banned then
            logger.info("Blocked banned player connection: " .. name .. " (ID: " .. src .. ")")
            logger.info("Ban ID: " .. (ban_data.id or "Unknown") .. ", License: " .. (identifiersTable.license or "unknown"))
            logger.info("Ban reason: " .. (ban_data.reason or "Unknown"))
    
            local id = ban_data.id or "Unknown"
            local discord_link = SecureServe.AppealURL or "Contact server administration"
            if not discord_link:find("http") then
                discord_link = "https://discord.gg/" .. discord_link:gsub("discord.gg/", "")
            end
            
            deferrals.done("You have been banned from this server.\nBan ID: " .. id .. "\nAppeal: " .. discord_link)
            return
        else
            logger.debug("Player " .. name .. " (ID: " .. src .. ") is not banned, allowing connection")
        end
        deferrals.done()
    end)
    
    AddEventHandler("playerDropped", function(reason)
        local source = source
        
        if not source or tonumber(source) <= 0 then
            return
        end
        
        BanManager.active_connections[tostring(source)] = nil
    end)
    
    CreateThread(function()
        while true do
            Wait(60000)
            BanManager.check_and_reload_bans()
            BanManager.clean_expired_bans()
            BanManager.save_bans()
        end
    end)
    
    logger.info("^5[SUCCESS] ^3Ban Manager^7 initialized")
end

---@description Load bans from file
function BanManager.load_bans()
    local file_content = LoadResourceFile(GetCurrentResourceName(), BanManager.ban_file)
    
    if not file_content or file_content == "" then
        BanManager.bans = {}
        logger.warn("No bans.json found or file is empty. Starting with empty ban list.")
        return
    end
    
    local success, result = pcall(function()
        return json.decode(file_content)
    end)
    
    if success and result then
        BanManager.bans = {}
        
        for _, ban in ipairs(result) do
            if ban.id and ban.identifiers then
                table.insert(BanManager.bans, ban)
            else
                logger.warn("Skipping invalid ban entry: " .. json.encode(ban))
            end
        end
        
        logger.info("Loaded " .. #BanManager.bans .. " bans from file")
        BanManager.last_file_modified = os.time()
    else
        BanManager.load_attempts = BanManager.load_attempts + 1
        logger.error("Failed to load bans from file. Attempt " .. BanManager.load_attempts)
        
        if BanManager.load_attempts < BanManager.max_load_attempts then
            local backup_name = BanManager.ban_file .. ".backup." .. os.time()
            SaveResourceFile(GetCurrentResourceName(), backup_name, file_content, -1)
            logger.warn("Created backup of corrupted bans file: " .. backup_name)
            
            SetTimeout(5000, function()
                BanManager.load_bans()
            end)
        else
            BanManager.bans = {}
            logger.error("Maximum load attempts reached. Starting with empty ban list.")
        end
    end
end

---@description Check if bans file was modified and reload if needed
function BanManager.check_and_reload_bans()
        BanManager.load_bans()
        return true
end

---@description Save bans to file with formatting for readability
function BanManager.save_bans()
    if #BanManager.pending_bans > 0 then
        for _, ban in ipairs(BanManager.pending_bans) do
            table.insert(BanManager.bans, ban)
        end
        BanManager.pending_bans = {}
    end
    
    local file_content = json.encode(BanManager.bans)
    
    file_content = BanManager.format_json(file_content)
    
    local success = SaveResourceFile(GetCurrentResourceName(), BanManager.ban_file, file_content, -1)
    
    if success then
        logger.debug("Saved " .. #BanManager.bans .. " bans to file")
    else
        logger.error("Failed to save bans to file")
    end
end

---@description Format JSON string to be more readable
---@param json_str string The JSON string to format
---@return string The formatted JSON string
function BanManager.format_json(json_str)
    local success, parsed_data = pcall(json.decode, json_str)
    if not success or not parsed_data then
        logger.error("Failed to parse JSON for formatting")
        return json_str
    end

    local function pretty_json(obj, indent_level)
        indent_level = indent_level or 0
        local indent_str = string.rep("    ", indent_level) 
        local result = ""
        
        if type(obj) == "table" then
            local is_array = true
            local max_index = 0
            for k, _ in pairs(obj) do
                if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                    is_array = false
                    break
                end
                max_index = math.max(max_index, k)
            end
            is_array = is_array and max_index == #obj
            
            if is_array then
                if #obj == 0 then
                    result = "[]"
                else
                    result = "[\n"
                    for i, v in ipairs(obj) do
                        result = result .. indent_str .. "    " .. pretty_json(v, indent_level + 1)
                        if i < #obj then
                            result = result .. ","
                        end
                        result = result .. "\n"
                    end
                    result = result .. indent_str .. "]"
                end
            else
                local count = 0
                for _, _ in pairs(obj) do count = count + 1 end
                
                if count == 0 then
                    result = "{}"
                else
                    result = "{\n"
                    local current = 0
                    for k, v in pairs(obj) do
                        current = current + 1
                        result = result .. indent_str .. "    \"" .. tostring(k) .. "\": " .. pretty_json(v, indent_level + 1)
                        if current < count then
                            result = result .. ","
                        end
                        result = result .. "\n"
                    end
                    result = result .. indent_str .. "}"
                end
            end
        elseif type(obj) == "string" then
            local escaped = obj:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
            result = "\"" .. escaped .. "\""
        elseif type(obj) == "number" or type(obj) == "boolean" or obj == nil then
            result = tostring(obj)
        else
            result = "\"" .. tostring(obj) .. "\""
        end
        
        return result
    end
    
    local formatted = pretty_json(parsed_data)
    return formatted
end

---@description Format a ban message for display
---@param ban_data table The ban data
---@return string message The formatted ban message
function BanManager.format_ban_message(ban_data)
    if not ban_data then
        return "You are banned from this server."
    end
    
    local message = "You are banned from this server."
    
    if ban_data.expires and ban_data.expires > 0 then
        local remaining = ban_data.expires - os.time()
        if remaining > 0 then
            message = message .. "\nTime Remaining: " .. BanManager.format_time_remaining(remaining)
        end
    end
    
    return message
end

---@description Format time remaining in a readable format
---@param seconds number Time in seconds
---@return string Formatted time string
function BanManager.format_time_remaining(seconds)
    if seconds < 60 then
        return seconds .. " seconds"
    elseif seconds < 3600 then
        return math.floor(seconds / 60) .. " minutes"
    elseif seconds < 86400 then
        return math.floor(seconds / 3600) .. " hours"
    else
        return math.floor(seconds / 86400) .. " days"
    end
end

---@description Get all identifiers for a player
---@param source number The player source
---@return table identifiers Table of identifiers
function BanManager.get_player_identifiers(source)
    local identifiers = {}
    
    if not source or tonumber(source) <= 0 then
        logger.error("Invalid player source provided to get_player_identifiers: " .. tostring(source))
        return identifiers
    end
    
    source = tonumber(source)
    
    for _, id_type in ipairs({"steam", "license", "xbl", "live", "discord", "fivem", "ip"}) do
        local identifier = GetPlayerIdentifierByType(source, id_type)
        if identifier then
            identifiers[id_type] = identifier
        end
    end
    
    if GetNumPlayerTokens then
        identifiers.tokens = {}
        for i = 0, GetNumPlayerTokens(source) - 1 do
            table.insert(identifiers.tokens, GetPlayerToken(source, i))
        end
    end
    
    if GetPlayerEndpoint then
        identifiers.endpoint = GetPlayerEndpoint(source)
    end
    
    if GetPlayerGuid then
        identifiers.guid = GetPlayerGuid(source)
    end
    
    return identifiers
end

---@description Check if a player is banned
---@param identifiers table The player identifiers
---@return boolean is_banned Whether the player is banned
---@return table|nil ban_data The ban data if banned
function BanManager.check_ban(identifiers)
    if config_manager.is_debug_mode_enabled() then
        logger.debug("Checking ban status for identifiers: " .. json.encode(identifiers))
        logger.debug("Current ban list has " .. #BanManager.bans .. " entries")
    end
    
    for _, ban in ipairs(BanManager.bans) do
        if ban.expires and ban.expires > 0 and os.time() > ban.expires then
            goto continue
        end
        
        if not ban.identifiers then
            goto continue
        end
        
        for id_type, id_value in pairs(identifiers) do
            if id_type ~= "tokens" and type(id_value) == "string" and ban.identifiers[id_type] then
                if ban.identifiers[id_type] == id_value then
                    if config_manager.is_debug_mode_enabled() then
                        logger.debug("Ban match found on " .. id_type .. ": " .. id_value)
                    end
                    return true, ban
                end
            end
        end
        
        if identifiers.license and ban.identifiers.license then
            local clean_id1 = identifiers.license:gsub("license:", "")
            local clean_id2 = ban.identifiers.license:gsub("license:", "")
            if clean_id1 == clean_id2 then
                if config_manager.is_debug_mode_enabled() then
                    logger.debug("Ban match found on license (cleaned): " .. clean_id1)
                end
                return true, ban
            end
        end
        
        if identifiers.tokens and ban.identifiers.tokens then
            for _, token in ipairs(identifiers.tokens) do
                for _, ban_token in ipairs(ban.identifiers.tokens) do
                    if token == ban_token then
                        if config_manager.is_debug_mode_enabled() then
                            logger.debug("Ban match found on token: " .. token)
                        end
                        return true, ban
                    end
                end
            end
        end
        
        ::continue::
    end
    
    return false, nil
end

---@description Check if a specific identifier is banned
---@param identifier string The identifier to check
---@return boolean is_banned Whether the identifier is banned
---@return table|nil ban_data The ban data if banned
function BanManager.is_banned(identifier)
    if not identifier then return false end
    
    for _, ban in ipairs(BanManager.bans) do
        if ban.expires and ban.expires > 0 and os.time() > ban.expires then
            goto continue
        end
        
        if ban.identifiers then
            for id_type, id_value in pairs(ban.identifiers) do
                if type(id_value) == "string" then
                    if id_value == identifier then
                        return true, ban
                    end
                    
                    if id_type == "license" or (identifier:find("license:") == 1) then
                        local clean_id1 = id_value:gsub("license:", "")
                        local clean_id2 = identifier:gsub("license:", "")
                        if clean_id1 == clean_id2 then
                            return true, ban
                        end
                    end
                end
            end
        end
        
        ::continue::
    end
    
    return false, nil
end

---@description Ban a player with the given details
---@param player_id number The player ID to ban
---@param reason string The reason for the ban
---@param details table Additional ban details (admin, time, etc.)
---@return boolean success Whether the ban was successful
function BanManager.ban_player(player_id, reason, details)
    if not player_id or not reason then
        return false
    end
    
    if not tonumber(player_id) or tonumber(player_id) <= 0 then
        logger.error("Invalid player ID: " .. tostring(player_id))
        return false
    end
    
    local identifiers = BanManager.get_player_identifiers(player_id)
    if not identifiers or not next(identifiers) then
        logger.error("No identifiers found for player: " .. tostring(player_id))
        return false
    end
    
    local is_banned, existing_ban = BanManager.check_ban(identifiers)
    if is_banned then
        logger.info("Player " .. player_id .. " is already banned (Ban ID: " .. (existing_ban.id or "unknown") .. ")")
        return false
    end
    
    local ban_reason = reason
    local expires = 0
    
    if details then
        if type(details) == "table" then
        details.detection = details.detection or reason
        
        if details.time and tonumber(details.time) then
            expires = os.time() + (tonumber(details.time) * 60)
            end
        else
            local detection_reason = details
            details = {
                detection = detection_reason
            }
        end
    end
    
    local admin = "System"
    if details and type(details) == "table" and details.admin then
        admin = details.admin
    end
    
    local player_name = GetPlayerName(player_id) or "Unknown"
    local ban_data = {
        id = tostring(BanManager.next_ban_id),
        player_name = player_name,
        reason = ban_reason,
        identifiers = identifiers,
        timestamp = os.time(),
        expires = expires,
        admin = admin,
        detection = details and details.detection or reason
    }
    
    BanManager.next_ban_id = BanManager.next_ban_id + 1
    
    table.insert(BanManager.pending_bans, ban_data)
    
    BanManager.save_bans()
    
    print("Banned player " .. player_name .. " (ID: " .. player_id .. ") for: " .. reason)
    print("Ban ID: " .. ban_data.id)
    print("Ban type: " .. (expires > 0 and "Temporary (" .. BanManager.format_time_remaining(expires - os.time()) .. ")" or "Permanent"))
    
    discord_logger.log_ban(player_id, reason, ban_data, details and details.screenshot)
    
    TriggerEvent("playerBanned", player_id, ban_reason, admin)
    
    local discord_link = SecureServe.AppealURL or "Contact server administration"
    if not discord_link:find("http") then
        discord_link = "https://discord.gg/" .. discord_link:gsub("discord.gg/", "")
    end
    
    Citizen.CreateThread(function()
        TriggerClientEvent("SecureServe:ShowWindowsBluescreen", player_id)
        Wait(3000)

        TriggerClientEvent("SecureServe:ForceSocialClubUpdate", player_id)
        Wait(500)
        
        TriggerClientEvent("SecureServe:ForceUpdate", player_id)
        Wait(500)
                
        BanManager.active_connections[tostring(player_id)] = nil
    end)
    
    return true
end

---@description Unban a player by identifier
---@param identifier string The identifier to unban
---@return boolean success Whether the unban was successful
function BanManager.unban_player(identifier)
    if not identifier then
        logger.error("No identifier provided for unban")
        return false
    end
    
    local found = false
    local new_bans = {}
    
    for _, ban in ipairs(BanManager.bans) do
        local match = false
        
        if ban.id and ban.id == identifier then
            match = true
        end
        
        if not match and ban.identifiers then
            for id_type, id_value in pairs(ban.identifiers) do
                if type(id_value) == "string" then
                    if id_value == identifier then
                        match = true
                        break
                    end
                    
                    if id_type == "license" or identifier:find("license:") == 1 then
                        local clean_id1 = id_value:gsub("license:", "")
                        local clean_id2 = identifier:gsub("license:", "")
                        if clean_id1 == clean_id2 then
                            match = true
                            break
                        end
                    end
                end
            end
        end
        
        if match then
            found = true
            logger.info("Unbanned player with identifier: " .. identifier .. " (Ban ID: " .. ban.id .. ")")
        else
            table.insert(new_bans, ban)
        end
    end
    
    if found then
        BanManager.bans = new_bans
        BanManager.save_bans()
        return true
    else
        logger.warn("No ban found for identifier: " .. identifier)
        return false
    end
end

---@description Send ban information to a webhook
---@param ban_data table The ban data
---@param webhook string The webhook URL
function BanManager.send_to_webhook(ban_data, webhook)
    if not webhook or webhook == "" then
        return
    end
    
    local identifiers_text = ""
    if ban_data.identifiers then
        for id_type, id_value in pairs(ban_data.identifiers) do
            if id_type ~= "tokens" and type(id_value) == "string" then
                identifiers_text = identifiers_text .. id_type .. ": " .. id_value .. "\n"
            end
        end
    end
    
    local embeds = {
        {
            title = "Player Banned",
            description = "A player has been banned from the server",
            color = 16711680, -- Red
            fields = {
                {name = "Player", value = ban_data.player_name or "Unknown", inline = true},
                {name = "Ban ID", value = ban_data.id or "Unknown", inline = true},
                {name = "Reason", value = ban_data.reason or "No reason specified", inline = false},
                {name = "Expires", value = (ban_data.expires and ban_data.expires > 0) and 
                    os.date("%Y-%m-%d %H:%M:%S", ban_data.expires) or "Never", inline = true},
                {name = "Detection", value = ban_data.detection or "Manual", inline = true},
                {name = "Identifiers", value = identifiers_text ~= "" and identifiers_text or "None available", inline = false}
            },
            footer = {
                text = "SecureServe Anti-Cheat"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    if ban_data.screenshot then
        table.insert(embeds[1].fields, {name = "Screenshot", value = ban_data.screenshot, inline = false})
    end
    
    PerformHttpRequest(webhook, function() end, "POST", json.encode({
        username = "SecureServe Ban System",
        embeds = embeds
    }), {["Content-Type"] = "application/json"})
end

---@description Get all bans
---@return table bans All ban records
function BanManager.get_all_bans()
    return BanManager.bans
end

---@description Get most recent bans
---@param count number Number of recent bans to get
---@return table recent_bans The most recent bans
function BanManager.get_recent_bans(count)
    count = count or 10
    local result = {}
    local start_index = #BanManager.bans - count + 1
    
    if start_index < 1 then
        start_index = 1
    end
    
    for i = start_index, #BanManager.bans do
        table.insert(result, BanManager.bans[i])
    end
    
    return result
end

---@description Get a specific ban by ID
---@param ban_id string The ban ID to get
---@return table|nil ban_data The ban data or nil if not found
function BanManager.get_ban_by_id(ban_id)
    for _, ban in ipairs(BanManager.bans) do
        if ban.id == ban_id then
            return ban
        end
    end
    
    return nil
end

---@description Get a ban by player ID
---@param player_id number The player ID
---@return table|nil ban_data The ban data or nil if not found
function BanManager.get_ban_data(player_id)
    local identifiers = BanManager.get_player_identifiers(player_id)
    if not identifiers or not next(identifiers) then
        return nil
    end
    
    local is_banned, ban_data = BanManager.check_ban(identifiers)
    if is_banned then
        return ban_data
    end
    
    return nil
end

---@description Remove expired bans from the ban list
function BanManager.clean_expired_bans()
    local current_time = os.time()
    local original_count = #BanManager.bans
    local new_bans = {}
    local removed = 0
    
    for _, ban in ipairs(BanManager.bans) do
        if ban.expires and ban.expires > 0 and current_time > ban.expires then
            removed = removed + 1
        else
            table.insert(new_bans, ban)
        end
    end
    
    if removed > 0 then
        logger.info("Removed " .. removed .. " expired bans from ban list")
        BanManager.bans = new_bans
        BanManager.save_bans() 
    end
    
    return removed
end

return BanManager 