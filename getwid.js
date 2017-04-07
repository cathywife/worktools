var mongo = require("mongodb");
var MongoClient = require('mongodb').MongoClient
MongoClient.connect('mongodb://nba_db1:27017/game_db', function(err, db) {
	collection=db.collection('game_user');
	collection.find({w:4,'ii':{"$elemMatch":{'i':30002,'a':{$gt:500000}}}},{_id:1}).toArray(function(err,results){
		results.forEach(function(elem){
		if(typeof elem._id === 'object'){
		var uid = new mongo.Long(elem._id.low_, elem._id.high_);
		console.log(uid.toString());
		}
		else
		{console.log(elem._id)}
		})
		process.exit(1)
	})
})
