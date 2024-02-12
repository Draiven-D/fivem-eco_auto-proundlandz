fx_version 'adamant'
game 'gta5'

description 'eco'

version '1.0.0'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'config.lua',
	-- 'server/main.lua'
}

client_scripts {
	'client/main.lua'
}

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/main.js',
  'html/style.css'
}

-- data_file 'DLC_ITYP_REQUEST' 'stream/likemod_rock_anim_props.ytyp'

dependencies {
	'es_extended',
}