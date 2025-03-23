---@class DiscordLoggerModule
local DiscordLogger = {
    webhooks = {
        system = "",
        detection = "",
        ban = "",
        kick = "",
        screenshot = "",
        admin = "",
        debug = "",
        join = "",         
        leave = "",       
        kill = "",        
        resource = ""      
    },
    colors = {
        system = 3447003,     -- Blue
        detection = 15105570, -- Orange
        ban = 15158332,       -- Red
        kick = 15844367,      -- Yellow
        screenshot = 3066993, -- Green
        admin = 10181046,     -- Purple
        debug = 9807270,      -- Gray
        join = 5763719,       -- Green-Blue
        leave = 16525609,     -- Light Red
        kill = 16711680,      -- Pure Red
        resource = 2067276    -- Teal
    },
    enabled = true,
    message_queue = {},
    processing = false,
    rate_limit = {
        last_sent = {},
        cooldown = 2         
    }
}

local logger = require("server/core/logger")

---@description Initialize the Discord logger
---@param config table Configuration settings
function DiscordLogger.initialize(config)
    if config and config.Logs then
        for webhook_type, _ in pairs(DiscordLogger.webhooks) do
            if config.Logs and config.Logs[webhook_type] then
                DiscordLogger.webhooks[webhook_type] = config.Logs[webhook_type]
                logger.debug("Setting webhook for " .. webhook_type .. ": " .. 
                    (config.Logs[webhook_type] ~= "" and config.Logs[webhook_type]:sub(1, 30) .. "..." or "Not configured"))
            end
        end
        
        DiscordLogger.enabled = config.Logs.Enabled ~= false
    end
    
    DiscordLogger.registerEventHandlers()
    
    local validWebhooks = false
    for k, v in pairs(DiscordLogger.webhooks) do
        if v ~= "" then
            validWebhooks = true
            break
        end
    end
    
    if not validWebhooks then
        logger.error("No valid Discord webhooks configured, logging will be disabled")
        DiscordLogger.enabled = false
    end
    
    Citizen.CreateThread(function()
        DiscordLogger.process_queue()
    end)
    
    if DiscordLogger.enabled then
        DiscordLogger.log_system(
            "System Started", 
            "The SecureServe Anti-Cheat system has been initialized.",
            {
                {name = "Status", value = "✅ Online", inline = true},
                {name = "Version", value = "SecureServe v1.0", inline = true}
            }
        )
    end
    
    logger.info("Discord logger initialized. Enabled: " .. tostring(DiscordLogger.enabled))
end

---@description Register event handlers for the new webhook types
function DiscordLogger.registerEventHandlers()
    AddEventHandler("playerJoining", function(source, oldID)
        local player_id = tonumber(source)
        if player_id then
            Citizen.SetTimeout(2000, function()
                if GetPlayerName(player_id) then 
                    DiscordLogger.log_join(player_id)
                end
            end)
        end
    end)
    
    AddEventHandler("playerDropped", function(reason)
        local player_id = source
        DiscordLogger.log_leave(player_id, reason or "No reason provided")
    end)
    
    AddEventHandler("onResourceStart", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then
            DiscordLogger.log_resource(resourceName, "started")
        end
    end)
    
    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then
            DiscordLogger.log_resource(resourceName, "stopped")
        end
    end)
    
    AddEventHandler("baseevents:onPlayerDied", function(killerType, deathData)
        local player_id = source
        DiscordLogger.log_death(player_id, nil, deathData)
    end)
    
    AddEventHandler("baseevents:onPlayerKilled", function(killerId, deathData)
        local player_id = source
        DiscordLogger.log_death(player_id, killerId, deathData)
    end)
end

