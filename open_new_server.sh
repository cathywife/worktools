#!/bin/bash
#by liuyun 20151114
id=$1
if [ -z $id ];then
        echo "use:$0 3"
        exit 1
fi
####
echo "===$id区==="
#手动 修改js 设置v:1 修改redis主机名 start时间 提前14天
start=`date +%Y,%m,%d -d '-14days'`
ii=` expr $id % 2 `
if [ $id -gt 10000 ];then
        type="yyb"
	loginhost="tnba2_login1 tnba2_login2"
	redishost=tnba2_redis${id}
else
	redishost=nba2_redis${id}
       	type="and"
	loginhost="nba2_login01 nba2_login02 "
fi
grep "{_id:$id," /nba/server/server_config_CN_PROD.js.$type |grep "$start" &>/dev/null
if [ $? -eq 0 ];then
	grep "{_id:$id," /nba/server/server_config_CN_PROD.js.$type|grep "v:1" &>/dev/null
	if [ $? -eq 0 ];then
        	echo "ERROR:$type id:$id have open,please check..."
        	exit 1
	fi
else
	echo "ERROR:$type id:$id not deploy or start is error,please check..."
	exit 1
fi
#修改js配置
cp /nba/server/server_config_CN_PROD.js.$type /nba/server/server_config_CN_PROD.js.$type.bak
sed -i "/{_id:$id,/s/v:0/v:1/" /nba/server/server_config_CN_PROD.js.$type
preid=$(($id-1))
sed -i "/{_id:$preid,/s/w:1/w:-1/;/{_id:$preid,/s/00ff00/ff0000/;/{_id:$preid,/s/新/满/"  /nba/server/server_config_CN_PROD.js.$type
diff /nba/server/server_config_CN_PROD.js.$type /nba/server/server_config_CN_PROD.js.$type.bak

#部署redis 实际在部署新区的时候已经做过了 重复执行也不会有问题
cd /nba/server
scp /nba/server/tools/deploy_redis.sh $redishost:/data/
ssh $redishost "sh /data/deploy_redis.sh ${id} open"

#传js 
sh /nba/server/tools/scpjs_host.sh "$loginhost" $type
sh /nba/server/tools/scpjs_host.sh "$loginhost" $type 8100
sh /nba/server/tools/scpjs_server.sh $id
#重启login
perl /nba/nba.pl --host $loginhost -t login -p 8300 -o restart
perl /nba/nba.pl --host $loginhost -t login -p 8100 -o restart

#重启gamenode
perl /nba/nba.pl  -s gs  -w $id -t web -o restart -a no
mail="liuyun.zou@dena.com,ertao.xu@dena.com"
echo "open $type id:$id区 OK" |mailx -v -s "[NBA2]新开区通知" $mail
#/bin/bash /nba/server/td-agent.sh $id
