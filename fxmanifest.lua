shared_script '@trappin_security/ai_module_fg-obfuscated.lua'
shared_script '@trappin_security/shared_fg-obfuscated.lua'

fx_version 'cerulean'
game 'gta5'

name "trp_moneywash"
lua54 "yes"

shared_scripts {
    'config.lua',
    "@ox_lib/init.lua"
}

client_scripts {
    'client/cl-token.lua',
    'client/main.lua'
}

server_scripts {
    'server/sv-token.lua',
    'server/main.lua'
}
