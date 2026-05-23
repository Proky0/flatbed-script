fx_version "cerulean"
game "gta5"

author "Proky"
description "Be able to move a bed from a truck"

files {
	"locales/*.json"
}

shared_scripts {
	"@ox_lib/init.lua",
	"shared/*.lua"
}

client_scripts { "client/*.lua" }
server_scripts { "server/*.lua" }