local Require = require("shared/lib/require")

local SharedInit = require("shared/init")
SharedInit.initialize()

if IsDuplicityVersion() then
    local ServerMain = require("server/main")
else
    local ClientInit = require("client/init")
        CreateThread(function()
        Wait(1000) 
        ClientInit.initialize()
    end)
end 

