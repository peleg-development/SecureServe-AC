fx_version "cerulean"
game "gta5"

author "SecureServe.net"
version "1.1.30"

ui_page 'index.html'
files {
    'stats.json',
    'index.html',
    'app.js',
    'styles.css',
    'bans.json'
}

server_scripts {
    "config.lua",
    "server.lua",
    "server.js",
    "admin_panel_sv.lua"
}

client_scripts {
    "client.lua",
    "admin_panel_cl.lua"
}

shared_scripts {
    "shared.lua",
    "module.lua",
}

dependencies {
    "/server:5181",
    "screenshot-basic"
}

lua54 "yes"

server_export 'banPlayer'

