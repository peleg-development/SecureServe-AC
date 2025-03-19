---@class BanManagerModule
local BanManager = {
    bans = {},
    pending_bans = {},
    ban_file = "bans.json",
    load_attempts = 0,
    max_load_attempts = 5,
    next_ban_id = 1, 
    active_connections = {} 
}

local config_manager = require("server/core/config_manager")
local logger = require("server/core/logger")

---@description Initialize the ban manager
function BanManager.initialize()
    BanManager.load_bans()
    
    for _, ban in ipairs(BanManager.bans) do
        local numeric_id = tonumber(ban.id)
        if numeric_id and numeric_id >= BanManager.next_ban_id then
            BanManager.next_ban_id = numeric_id + 1
        end
    end
    
    AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
        deferrals.defer()
        
        local source = source
        local tokens = {}
        
        if GetNumPlayerTokens and source then
            for i = 0, GetNumPlayerTokens(source) - 1 do
                table.insert(tokens, GetPlayerToken(source, i))
            end
        end
        
        Citizen.Wait(100)
        
        local identifiers = GetPlayerIdentifiers(source) or {}
        local license = nil
        local steam = nil
        local hasSteam = false
        
        for _, identifier in ipairs(identifiers) do
            if string.match(identifier, "license:") then
                license = identifier
            elseif string.match(identifier, "steam:") then
                steam = identifier
                hasSteam = true
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
            
            deferrals.presentCard(steamCard, function(data, rawData) end)
            
            Citizen.CreateThread(function()
                while true do
                    Citizen.Wait(1000)
                    deferrals.presentCard(steamCard, function(data, rawData) end)
                    CancelEvent()
                end
            end)
            
            setKickReason("Steam is required to join this server. Please open Steam and restart FiveM.")
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
        
        if source and tonumber(source) > 0 then
            BanManager.active_connections[tostring(source)] = identifiersTable
        end
        
        local is_banned, ban_data = BanManager.check_ban(identifiersTable)
        
        if is_banned then
            logger.info("Blocked banned player connection: " .. name .. " (" .. (identifiersTable.license or "unknown") .. ")")
            
            -- Format ban details for the card
            local ban_id = ban_data.id or "Unknown"
            local reason = ban_data.reason or "Violating server rules"
            local ban_type = "Permanent"
            local expires_value = "Never"
            
            if ban_data.expires and ban_data.expires > 0 then
                local remaining = ban_data.expires - os.time()
                if remaining > 0 then
                    ban_type = "Temporary"
                    expires_value = os.date("%Y-%m-%d %H:%M:%S", ban_data.expires)
                else
                    deferrals.done()
                    return
                end
            end
            
            local discord_link = SecureServe.AppealURL or "Contact server administration"
            if not discord_link:find("http") then
                discord_link = "https://discord.gg/" .. discord_link:gsub("discord.gg/", "")
            end
            
            local card = [[
                {
                    "type": "AdaptiveCard",
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "version": "1.0",
                    "body": [
                        {
                            "type": "Container",
                            "style": "attention",
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "text": "BANNED",
                                    "wrap": true,
                                    "horizontalAlignment": "Center",
                                    "size": "ExtraLarge",
                                    "weight": "Bolder",
                                    "color": "light",
                                    "spacing": "Small"
                                }
                            ]
                        },
                        {
                            "type": "Container",
                            "style": "default",
                            "items": [
                                {
                                    "type": "TextBlock",
                                    "text": "Access to this server has been denied",
                                    "wrap": true,
                                    "horizontalAlignment": "Center",
                                    "size": "Medium",
                                    "weight": "Bolder",
                                    "spacing": "Small"
                                }
                            ]
                        },
                        {
                            "type": "FactSet",
                            "facts": [
                                {
                                    "title": "Ban ID",
                                    "value": "%s"
                                },
                                {
                                    "title": "Ban Type",
                                    "value": "%s"
                                },
                                {
                                    "title": "Issued",
                                    "value": "%s"
                                },
                                {
                                    "title": "Expires",
                                    "value": "%s"
                                }
                            ]
                        },
                        {
                            "type": "TextBlock",
                            "text": "SECURESERVE PROTECTION",
                            "wrap": true,
                            "horizontalAlignment": "Center",
                            "size": "Medium",
                            "weight": "Bolder",
                            "color": "accent",
                            "spacing": "Medium"
                        }
                    ],
                    "actions": [
                        {
                            "type": "Action.OpenUrl",
                            "title": "Appeal on Discord",
                            "url": "%s"
                        }
                    ]
                }
            ]]
            
            local formatted_card = string.format(
                card,
                ban_id,
                ban_type,
                os.date("%Y-%m-%d %H:%M:%S", ban_data.timestamp or os.time()),
                expires_value,
                discord_link
            )
            
            deferrals.defer()
            
            deferrals.presentCard(formatted_card, function(data, rawData) end)
            
            Citizen.CreateThread(function()
                while true do
                    Citizen.Wait(10)
                    deferrals.defer()
                    deferrals.presentCard(formatted_card, function(data, rawData) end)
                    CancelEvent()
                end
            end)
            
            return
        else
            deferrals.done()
        end
    end)
    
    AddEventHandler("playerDropped", function(reason)
        local source = source
        
        if not source or tonumber(source) <= 0 then
            return
        end
        
        BanManager.active_connections[tostring(source)] = nil
    end)
    
    AddEventHandler("playerJoining", function(source, oldID)
        if not source or tonumber(source) <= 0 then
            return
        end
        
        local player_name = GetPlayerName(source) or "Unknown"
        local identifiers = BanManager.get_player_identifiers(source)
        
        if not identifiers or not next(identifiers) then
            identifiers = BanManager.active_connections[tostring(source)]
            
            if not identifiers or not next(identifiers) then
                local rawIdentifiers = GetPlayerIdentifiers(source) or {}
                identifiers = {}
                
                for _, identifier in ipairs(rawIdentifiers) do
                    local idType = string.match(identifier, "^([^:]+):")
                    if idType then
                        identifiers[idType] = identifier
                    end
                end
                
                if GetNumPlayerTokens then
                    identifiers.tokens = {}
                    for i = 0, GetNumPlayerTokens(source) - 1 do
                        table.insert(identifiers.tokens, GetPlayerToken(source, i))
                    end
                end
            end
            
            if not identifiers or not next(identifiers) then
                logger.warn("No identifiers found for joining player: " .. player_name .. " (ID: " .. source .. ")")
                return
            end
        end
        
        BanManager.active_connections[tostring(source)] = identifiers
        
        local is_banned, ban_data = BanManager.check_ban(identifiers)
        if is_banned then
            logger.info("Caught banned player after joining: " .. player_name .. " (" .. (identifiers.license or "unknown") .. ")")
            
            local ban_id = ban_data.id or "Unknown"
            local reason = ban_data.reason or "Violating server rules"
            local ban_type = "Permanent"
            local expires_value = "Never"
            
            if ban_data.expires and ban_data.expires > 0 then
                ban_type = "Temporary"
                expires_value = os.date("%Y-%m-%d %H:%M:%S", ban_data.expires)
            end
            
            Citizen.CreateThread(function()
                Citizen.Wait(500)
                TriggerClientEvent("SecureServe:ForceSocialClubUpdate", source)
                TriggerEvent("SecureServe:KickBannedPlayer", source)
                DropPlayer(source, BanManager.format_ban_message(ban_data))
            end)
        end
    end)
    
    CreateThread(function()
        while true do
            Wait(300000) 
            BanManager.save_bans()
        end
    end)
    
    print("^5[SUCCESS] ^3Ban Manager^7 initialized")
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
        BanManager.bans = result
        logger.info("Loaded " .. #BanManager.bans .. " bans from file")
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

---@description Format a ban message for display to players
---@param ban_data table The ban data to format
---@return string The formatted ban message
function BanManager.format_ban_message(ban_data)
    local message = [[
SecureServe Anti-Cheat

You have been banned from this server.

]]
    
    if ban_data.expires and ban_data.expires > 0 then
        local time_remaining = ban_data.expires - os.time()
        if time_remaining > 0 then
            message = message .. "Ban Duration:" .. BanManager.format_time_remaining(time_remaining) .. "\n\n"
        else
            message = message .. "Your ban has expired. Please refresh to reconnect.\n\n"
        end
    else
        message = message .. "Ban Type: Permanent\n\n"
    end
    
    message = message .. "Ban ID: " .. (ban_data.id or "Unknown") .. "\n"
    message = message .. "Issue Date: " .. os.date("%Y-%m-%d %H:%M:%S", ban_data.timestamp or os.time()) .. "\n\n"
    message = message .. "For appeals, visit: " .. (SecureServe.AppealURL or "Contact server administration") .. "\n"
    
    message = message .. [[
]]
    
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
    for _, ban in ipairs(BanManager.bans) do
        if ban.expires and ban.expires > 0 and os.time() > ban.expires then
            goto continue
        end
        
        for id_type, id_value in pairs(identifiers) do
            if id_type ~= "tokens" and type(id_value) == "string" and ban.identifiers and ban.identifiers[id_type] then
                if ban.identifiers[id_type] == id_value then
                    return true, ban
                end
            end
        end
        
        if identifiers.license and ban.identifiers and ban.identifiers.license then
            local clean_id1 = identifiers.license:gsub("license:", "")
            local clean_id2 = ban.identifiers.license:gsub("license:", "")
            if clean_id1 == clean_id2 then
                return true, ban
            end
        end
        
        if identifiers.tokens and ban.identifiers and ban.identifiers.tokens then
            for _, token in ipairs(identifiers.tokens) do
                for _, ban_token in ipairs(ban.identifiers.tokens) do
                    if token == ban_token then
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

---@description Ban a player
---@param source number The player source
---@param reason string The ban reason
---@param details table Additional ban details
---@return boolean success Whether the ban was successful
function BanManager.ban_player(source, reason, details)
    
    if not source or tonumber(source) <= 0 then
        logger.error("Invalid source provided for ban")
        return false
    end
    
    details = details or {}
    local time = tonumber(details.time) or 0
    local player_name = GetPlayerName(source) or "Unknown"
    
    local identifiers = BanManager.get_player_identifiers(source)
    if not identifiers or not next(identifiers) then
        logger.error("Could not get identifiers for player: " .. player_name .. " (" .. source .. ")")
        return false
    end
    
    local expires = 0
    if time and time > 0 then
        expires = os.time() + (time * 60) 
    end
    
    local ban_id = BanManager.next_ban_id
    BanManager.next_ban_id = BanManager.next_ban_id + 1
    
    local ban_data = {
        id = tostring(ban_id),
        name = player_name,
        reason = reason,
        identifiers = identifiers,
        admin = details.admin or "System",
        timestamp = os.time(),
        expires = expires,
        detection = details.detection or "Manual",
        screenshot = details.screenshot,
        details = details.additional or {}
    }
    
    table.insert(BanManager.pending_bans, ban_data)
    
    BanManager.save_bans()
    
    logger.info("Banned player: " .. player_name .. " (" .. (identifiers.license or "unknown") .. ") for: " .. reason)
    
    if details.webhook then
        BanManager.send_to_webhook(ban_data, details.webhook)
    end
    
    local ban_type = "Permanent"
    local expires_value = "Never"
    local time_remaining = ""
    
    if expires > 0 then
        ban_type = "Temporary"
        expires_value = os.date("%Y-%m-%d %H:%M:%S", expires)
        time_remaining = BanManager.format_time_remaining(expires - os.time())
    end
    
    local discord_link = SecureServe.AppealURL or "Contact server administration"
    if not discord_link:find("http") then
        discord_link = "https://discord.gg/" .. discord_link:gsub("discord.gg/", "")
    end
    
    local card = [[
        {
            "type": "AdaptiveCard",
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "version": "1.0",
            "body": [
                {
                    "type": "Container",
                    "style": "attention",
                    "items": [
                        {
                            "type": "TextBlock",
                            "text": "BANNED",
                            "wrap": true,
                            "horizontalAlignment": "Center",
                            "size": "ExtraLarge",
                            "weight": "Bolder",
                            "color": "light",
                            "spacing": "Small"
                        }
                    ]
                },
                {
                    "type": "Container",
                    "style": "default",
                    "items": [
                        {
                            "type": "TextBlock",
                            "text": "Access to this server has been denied",
                            "wrap": true,
                            "horizontalAlignment": "Center",
                            "size": "Medium",
                            "weight": "Bolder",
                            "spacing": "Small"
                        }
                    ]
                },
                {
                    "type": "FactSet",
                    "facts": [
                        {
                            "title": "Ban ID",
                            "value": "%s"
                        },
                        {
                            "title": "Ban Type",
                            "value": "%s"
                        },
                        {
                            "title": "Issue Date",
                            "value": "%s"
                        },
                        {
                            "title": "Expires",
                            "value": "%s"
                        }
                    ]
                },
                {
                    "type": "TextBlock",
                    "text": "SECURESERVE PROTECTION",
                    "wrap": true,
                    "horizontalAlignment": "Center",
                    "size": "Medium",
                    "weight": "Bolder",
                    "color": "accent",
                    "spacing": "Medium"
                }
            ],
            "actions": [
                {
                    "type": "Action.OpenUrl",
                    "title": "Appeal on Discord",
                    "url": "%s"
                }
            ]
        }
    ]]
    
    local formatted_card = string.format(
        card,
        ban_data.id,
        ban_type,
        os.date("%Y-%m-%d %H:%M:%S", ban_data.timestamp),
        expires_value,
        discord_link
    )
    
    TriggerClientEvent("SecureServe:ForceSocialClubUpdate", source)
    DropPlayer(source, "You have been banned from this server.")
    BanManager.active_connections[tostring(source)] = nil
    
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
                {name = "Player", value = ban_data.name or "Unknown", inline = true},
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

return BanManager 