#!/bin/bash
#by zouliuyun 2015/11/23
#备份redis上rankserver数据
if [ ! -d /data/8500 ];then
        mkdir /data/8500
fi

for redishost in `grep "{_id:" /nba/server/server_config_CN_PROD.js.yyb /nba/server/server_config_CN_PROD.js.and |awk -F "rank:{h:'" '{print $NF}'|awk -F "'" '{print $1}'`
do
        scp -r ${redishost}:/8500 /data/8500/${redishost}_8500
        if [ $? -eq 0 ];then
                echo "scp -r ${redishost}:/8500 /data/8500/${redishost}_8500 SUCC"
        else
                echo "scp -r ${redishost}:/8500 /data/8500/${redishost}_8500 FAIL"
        fi
	
done
