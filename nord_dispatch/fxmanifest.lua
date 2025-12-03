fx_version 'cerulean'
game 'gta5'

author 'Nord Labs'
description 'Dispatch + MDT Integration'
version '1.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}

files {
    'html/ui.html',
    'html/sounds/*.ogg',
    'html/style.css',
    'html/script.js'
}

ui_page 'html/ui.html'

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql'
}
