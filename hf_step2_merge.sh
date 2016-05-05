#!/bin/bash
#by liuyun 20151207
#执行合并脚本
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -s 被合区id
            -t 目标区id
            -h 打印本帮助信息;
            eg1:sh $0 -s 10000 -t 9999
        "
    exit 1
}
sid=""
tid=""
while getopts ":s:t:h" optname
do
        case "$optname" in
            "s")
                sid="$OPTARG";
                ;;
            "t")
                tid="$OPTARG";
                ;;
            "?")
                echo "Unkown option $OPTARG"
                exit_with_help;
                ;;
            ":")
                echo "No arugument value for option $OPTARG"
                exit_with_help;
                ;;
            "h")
                exit_with_help;
                ;;
        esac
done
####
file1=/data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js

grep "_id:${tid}" $file1
flag="n"
read -p "请确认备份login_db/game_db是否开始执行(y/n)" flag
if [ $flag == "y" ];then
        echo "go on ..."
else
        exit 1
fi

cd /data/nba/nba_game_server
git pull|grep "would be overwritten by merge"
if [ $? -eq 0 ];then
	echo "git pull FAIL"
        exit 1
fi

echo "exec env MODE=0 FROM_SERVER=$sid TO_SERVER=$tid node bin/scripts/mergeServerr/NBA2MergeServer.js" 
if [ ! -d /data/hequ ];then
	mkdir /data/hequ
fi
nohup env MODE=0 FROM_SERVER=$sid TO_SERVER=$tid node bin/scripts/mergeServer/NBA2MergeServer.js  > /data/hequ/${sid}-${tid}-hequ.txt  2>&1 &
echo "logname:/data/hequ/${sid}-${tid}-hequ.txt"
echo "waiting for NBA2MergeServer exec..."
while true
do
	ps x|grep NBA2MergeServer|grep -v grep &>/dev/null
	if [ $? -ne 0 ];then
		break
	fi
	sleep 5
done
mongohost=`grep "_id:${tid}" $file1 |awk -F "login_db" '{print $NF}'|awk -F "'" '{print $2}'`
grep -A15 "Execute this SQL on login_db" /data/hequ/${sid}-${tid}-hequ.txt|grep -B15 "Restart game_redis"|grep -Ewv "Restart|Manually"|sed '1 iuse login_db' >/data/hequ/login_db_${sid}-${tid}
cat /data/hequ/login_db_${sid}-${tid}
flag="n"
read -p "请确定是否继续对${mongohost}:login_db 执行上面语句(y/n)" flag
if [ $flag == "y" ];then
	echo "go on ..."
else
	exit 1
fi
scp /data/hequ/login_db_${sid}-${tid} root@$mongohost:/tmp
if [ $? -eq 0 ];then
	ssh root@$mongohost "cat /tmp/login_db_${sid}-${tid}|mongo"
	if [ $? -ne 0 ];then
		echo "exec update mongo uid FAIL"
		exit 1
	fi
	echo "偏转后${sid}区uid数:"
	ssh root@$mongohost "echo -e \"use login_db\ndb.common_user.find({'u.w': ${sid}}).count();\"|mongo"
	echo "偏转后${tid}区uid数:"
	ssh root@$mongohost "echo -e \"use login_db\ndb.common_user.find({'u.w': ${tid}}).count();\"|mongo"
else
	echo "scp file FAIL"
fi

