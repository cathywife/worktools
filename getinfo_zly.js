var fs = require( 'fs' )
var argv=process.argv.slice(2);
var _ENV=argv[0];

function getCNConfig() {
    var _config = [];
    for (var i in configCN) {
        console.log("_id:"+configCN[i]._id,"game_db:"+JSON.stringify(configCN[i].game_db),"login_db:"+JSON.stringify(configCN[i].login_db))
    }
    for (var i in configCN) {
        console.log("_id:"+configCN[i]._id,"start:"+JSON.stringify(configCN[i].start),"combine:"+JSON.stringify(configCN[i].combine),"close:"+JSON.stringify(configCN[i].close))
    }
    for (var i in configCN) {
        console.log("_id:"+configCN[i]._id,"game:"+JSON.stringify(configCN[i].game))
    }
};

if(argv.length < 1){
	var configCN = require('/data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD').data;
}
else
{
	var src='/nba/server/'+"server_config_CN_PROD.js."+ _ENV
	console.log(src)
	var dst='/data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js'
	fs.createReadStream(src).pipe(fs.createWriteStream(dst))
	var configCN = require(src).data;
}

getCNConfig()
