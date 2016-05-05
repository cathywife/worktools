#!/bin/bash
#by liuyun 20151118
if [ "$1" == "ios" ];then
	id=2
elif [ "$1" == "and" ];then
	id=1
else
	id=`grep "_id" /data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js |sed -n '1p'|awk -F [:,] '{print $2}' `
fi
ps aux | grep "gmTool/app.js" | grep -v grep  | awk '{print $2}' | xargs kill
nohup env MODE=0 WORLD_ID=$id PORT=8888 node /data/nba/nba_game_server/app/gmTool/app.js >> ~/gmTool.log 2>&1 &
ps aux | grep "processAddItemJob.js"|grep -v grep
if [ $? -ne 0 ];then
	nohup env MODE=0 WORLD_ID=$id PORT=8888 node /data/nba/nba_game_server/app/gmTool/bin/processAddItemJob.js >> ~/processAddItemJob.log 2>&1 &
fi
