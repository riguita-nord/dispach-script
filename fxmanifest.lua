fx_version 'cerulean'
game 'gta5'

author 'Nord Labs'
description 'Dispatch + MDT Integration'
version '1.1.0'
provide 'dispach-script'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/bridge.lua',
    'server/update.lua',
    'server/server.lua',
    'server/exports.lua'
}

client_scripts {
    'client/bridge.lua',
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
    'ox_lib',
    'oxmysql'
}
