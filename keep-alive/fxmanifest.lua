fx_version "cerulean"

shared_script "@SecureServe/src/module/module.lua"

file "@SecureServe/secureserve.key"
game "gta5"

version "1.1.0"
description "Canary auxiliar del anticheat SecureServe"

client_scripts {
    "client.lua",
}

dependencies {
    "/server:5181",
}

lua54 "yes"
