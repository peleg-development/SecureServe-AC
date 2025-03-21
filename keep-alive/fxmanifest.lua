
fx_version "cerulean"

shared_script "@SecureServe/src/module/module.lua"
shared_script "@SecureServe/src/module/module.js"

file "@SecureServe/secureserve.key"

-- SecureServe Protection
shared_script "@SecureServe/module/module.lua"
shared_script "@SecureServe/module/module.js"
game "gta5"

version "1.0.0"


client_scripts {
    "client.lua",
}

dependencies {
    "/server:5181",
    "screenshot-basic"
}

lua54 "yes"

