#!/bin/bash
#by liuyun 20151114
#server配置还需手动制作 部服总控脚本

if [ -z "$1" -o -z "$2" ];then
        echo "部署新区"
        echo "use:$0 3 '2015-11-17'"
        exit 1
fi
id=$1
openday=$2
file=server_$1

if [ ! -f /nba/server/$file ];then
        echo "no such file /nba/server/$file"
        exit 1
fi

###确认server中的端口都未使用
sh /nba/server/tools/check_port_server.sh $id |grep -w "succeeded"
if [ $? -eq 0 ];then
        echo "请确认/nba/server/server_$id 是否配置正常"
        exit 1
fi

####
echo "===$id区==="
if [ $id -gt 10000 ];then
        type="yyb"
	loginhost="tnba2_login1 tnba2_login2"
	redishost=tnba2_redis${id}
	gmhost="tnba2_gmtool"
else
	redishost=nba2_redis${id}
       	type="and"
	loginhost="nba2_login01 nba2_login02 "
	gmhost="nba2_gmtool_and nba2_gmtool_ios"
fi

#部署redis
cd /nba/server
scp /nba/server/tools/deploy_redis.sh $redishost:/data/
if [ $? -ne 0 ];then
	echo "scp deploy_redis.sh FAIL"
	exit 1
fi
ssh $redishost "sh /data/deploy_redis.sh ${id}"

###修改js
#sh /nba/server/tools/general_js.sh $id "$openday" w

#检查js
grep "{_id:$id," /nba/server/server_config_CN_PROD.js.$type|grep ",v:1,"
if [ $? -eq 0 ];then
	echo "ERROR:$type id:$id have deploy,please check..."
	exit 1
fi
grep "{_id:$id," /nba/server/server_config_CN_PROD.js.$type
if [ $? -ne 0 ];then
	echo "pleae exec general_js.sh"
	exit 1
fi

#rsync code to node
gamehost=`cat /nba/server/server_$id|grep -v "#"|awk '{print $1}'`
for host in $gamehost
do
	sh /nba/server/tools/rsync_code.sh -H $host -T $type -y no
done

#传js 
sh /nba/server/tools/scpjs_host.sh "$loginhost" $type
sh /nba/server/tools/scpjs_host.sh "$loginhost" $type 8100
sh /nba/server/tools/scpjs_host.sh "$gmhost" $type

#重启login
perl /nba/nba.pl --host $loginhost -t login -p 8100 -o restart

#重启gamenode
perl /nba/nba.pl  -s gs  -w $id -t web -o start -a no
sleep 5
sh /nba/server/tools/check_port_server.sh $id|grep "failed"
if [ $? -eq 0 ];then
        echo "$id 区启动失败"
        exit 1
fi

#重启gmtool
lsgame -r 'sh /nba/reload_gm.sh' 'gmtoo'

echo "通知联运新区部署ok"