---@description Process the message queue to avoid rate limiting
function DiscordLogger.process_queue()
    while true do
        Citizen.Wait(250)
        
        if #DiscordLogger.message_queue > 0 and not DiscordLogger.processing then
            DiscordLogger.processing = true
            
            local message = table.remove(DiscordLogger.message_queue, 1)
            local webhook_type = message.webhook_type
            local webhook_url = message.webhook_url
            local payload = message.payload
            
            if not webhook_url or webhook_url == "" then
                logger.error("Invalid webhook URL for type: " .. webhook_type)
                DiscordLogger.processing = false
                Citizen.Wait(100)
            else
                logger.debug("Sending Discord webhook to: " .. webhook_url:sub(1, 30) .. "...")
                
                PerformHttpRequest(webhook_url, function(err, text, headers)
                    if err ~= 200 and err ~= 204 then
                        logger.error("Discord webhook failed with error code: " .. tostring(err) .. ", response: " .. tostring(text))
                        
                        local truncated_payload = payload
                        if truncated_payload and #truncated_payload > 100 then
                            truncated_payload = truncated_payload:sub(1, 100) .. "..."
                        end
                        logger.debug("Failed webhook payload (truncated): " .. tostring(truncated_payload))
                    else
                        logger.debug("Successfully sent Discord webhook: " .. webhook_type)
                    end
                    
                    DiscordLogger.processing = false
                    Citizen.Wait(1000) 
                end, "POST", payload, { ["Content-Type"] = "application/json" })
            end
        end
    end
end

---@description Check if a message can be sent (rate limit check)
---@param webhook_type string The webhook type
---@return boolean can_send Whether the message can be sent
function DiscordLogger.can_send(webhook_type)
    if not DiscordLogger.enabled then return false end
    if not DiscordLogger.webhooks[webhook_type] or DiscordLogger.webhooks[webhook_type] == "" then return false end
    return true
end

---@description Get player avatar URL if available
---@param player_id number The player ID
---@return string|nil avatar_url The player's avatar URL or nil
function DiscordLogger.get_player_avatar(player_id)
    local discord_id = nil
    
    for _, identifier in pairs(GetPlayerIdentifiers(player_id) or {}) do
        if string.find(identifier, "discord:") then
            discord_id = string.gsub(identifier, "discord:", "")
            break
        end
    end
    
    if discord_id then
        return "https://cdn.discordapp.com/avatars/" .. discord_id .. ".png?size=128"
    end
    
    return nil
end

