fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'GESUS'
description 'Campfire Script'
version '1.0.0'

client_script {
    'client/*.lua',

}
server_script {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}
shared_scripts {
    '@ox_lib/init.lua',
    '@Renewed-Lib/init.lua',
    'shared/*.lua',
}
ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/styles.css',
    'nui/script.js',
}

dependencies {
    'ox_lib',
}

