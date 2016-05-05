#!/bin/bash
#by liuyun 20151110
if [ -z $1 ];then
        echo "use:sh $0 ID"
        exit 1
else
        file=server_$1
fi
cd /nba/server
id=$1
if [ $id -gt 10000 ];then
	type="yyb"
else
	type="and"
fi
echo "===rsync js to id $id ($type)==="
line=`cat $file|wc -l`
for ((i=2;i<=$line;i++));
do  
	row=`awk -v r=$i 'NR==r{print $0}' $file` 
        host=`echo $row|awk '{print $1}'`
	ssh root@${host} "cd /data/nba/nba_game_server/app/config_data_cn/ && cp -rf server_config_CN_PROD.js server_config_CN_PROD.js.bak"
	scp -r server_config_CN_PROD.js.$type root@${host}:/data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js
	if [ $? -ne 0 ];then
		echo "scp js to ${host} FAIL"
		exit 1
	fi
	cp server_config_CN_PROD.js.$type /data/nba/nba_game_server/app/config_data_cn/ -rf
done 
