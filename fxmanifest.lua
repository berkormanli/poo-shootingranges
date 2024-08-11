fx_version 'cerulean'
author 'zeixna'

games { 'gta5' }

client_scripts {
    'client/interpolations.lua',
    'client/main.lua'
}

shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }

server_scripts {
	'server/main.lua',
}

lua54 'yes'

dependencies {
    '/onesync',
    'ox_target',
    'ox_lib'
}