local Require = require("shared/lib/require")

---@class SharedInit
local SharedInit = {}

---@description Initialize all shared components
function SharedInit.initialize()
    local Encryption = require("shared/lib/encryption")
    
    local Utils = require("shared/lib/utils")
    
    local Callbacks = require("shared/lib/callbacks")
    Callbacks.initialize(IsDuplicityVersion())
    
    Encryption.initialize()
    
    print("^5[SUCCESS] ^3Shared Libraries^7 initialized")
    
    if GetCurrentResourceName() ~= "SecureServe" then
        print("^3SecureServe detected in resource: ^7" .. GetCurrentResourceName())
    end
end

return SharedInit 