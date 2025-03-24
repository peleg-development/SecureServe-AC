---@class AntiExecutionModule
local AntiExecution = {}

local ban_manager = require("server/core/ban_manager")
local config_manager = require("server/core/config_manager")

local blocked_menus = {
    "rootMenu",
    "rootMenuv2",
    "rootMenuv3",
    "Wugr4yfgb"
}

local blacklisted_executors = {
    "Eulen",
    "EulenMenu",
    "EulenMenu2",
    "EulenMenu3",
    "SkidMenu",
    "AbsoluteEulen",
    "HamMafia",
    "LynxRevolution",
    "Lynx8",
    "LynxSeven",
    "TiagoMenu",
    "MarketMenu",
    "KoGuSzEk",
    "SentioMenu",
    "SwagMenu",
    "Dopamine",
    "Script Hook",
    "ScrHook",
    "d0pa1998",
    "HydroMenu",
    "D0paMenu",
    "Lux",
    "LuxuinityMenu",
    "OpenMenuV",
    "xAries",
    "Krepozz",
    "CiacaDasai",
    "GenesisV",
    "Deluxe Menu",
    "Ruby",
    "SwagCheats",
    "HudMenuX",
    "xseira",
    "SkazaMenu",
    "WADUI",
    "aries",
    "SidMenu",
    "AlwaysKaffa",
    "Lynx",
    "Maestro Menu",
    "NertigelFunc",
    "FendinX",
    "Root Menu",
    "Fuckingmenu",
    "Falcon",
    "Fallout Menu",
    "Redengine",
    "Executor",
    "DreamMenu",
    "Executor.lua",
    "RottenV",
    "Deer Menu",
    "Dopameme",
    "dopamine",
    "ICMENU",
    "Qlieplayer",
    "MaestroMenu",
    "Roblox Hack",
    "Nano",
    "SKRIPT.LUA",
    "Macias",
    "GrubyMenu",
    "Wolfi",
    "Ham",
    "luminous",
    "Absolute",
    "Mockingbird",
    "FlexSkazaMenu",
    "Nebula",
    "BellaMenu",
    "WaveMenu"
}

---@description Initialize anti-execution module
function AntiExecution.initialize()
    RegisterNetEvent("SecureServe:Server_Callbacks:Detections:RegisterKnownMenus", function(menus)
        for menu_name, _ in pairs(menus) do
            if config_manager.is_menu_detection_enabled() then
                for _, blocked_menu in ipairs(blocked_menus) do
                    if string.lower(menu_name) == string.lower(blocked_menu) then
                        ban_manager.ban_player(source, "Menu Detection", "Detected menu: " .. menu_name)
                        return
                    end
                end
                
                for _, blacklisted_executor in ipairs(blacklisted_executors) do
                    if string.lower(menu_name) == string.lower(blacklisted_executor) then
                        ban_manager.ban_player(source, "Executor Detection", "Detected executor: " .. menu_name)
                        return
                    end
                end
            end
        end
    end)
    
    RegisterNetEvent("__cfx_internal:handlePlayerTrigger", function(name, source)
        if config_manager.is_trigger_protection_enabled() then
            if name == "chat:addMessage" then
                ban_manager.ban_player(source, "Trigger Protection", "Tried executing chat:addMessage")
            end
        end
    end)
    
    AddEventHandler("playerConnecting", function(_, _, deferrals)
        local source = source
        deferrals.defer()
        
        Wait(100)
        
        if GetPlayerEndpoint(source) == nil then
            deferrals.done("SecureServe: Invalid connection detected.")
            CancelEvent()
        else
            deferrals.update("SecureServe: Checking connection...")
            deferrals.done()
        end
    end)
end

return AntiExecution 