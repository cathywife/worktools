function execcmd(cmd){
	var exec = require('child_process').exec;
          exec(cmd, function callback(error, stdout, stderr) {
               console.log(stdout);
          })
}
//拷贝后文件为空 放弃~
function copy(src, dst) {
	var fs = require('fs')
    	fs.createReadStream(src).pipe(fs.createWriteStream(dst));
	console.log("test")
}

function main(){
	if(process.argv.length != 4){
		console.log("Usage: node thisNode target worldId");
		process.exit(0);
	}
	var target = process.argv[2];
	var worldId = parseInt(process.argv[3]);

	var configPath;
	var serverConfig;
	var worldConfig;
	if(target === "NBA2_and"){
	  src= "/nba/server/server_config_CN_PROD.js.and"
	  dst="/data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js"
	  cmd = "cp "+src+" "+dst+" -rf"
	  execcmd(cmd)
	  configPath = dst;
	}else if(target === "NBA2_yyb"){
	  src= "/nba/server/server_config_CN_PROD.js.yyb"
          dst="/data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js"
	  cmd = "cp "+src+" "+dst+" -rf"
          execcmd(cmd)
	  configPath = dst
	}else if(target === "NBA1_cn"){
	  configPath = "/data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js";
	}
	serverConfig = require(configPath).data;
	if(! serverConfig){
		console.log("server config not found", configPath);
		process.exit(0);
	}
	
	for(var i = 0; i < serverConfig.length; ++i){
		if(serverConfig[i]._id == worldId){
			worldConfig = serverConfig[i];
			break;
		}
	}
	
	if(! worldConfig){
		console.log("world config not found");
		process.exit(0);
	}

	var tiantiDuration = 7;
	var curDate = new Date();
	var serviceStartTime = new Date(worldConfig.start[0], worldConfig.start[1] - 1, worldConfig.start[2], worldConfig.start[3], worldConfig.start[4]);
	var timezoneOffset = curDate.getTimezoneOffset();
	var curDay = (curDate.getTime() - timezoneOffset * 60000) / 86400000 | 0;
	var serviceStartDay = (serviceStartTime.getTime() - timezoneOffset * 60000) / 86400000 | 0;
	var tiantiSeason = parseInt((curDay - serviceStartDay) / tiantiDuration) + 1;
	var dayDiff = ((curDate.getTime() + 28800000) / 86400000 | 0) - ((serviceStartTime.getTime() + 28800000) / 86400000 | 0);
	dayDiff = dayDiff % tiantiDuration;
	var tiantiStartTime = new Date(curDate.getTime()  - dayDiff * 86400000);
	var tiantiEndTime = new Date(tiantiStartTime.getTime() + tiantiDuration * 86400000);
	
	console.log("ID:"+worldId+"天梯目前为第 ", tiantiSeason, " 期的 ", dayDiff, " 天");
	console.log("最新一期时间: "+tiantiStartTime.getFullYear() + "-" + (tiantiStartTime.getMonth() + 1) + "-" + tiantiStartTime.getDate() + " 00:00 ~ ", tiantiEndTime.getFullYear() + "-" + (tiantiEndTime.getMonth() + 1) + "-" + tiantiEndTime.getDate()+" 00:00")
}
main();
