author "JericoFX#3512"
fx_version 'cerulean'
game "gta5"
description "JK Helper"

version "0.0.1"

client_script "client/init.lua"

shared_scripts { '@ox_lib/init.lua', "shared/init.lua" }
server_scripts { "@oxmysql/lib/MySQL.lua", "server/init.lua" }


lua54 'yes'

use_fxv2_oal 'on'

is_cfxv2 'yes'

files {
    "client/modules/*.*",
}

dependencies {
    '/onesync',
    "ox_lib"
}

-- jobs {
--     police {
--         blip = true,
--         stash = true,
--         privateStash = true,
--         clothes = true,
--         garage = true,
--         boss = true,
--         duty = true,
--         dj = true
--     },
--     ambulance {
--         blip = true,
--         stash = true,
--         privateStash = true,
--         clothes = true,
--         garage = true,
--         boss = true,
--         duty = true,
--         dj = true
--     }
-- }
