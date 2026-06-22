fx_version "cerulean"

author "@cassanodev"
version '1.0.0'

lua54 'yes'
game "gta5"

shared_scripts {
  '@ox_lib/init.lua',
  'shared/utils.lua',
}

client_script "client/client.lua"
server_script "server/server.lua"

files {
  'shared/settings.lua'
}