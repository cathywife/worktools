//构造mongolong类型变成字符串
var mongo = require("mongodb");

var userData = require("./tianti_data");

var allData = [];
userData.forEach(function(elem){
	allData = allData.concat(elem);
})

allData.forEach(function(elem){
	if(typeof elem.u === 'object'){
		var uid = new mongo.Long(elem.u.low_, elem.u.high_);
		console.log(uid.toString());
	}else{
		console.log(elem.u);
	}
})