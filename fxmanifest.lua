fx_version 'adamant'
game 'gta5'

name 'esx-tow'
author 'Seu Nome'
description 'Sistema avançado de reboque com rampas móveis, guincho e modo de edição para ESX-Legacy'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/editor.lua',
    'client/movable_ramps.lua',
    'client/winch.lua',
    'client/attach_system.lua',
    'client/fixed_ramps.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib'
}