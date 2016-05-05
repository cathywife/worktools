#!/bin/bash
id=$1
if [ -z $id ];then
	echo "use:$0 3"
	echo "use:$0 3 open"
	exit 1
fi
if [ $id -gt 10000 ];then
        redishost=tnba2_redis${id}
else
        redishost=nba2_redis${id}
fi
echo "===$id区`hostname`==="
echo "create fighting_db index"
if [ ! -e /etc/mongo.conf ];then
	redishost=`grep "_redis" /etc/hosts|sort -k2|grep -v cbt3 |awk '{print $2}'|head -n 1`
	scp $redishost:/etc/mongo.conf /etc/mongo.conf
fi
/usr/bin/mongod -f /etc/mongo.conf
netstat -tpln|grep mongo
if [ $? -ne 0 ];then
	echo "ERROR:mongod is stop "
	exit 1
fi
scp 10.96.69.126:/nba/server/fighting_db.index  /tmp/fighting_db.index
cat /tmp/fighting_db.index |mongo
echo "check crontab redis ..."
/etc/init.d/crond restart 
/etc/init.d/crond status|grep running
if [ $? -ne 0 ];then
        echo "crontab error"
fi

echo "start redis server..."
for server in  rank_8500 tianti_8700
do
	start $server
	restart $server
done
sleep 2
num=`netstat -tpln|grep -E '8500|8700'|wc -l`
if [ $num -ne 2 ];then
	echo "ERROR:redis server not ok,please check..."
fi

ps x|grep redis-server|grep -v grep|awk '{print $1}'|xargs kill -9 
start redis-server
netstat -tpln|grep redis-server
if [ $? -ne 0 ];then
	echo "ERROR:redis error"
fi

####对外当天设置
if [ "$2" == "open" ];then
        crontab -l >/tmp/crontab.bak
        crontab -l >/tmp/.crontab
        sed -i /PVP_tianti_freeze_ranking.js/d /tmp/.crontab
        echo "30 0 * * * nohup /usr/local/bin/node /data/nba/nba_game_server/bin/daemon/PVP_tianti_freeze_ranking.js $id 0 DEBUG $redishost 8500 >> /data/nba/log/PVP_tianti_freeze_ranking.\`date +\%Y\%m\%d\`.log &" >>/tmp/.crontab
        echo "0 1 * * 1 nohup /usr/local/bin/node /data/nba/nba_game_server/bin/daemon/PVP_threepoint_dist_reward.js $id 0 DEBUG >> /data/nba/log/PVP_threepoint_dist_reward.\`date +\%Y\%m\%d\`.log &" >>/tmp/.crontab
        crontab /tmp/.crontab
        crontab -l|grep PVP_tianti_freeze_ranking.js
fi
