#/bin/bash
#by liuyun 20151110
if [ -z "$1" -o -z "$2" ];then
	echo "use:sh $0 \"nba2_login01 nba2_login02\" and"
	echo "use:sh $0 \"\" ios 8100" 
	exit 1
fi
hosts=$1
type=$2
qa=$3
js_cn()
{
	echo "===rsync js to $host $qa==="
	cd /nba/server
	ssh root@${host} "cd /data/nba/nba_game_server/app/config_data_cn/ && cp -rf server_config_CN_PROD.js server_config_CN_PROD.js.bak"
	scp -r server_config_CN_PROD.js.$type root@${host}:/data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js
        if [ $? -ne 0 ];then
                echo "scp js to host ${host} FAIL"
                exit 1
        fi
	cp server_config_CN_PROD.js.$type /data/nba/nba_game_server/app/config_data_cn/ -rf
}

js_cn_8100()
{
	echo "===rsync js to $host $qa==="
	cd /nba/server
	ssh root@${host} "cd /data/8100/nba_game_server/app/config_data_cn/ && cp -rf server_config_CN_PROD.js server_config_CN_PROD.js.bak"
	scp -r server_config_CN_PROD.js.$type root@${host}:/data/8100/nba_game_server/app/config_data_cn/server_config_CN_PROD.js
        if [ $? -ne 0 ];then
                echo "scp js to host ${host} FAIL"
                exit 1
        fi 
}

if [ "$qa" == "8100" ];then
	for host in $hosts
	do
		js_cn_8100
	done
else
        for host in $hosts
        do
                js_cn
        done
fi
