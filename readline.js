var readline = require('readline');  
var fs = require('fs');  
var os = require('os');  
var async = require("async");
  
var worldIds = [164];
var logDays = [1];

async.eachSeries(worldIds, function(worldId, eachCb1){
	async.eachSeries(logDays, function(logDay, eachCb2){
		var fReadName = './data/' + worldId + '_' + logDay + '.log';    
		var fRead = fs.createReadStream(fReadName); 
		var writeFileName = './data/' + worldId + "_" + logDay + '_data.txt';
		ProcData(fRead, writeFileName, function(err){
			return eachCb2(err);
		})
	}, function(err){
		return eachCb1(err);
	})
}, function(err){
	console.log("finish");
})

function ProcData(fRead, writeFileName, callBack){

	var objReadline = readline.createInterface({input: fRead})

	var userData = [];

	objReadline.on("line", function(lineData){
		var index = lineData.indexOf(":");
		if(index == -1){
			return;
		}
		var time = lineData.substring(0, index);
		lineData = lineData.substring(index + 1);
		
		index = lineData.indexOf(":");
		if(index == -1){
			return;
		}
		var wuid = lineData.substring(0, index);
		lineData = lineData.substring(index + 1);
		
		index = lineData.indexOf(":");
		if(index == -1){
			return;
		}
		var logCode = lineData.substring(0, index);
		lineData = lineData.substring(index + 1);
		
		index = lineData.indexOf(":");
		if(index == -1){
			return;
		}
		var logType = lineData.substring(0, index);
		var data = lineData.substring(index + 1);
		//console.log("wuid:", wuid);
		//console.log("data:", data);
		userData.push({wuid : wuid, data : JSON.parse(data)});
	})

	objReadline.on("close", function(){
		//console.log("read finish");

		var dataMap = {};
		userData.forEach(function(elem){
			if(!dataMap[elem.wuid]){
				dataMap[elem.wuid] = [];
			}

			var found = false;
			for(var j = 0; j < elem.data.length; ++j){
				for(var i = 0; i < dataMap[elem.wuid].length; ++i){
					if(dataMap[elem.wuid][i].i == elem.data[j].i){
						dataMap[elem.wuid][i].a += elem.data[j].a;
						found = true;
					}
				}

				if(!found){
					dataMap[elem.wuid].push(elem.data[j]);
				}
			}
		})

		//console.log(JSON.stringify(dataMap, null, "	"));
		
		var str = "";
		Object.keys(dataMap).forEach(function(wuid){
			str += wuid;
			for(var i = 0; i < dataMap[wuid].length; ++i){
				str += " " + dataMap[wuid][i].i + " " + dataMap[wuid][i].a;
			}
			//console.log(str);
			str += "\n";
		})
		console.log(str);
		console.log("write to ", writeFileName);
		fs.writeFileSync(writeFileName, str, {encoding : "utf8", mode : 0644, flag : "w+"});
		return callBack(null);
	})
}