---@description Format player identifiers nicely
---@param player_id number The player ID
---@return string identifiers_text Formatted identifiers text
function DiscordLogger.format_identifiers(player_id)
    local identifiers_text = ""
    local identifiers = {}
    
    for _, id_type in ipairs({"steam", "license", "discord", "ip", "xbl", "live", "fivem"}) do
        local id = GetPlayerIdentifierByType(player_id, id_type)
        if id then
            if id_type == "discord" then
                local discord_id = string.gsub(id, "discord:", "")
                table.insert(identifiers, "**Discord:** <@" .. discord_id .. "> (" .. discord_id .. ")")
            elseif id_type == "steam" then
                local steam_hex = string.gsub(id, "steam:", "")
                local steam_dec = tonumber(steam_hex, 16)
                if steam_dec then
                    table.insert(identifiers, "**Steam:** " .. id .. " ([Profile](https://steamcommunity.com/profiles/" .. steam_dec .. "))")
                else
                    table.insert(identifiers, "**Steam:** " .. id)
                end
            else
                table.insert(identifiers, "**" .. id_type .. ":** " .. id)
            end
        end
    end
    
    if GetNumPlayerTokens then
        local tokens = {}
        for i = 0, GetNumPlayerTokens(player_id) - 1 do
            table.insert(tokens, GetPlayerToken(player_id, i))
        end
        
        if #tokens > 0 then
            local tokens_text = ""
            for i = 1, math.min(3, #tokens) do
                tokens_text = tokens_text .. tokens[i] .. "\n"
            end
            
            if #tokens > 3 then
                tokens_text = tokens_text .. "... and " .. (#tokens - 3) .. " more"
            end
            
            table.insert(identifiers, "**HWID Tokens:** ```" .. tokens_text .. "```")
        end
    end
    
    local endpoint = GetPlayerEndpoint(player_id)
    if endpoint then
        table.insert(identifiers, "**Endpoint:** " .. endpoint)
    end
    
    local ping = GetPlayerPing(player_id)
    if ping then
        table.insert(identifiers, "**Ping:** " .. ping .. "ms")
    end
    
    local fivem_id = GetPlayerIdentifierByType(player_id, "fivem")
    if fivem_id then
        local fivem_num = fivem_id:gsub("fivem:", "")
        table.insert(identifiers, "**FiveM Profile:** [" .. fivem_num .. "](https://forum.cfx.re/u/" .. fivem_num .. "/summary)")
    end
    
    return table.concat(identifiers, "\n")
end

---@description Add message to queue for rate-limited sending
---@param webhook_type string The webhook type
---@param payload string JSON payload to send
---@param webhook_url string The webhook URL
function DiscordLogger.queue_message(webhook_type, payload, webhook_url)
    table.insert(DiscordLogger.message_queue, {
        webhook_type = webhook_type,
        webhook_url = webhook_url,
        payload = payload
    })
end

---@description Send a message to a Discord webhook
---@param webhook_type string The webhook type
---@param title string The title of the embed
---@param description string The description text
---@param fields table Optional fields to include
---@param image_url string Optional image URL to include
---@param footer_text string Optional footer text
---@param thumbnail_url string Optional thumbnail URL
function DiscordLogger.send(webhook_type, title, description, fields, image_url, footer_text, thumbnail_url)
    if not DiscordLogger.enabled then
        logger.debug("Discord logger is disabled, not sending webhook")
        return
    end
    
    if not DiscordLogger.webhooks[webhook_type] or DiscordLogger.webhooks[webhook_type] == "" then
        logger.debug("Webhook URL for type " .. webhook_type .. " is not configured")
        return
    end
    
    local webhook_url = DiscordLogger.webhooks[webhook_type]
    
    logger.debug("Preparing Discord webhook: " .. webhook_type)
    
    local currentDate = os.date("%d/%m/%Y")
    local currentTime = os.date("%H:%M:%S")
    local formattedDateTime = currentDate .. " " .. currentTime
    
    local embed = {
        title = title,
        description = description,
        color = DiscordLogger.colors[webhook_type],
        fields = fields or {},
        footer = {
            text = footer_text or "SecureServe Anti-Cheat • " .. formattedDateTime
        }
    }
    
    if image_url then
        embed.image = {
            url = image_url
        }
    end
    
    if thumbnail_url then
        embed.thumbnail = {
            url = thumbnail_url
        }
    end
    
    table.insert(embed.fields, {
        name = "⏰ Date & Time",
        value = currentDate .. " at " .. currentTime,
        inline = true
    })
    
    local payload = {
        username = "SecureServe Anti-Cheat",
        embeds = { embed }
    }
    
    local json_payload = json.encode(payload)
    if not json_payload then
        logger.error("Failed to encode Discord webhook payload to JSON")
        return
    end
    
    DiscordLogger.queue_message(webhook_type, json_payload, webhook_url)
end

---@description Log a player join
---@param player_id number The player ID
function DiscordLogger.log_join(player_id)
    if not DiscordLogger.can_send("join") then return end
    
    local player_name = GetPlayerName(player_id) or "Unknown"
    
    local identifiers_text = DiscordLogger.format_identifiers(player_id)
    
    local connection_info = ""
    local endpoint = GetPlayerEndpoint(player_id)
    local ping = GetPlayerPing(player_id)
    
    if endpoint then
        connection_info = connection_info .. "IP: " .. endpoint
    end
    
    if ping then
        connection_info = connection_info .. " | Ping: " .. ping .. "ms"
    end
    
    local location = "Unknown"
    if endpoint and endpoint ~= "" then
        location = "Location lookup disabled"
    end
    
    local clientInfo = "FiveM Client"
    
    local fields = {
        {name = "Player", value = player_name .. " (ID: " .. player_id .. ")", inline = true},
        {name = "Players Online", value = tostring(GetNumPlayerIndices()), inline = true},
        {name = "Connection", value = connection_info ~= "" and connection_info or "Unknown", inline = true}
    }
    
    table.insert(fields, {name = "Client", value = clientInfo, inline = true})
    
    local serverInfo = "Server: " .. GetConvar("sv_hostname", "Unknown") .. "\nSlots: " .. GetConvar("sv_maxclients", "Unknown")
    table.insert(fields, {name = "Server Info", value = serverInfo, inline = true})
    
    table.insert(fields, {name = "Identifiers", value = identifiers_text ~= "" and identifiers_text or "None found", inline = false})
    
    DiscordLogger.send(
        "join",
        "👋 Player Joined",
        "A player has joined the server.",
        fields,
        nil,
        nil,
        DiscordLogger.get_player_avatar(player_id)
    )
    
    logger.info(player_name .. " (ID: " .. player_id .. ") joined the server")
end

---@description Log a player leave
---@param player_id number The player ID
---@param reason string The reason for leaving
function DiscordLogger.log_leave(player_id, reason)
    if not DiscordLogger.can_send("leave") then return end
    
    local player_name = GetPlayerName(player_id) or "Unknown"
    
    local identifiers_text = DiscordLogger.format_identifiers(player_id)
    
    local sessionStart = 0 
    local sessionDuration = "Unknown"
    
    if sessionStart > 0 then
        local duration = os.time() - sessionStart
        sessionDuration = DiscordLogger.format_time_remaining(duration)
    end
    
    local fields = {
        {name = "Player", value = player_name .. " (ID: " .. player_id .. ")", inline = true},
        {name = "Reason", value = "```" .. reason .. "```", inline = true},
        {name = "Players Online", value = tostring(math.max(0, GetNumPlayerIndices() - 1)), inline = true}
    }
    
    if sessionDuration ~= "Unknown" then
        table.insert(fields, {name = "Session Duration", value = sessionDuration, inline = true})
    end
    
    table.insert(fields, {name = "Identifiers", value = identifiers_text ~= "" and identifiers_text or "None found", inline = false})
    
    DiscordLogger.send(
        "leave",
        "🚪 Player Left",
        "A player has left the server.",
        fields,
        nil,
        nil,
        DiscordLogger.get_player_avatar(player_id)
    )
    
    logger.info(player_name .. " (ID: " .. player_id .. ") left the server: " .. reason)
end

---@description Log a player death/kill
---@param player_id number The victim ID
---@param killer_id number|nil The killer ID (nil if suicide or NPC)
---@param data table Death data
function DiscordLogger.log_death(player_id, killer_id, data)
    if not DiscordLogger.can_send("kill") then return end
    
    local victim_name = GetPlayerName(player_id) or "Unknown"
    local killer_name = killer_id and GetPlayerName(killer_id) or "NPC/Environment"
    local killerText = killer_id and killer_name .. " (ID: " .. killer_id .. ")" or killer_name
    
    local victim_identifiers = DiscordLogger.format_identifiers(player_id)
    
    local deathType = "Died"
    local deathIcon = "💀"
    
    if killer_id and killer_id > 0 then
        deathType = "Killed by Player"
        deathIcon = "🔫" 
    elseif killer_id == 0 then
        deathType = "Killed by NPC"
        deathIcon = "🤖"
    end
    
    local fields = {
        {name = "Victim", value = victim_name .. " (ID: " .. player_id .. ")", inline = true},
        {name = "Killer", value = killerText, inline = true},
        {name = "Death Type", value = deathType, inline = true}
    }
    
    if data and data.weaponHash then
        local weaponName = data.weaponName or "Unknown Weapon"
        table.insert(fields, {name = "Weapon", value = weaponName, inline = true})
    end
    
    table.insert(fields, {name = "Victim Identifiers", value = victim_identifiers ~= "" and victim_identifiers or "None found", inline = false})
    
    if killer_id and killer_id > 0 then
        local killer_identifiers = DiscordLogger.format_identifiers(killer_id)
        if killer_identifiers ~= "" then
            table.insert(fields, {name = "Killer Identifiers", value = killer_identifiers, inline = false})
        end
    end
    
    DiscordLogger.send(
        "kill",
        deathIcon .. " Player " .. deathType,
        "A player has " .. string.lower(deathType) .. ".",
        fields,
        nil,
        nil,
        DiscordLogger.get_player_avatar(player_id)
    )
end

---@description Log a resource event
---@param resource_name string The resource name
---@param action string The action (started, stopped)
function DiscordLogger.log_resource(resource_name, action)
    if not DiscordLogger.can_send("resource") then return end
    
    local fields = {
        {name = "Resource", value = "```" .. resource_name .. "```", inline = true},
        {name = "Action", value = action == "started" and "✅ Started" or "❌ Stopped", inline = true}
    }
    
    table.insert(fields, {
        name = "Server Info", 
        value = "Players Online: **" .. GetNumPlayerIndices() .. "**", 
        inline = true
    })
    
    DiscordLogger.send(
        "resource",
        "🔌 Resource " .. (action == "started" and "Started" or "Stopped"),
        "A server resource has been " .. action .. ".",
        fields
    )
end

---@description Request and process a screenshot
---@param player_id number The player ID
---@param reason string The reason for screenshot
---@param callback function Optional callback after screenshot is taken
function DiscordLogger.request_screenshot(player_id, reason, callback)
    if not player_id or player_id <= 0 then
        logger.error("Cannot request screenshot: Invalid player ID")
        return
    end
    
    local player_name = GetPlayerName(player_id) or "Unknown"
    logger.debug("Requesting screenshot from " .. player_name .. " (ID: " .. player_id .. ")")
    
    if not _G.exports or not _G.exports['screenshot-basic'] then
        logger.error("Failed to take screenshot: screenshot-basic export not available")
        if callback then callback(nil) end
        return
    end
    
    local success, err = pcall(function()
        _G.exports['screenshot-basic']:requestClientScreenshot(player_id, {
            quality = 0.95,
            encoding = 'jpg'
        }, function(err, data)
            if err then
                logger.error("Screenshot failed: " .. tostring(err))
                if callback then callback(nil) end
                return
            end
            
            if data and data:sub(1, 23) == "data:image/jpeg;base64," then
                local image_url = data
                logger.debug("Screenshot received for " .. player_name)
                
                DiscordLogger.log_screenshot(player_id, reason, image_url)
                
                if callback then callback(image_url) end
            else
                logger.error("Screenshot data invalid")
                if callback then callback(nil) end
            end
        end)
    end)
    
    if not success then
        logger.error("Error taking screenshot: " .. tostring(err))
        if callback then callback(nil) end
    end
end

---@description Log a player detection
---@param player_id number The player ID
---@param detection string The detection type
---@param details table Additional details
---@param take_screenshot boolean Whether to take a screenshot
function DiscordLogger.log_detection(player_id, detection, details, take_screenshot)
    if not DiscordLogger.can_send("detection") then return end
    
    details = details or {}
    local player_name = GetPlayerName(player_id) or "Unknown"
    
    local identifiers_text = DiscordLogger.format_identifiers(player_id)
    
    local fields = {
        {name = "Player", value = player_name .. " (ID: " .. player_id .. ")", inline = true},
        {name = "Detection", value = "```" .. detection .. "```", inline = true}
    }
    
    for k, v in pairs(details) do
        if type(k) == "string" and k ~= "screenshot" then
            table.insert(fields, {name = k, value = "```" .. tostring(v) .. "```", inline = true})
        end
    end
    
    table.insert(fields, {name = "Identifiers", value = identifiers_text ~= "" and identifiers_text or "None found", inline = false})
    
    if take_screenshot then
        DiscordLogger.request_screenshot(player_id, "Detection: " .. detection, function(screenshot_url)
            DiscordLogger.send(
                "detection",
                "🚨 Detection Triggered",
                "A player has triggered anti-cheat detection: **" .. detection .. "**",
                fields,
                screenshot_url,
                nil,
                DiscordLogger.get_player_avatar(player_id)
            )
        end)
    else
    DiscordLogger.send(
        "detection",
            "🚨 Detection Triggered",
            "A player has triggered anti-cheat detection: **" .. detection .. "**",
        fields,
            nil,
            nil,
            DiscordLogger.get_player_avatar(player_id)
    )
    end
end

---@description Log a player ban
---@param player_id number The player ID
---@param reason string The ban reason
---@param ban_data table The ban data
---@param screenshot string|nil The screenshot URL
function DiscordLogger.log_ban(player_id, reason, ban_data, screenshot)
    if not DiscordLogger.can_send("ban") then return end
    
    ban_data = ban_data or {}
    local player_name = GetPlayerName(player_id) or ban_data.player_name or "Unknown"
    
    local identifiers_text = DiscordLogger.format_identifiers(player_id)
    
    local tokens_list = {}
    if GetNumPlayerTokens then
        for i = 0, GetNumPlayerTokens(player_id) - 1 do
            table.insert(tokens_list, GetPlayerToken(player_id, i))
        end
    end
    
    local connection_info = ""
    local endpoint = GetPlayerEndpoint(player_id)
    local ping = GetPlayerPing(player_id)
    
    if endpoint then
        connection_info = connection_info .. "IP: " .. endpoint
    end
    
    if ping then
        connection_info = connection_info .. " | Ping: " .. ping .. "ms"
    end
    
    local fields = {
        {name = "Player", value = player_name .. " (ID: " .. player_id .. ")", inline = true},
        {name = "Reason", value = "```" .. reason .. "```", inline = true},
        {name = "Ban Type", value = (ban_data.expires and ban_data.expires > 0) and "⏱️ Temporary" or "🔒 Permanent", inline = true}
    }
    
    if ban_data.expires and ban_data.expires > 0 then
        local duration = os.date("%Y-%m-%d %H:%M:%S", ban_data.expires)
        local time_remaining = ban_data.expires - os.time()
        local formatted_time = "Unknown"
        
        if time_remaining > 0 then
            formatted_time = DiscordLogger.format_time_remaining(time_remaining)
        end
        
        table.insert(fields, {name = "Expires", value = duration .. " (" .. formatted_time .. ")", inline = true})
    end
    
    if ban_data.admin then
        table.insert(fields, {name = "Banned By", value = ban_data.admin, inline = true})
    end
    
    if connection_info ~= "" then
        table.insert(fields, {name = "Connection Info", value = connection_info, inline = true})
    end
    
    if ban_data.id then
        table.insert(fields, {name = "Ban ID", value = ban_data.id, inline = true})
    end
    
    if ban_data.detection then
        table.insert(fields, {name = "Detection", value = "```" .. ban_data.detection .. "```", inline = false})
    end
    
    if #tokens_list > 0 then
        local tokens_text = "```\n"
        for i, token in ipairs(tokens_list) do
            tokens_text = tokens_text .. token .. "\n"
            if i % 5 == 0 and i < #tokens_list then
                tokens_text = tokens_text .. "```"
                table.insert(fields, {name = "HWID Tokens " .. math.floor(i/5), value = tokens_text, inline = false})
                tokens_text = "```\n"
            end
        end
        tokens_text = tokens_text .. "```"
        
        table.insert(fields, {name = "HWID Tokens " .. (math.floor(#tokens_list/5) + 1), value = tokens_text, inline = false})
    end
    
    if identifiers_text ~= "" then
        table.insert(fields, {name = "Identifiers", value = identifiers_text, inline = false})
    end
    
    DiscordLogger.send(
        "ban",
        "🔨 Player Banned",
        "A player has been banned from the server.",
        fields,
        screenshot,
        nil,
        DiscordLogger.get_player_avatar(player_id)
    )
    
    TriggerClientEvent("SecureServe:ForceSocialClubUpdate", player_id)
end

---@description Log a player kick
---@param player_id number The player ID
---@param reason string The kick reason
---@param admin string Who kicked the player
---@param take_screenshot boolean Whether to take a screenshot
function DiscordLogger.log_kick(player_id, reason, admin, take_screenshot)
    if not DiscordLogger.can_send("kick") then return end
    
    local player_name = GetPlayerName(player_id) or "Unknown"
    
    local identifiers_text = DiscordLogger.format_identifiers(player_id)
    
    local fields = {
        {name = "Player", value = player_name .. " (ID: " .. player_id .. ")", inline = true},
        {name = "Reason", value = "```" .. reason .. "```", inline = true}
    }
    
    if admin then
        table.insert(fields, {name = "Admin", value = "👮 " .. admin, inline = true})
    end
    
    if identifiers_text ~= "" then
        table.insert(fields, {name = "Identifiers", value = identifiers_text, inline = false})
    end
    
    if take_screenshot then
        DiscordLogger.request_screenshot(player_id, "Kick: " .. reason, function(screenshot_url)
            DiscordLogger.send(
                "kick",
                "👢 Player Kicked",
                "A player has been kicked from the server.",
                fields,
                screenshot_url,
                nil,
                DiscordLogger.get_player_avatar(player_id)
            )
        end)
    else
    DiscordLogger.send(
        "kick",
            "👢 Player Kicked",
        "A player has been kicked from the server.",
        fields,
            nil,
            nil,
            DiscordLogger.get_player_avatar(player_id)
    )
    end
end

---@description Log a screenshot
---@param player_id number The player ID
---@param reason string The reason for the screenshot
---@param screenshot_url string The screenshot URL
---@param details table Additional details
function DiscordLogger.log_screenshot(player_id, reason, screenshot_url, details)
    if not DiscordLogger.can_send("screenshot") then return end
    
    details = details or {}
    local player_name = GetPlayerName(player_id) or "Unknown"
    
    local fields = {
        {name = "Player", value = player_name .. " (ID: " .. player_id .. ")", inline = true},
        {name = "Reason", value = reason, inline = true}
    }
    
    for k, v in pairs(details) do
        if type(k) == "string" then
            table.insert(fields, {name = k, value = "```" .. tostring(v) .. "```", inline = true})
        end
    end
    
    table.insert(fields, {name = "Server Info", value = "Players: " .. GetNumPlayerIndices() .. "\nTime: " .. os.date("%H:%M:%S"), inline = true})
    
    DiscordLogger.send(
        "screenshot",
        "📸 Player Screenshot",
        "A screenshot has been taken of a player.",
        fields,
        screenshot_url,
        nil,
        DiscordLogger.get_player_avatar(player_id)
    )
end

---@description Log an admin action
---@param admin_id number The admin ID (or 0 for console)
---@param action string The action performed
---@param target string The target of the action
---@param details table Additional details
function DiscordLogger.log_admin(admin_id, action, target, details)
    if not DiscordLogger.can_send("admin") then return end
    
    details = details or {}
    local admin_name = admin_id > 0 and GetPlayerName(admin_id) or "Console"
    
    local fields = {
        {name = "Admin", value = admin_name .. (admin_id > 0 and " (ID: " .. admin_id .. ")" or ""), inline = true},
        {name = "Action", value = "```" .. action .. "```", inline = true},
        {name = "Target", value = target, inline = true}
    }
    
    for k, v in pairs(details) do
        if type(k) == "string" then
            table.insert(fields, {name = k, value = "```" .. tostring(v) .. "```", inline = true})
        end
    end
    
    table.insert(fields, {name = "Timestamp", value = "🕒 " .. os.date("%Y-%m-%d %H:%M:%S"), inline = true})
    
    DiscordLogger.send(
        "admin",
        "🛡️ Admin Action",
        "An admin has performed an action.",
        fields,
        nil,
        nil,
        admin_id > 0 and DiscordLogger.get_player_avatar(admin_id) or nil
    )
end

---@description Log system information or errors
---@param title string The title of the message
---@param description string The message description
---@param fields table Optional fields to include
function DiscordLogger.log_system(title, description, fields)
    if not DiscordLogger.can_send("system") then return end
    
    fields = fields or {}
    
    local playerCount = GetNumPlayerIndices()
    
    table.insert(fields, {
        name = "🖥️ Server Info", 
        value = "Players Online: **" .. playerCount .. "**\nServer Time: **" .. os.date("%d/%m/%Y %H:%M:%S") .. "**", 
        inline = true
    })
    
    DiscordLogger.send(
        "system",
        "🖥️ " .. title,
        description,
        fields
    )
end

---@description Log debug information
---@param title string The title of the message
---@param description string The message description
---@param fields table Optional fields to include
function DiscordLogger.log_debug(title, description, fields)
    if not DiscordLogger.can_send("debug") then return end
    
    DiscordLogger.send(
        "debug",
        "🔍 " .. title,
        description,
        fields
    )
end

return DiscordLogger 