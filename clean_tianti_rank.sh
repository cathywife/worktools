#!/bin/bash
###by zouliuyun 20151207
if [ -z "$1" -o -z "$2" ];then
        echo "清空天梯排名数据："
        echo "use:sh $0 nba_redis1000 8500"
        exit 1
fi
host=$1
port=$2
remote_cmd()
{
	cmd=$1
	ssh root@$host "$1"
}

remote_cmd "hostname"
if [ $? -ne 0 ];then
        echo "ERROR:host $host not connect"
        exit 1
fi

remote_cmd "cp /8500 /8500.bak -rf"
if [ $? -ne 0 ];then
	echo "备份8500失败"
	exit 1
fi

remote_cmd 'cd /data/nba/nba_ranking_server/ && git pull|grep "would be overwritten by merge"'
if [ $? -eq 0 ];then
	echo "git pull FAIL"
        exit 1
fi

remote_cmd "cd /data/nba/nba_ranking_server/test && node remove_data_file $host $port 100"
if [ $? -ne 0 ];then
	echo "clean rank server FAIL"
	exit 1
fi

remote_cmd "rm /8500 -rf"

remote_cmd "restart rank_8500 && netstat -tpln|grep $port"
if [ $? -eq 0 ];then
	echo "clean rank server SUCC"
else
	echo "restart rank_8500 FAIL"
	exit 1
fi
