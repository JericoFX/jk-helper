author "JericoFX#3512"
fx_version 'cerulean'
game "gta5"
description "JK Helper"

version "0.0.6"

client_scripts { "client/admin.lua", "client/init.lua" }


shared_scripts { '@ox_lib/init.lua', "shared/init.lua", "shared/vehicle.lua" }
server_scripts { "@oxmysql/lib/MySQL.lua", "server/init.lua", "server/db.lua" }


lua54 'yes'

use_fxv2_oal 'on'

is_cfxv2 'yes'

files {
    "client/modules/*.*",
    "shared/*.*",
}

dependencies {
    '/onesync',
    "ox_lib"
}
