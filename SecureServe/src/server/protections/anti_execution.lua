local AntiExecution = {}

local ban_manager    = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

local blocked_set, executor_set = {}, {}

local function rebuild_lookups()
    blocked_set, executor_set = {}, {}

    local blocked_menus = (SecureServe and SecureServe.BlockedMenus) or {}
    for _, m in ipairs(blocked_menus) do
        if type(m) == "string" then
            blocked_set[m:lower()] = true
        end
    end

    local executors = (SecureServe and SecureServe.BlacklistedExecutors) or {}
    for _, e in ipairs(executors) do
        if type(e) == "string" then
            executor_set[e:lower()] = true
        end
    end
end

function AntiExecution.initialize()
    rebuild_lookups()

    RegisterNetEvent("SecureServe:Server_Callbacks:Detections:RegisterKnownMenus", function(menus)
        local src = source
        if type(menus) ~= "table" then return end
        if not config_manager.is_menu_detection_enabled() then return end

        for menu_name, _ in pairs(menus) do
            local key = type(menu_name) == "string" and menu_name:lower() or nil
            if key then
                if blocked_set[key] then
                    ban_manager.ban_player(src, "Menu Detection", {
                        admin     = "Anti-Cheat System",
                        time      = 2147483647,
                        detection = "Detected menu: " .. menu_name,
                    })
                    return
                elseif executor_set[key] then
                    ban_manager.ban_player(src, "Executor Detection", {
                        admin     = "Anti-Cheat System",
                        time      = 2147483647,
                        detection = "Detected executor: " .. menu_name,
                    })
                    return
                end
            end
        end
    end)
end

function AntiExecution.reload_lists()
    rebuild_lookups()
end

return AntiExecution
