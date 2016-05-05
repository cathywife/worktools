#/bin/bash
#by liuyun 20151125
#若gamenode信息发生变更 可以使用此脚本
if [ -z "$1" ];then
	echo "use:sh $0 10001"
	exit 1
else
	file=server_$1
	id=$1
fi
if [ ! -f /nba/server/$file ];then
	echo "no such file /nba/server/$file"
	exit 1
fi
read -p "请确认/nba/server/$file配置已经是最新(y/n)" flag
if [ $flag == "y" ];then
	echo "开始操作..."
else
	echo "请手动调整/nba/server/$file"
	echo "回收的gamenode 端口放在server_999999"
fi

if [ $id -gt 10000 ];then
        type="yyb"
	redisserver=tnba2_redis$id
	trueid=` expr $id - 10000 `
	title="{_id:${id},n:'应用宝公测${trueid}服'"
	loginhost="tnba2_login1 tnba2_login2"
else
        type="and"
	trueid=` expr $id - 2000 `
	title="{_id:${id},n:'联合${trueid}服'"
	loginhost="nba2_login01 nba2_login02 "
	redisserver=nba2_redis$id
fi
echo "===$id区:$type==="
cd /nba/server
game="["
line=`cat $file|wc -l`
for ((i=2;i<=$line;i++));
do  
	row=`awk -v r=$i 'NR==r{print $0}' $file` 
	host=`echo $row|awk '{print $1}'`
	fport=`echo $row|awk '{print $4}'`
	fport=` expr $fport - 1 `
	nums=`echo $row|awk '{print $3}'` 
	wip=`ssh $host "curl -s ip.cn"|awk -F"：" '{print $2}' |awk '{print $1}'`
	for p in `seq 1 $nums`
	do
		port=$(echo ` expr $fport + $p`)
		game=$game"{h:'$wip',p:$port},"
	done
done 
game=`echo $game|sed "s/,$//"`
game=${game}"]"
echo game:$game
#grep "{_id:$id," /nba/server/server_config_CN_PROD.js.$type|sed "s#\({.*,game:\).*\(,gn:'NBA2',union_chaos_fighting.*\)#\1$game\2#"
cp /nba/server/server_config_CN_PROD.js.$type /nba/server/server_config_CN_PROD.js.$type.bak
sed -i "/{_id:$id,/s#\({.*,game:\).*\(,gn:'NBA2',union_chaos_fighting.*\)#\1$game\2#" /nba/server/server_config_CN_PROD.js.$type
diff /nba/server/server_config_CN_PROD.js.$type /nba/server/server_config_CN_PROD.js.$type.bak


#开始更新js
sh /nba/server/tools/scpjs_host.sh "$loginhost" $type
sh /nba/server/tools/scpjs_host.sh "$loginhost" $type 8100
sh /nba/server/tools/scpjs_server.sh $id
sh /nba/server/tools/scpjs_host.sh "$redisserver" $type

#重启login
#perl /nba/nba.pl --host $loginhost -t login -p 8100 -o restart
#用QA手机测试
#perl /nba/nba.pl --host $loginhost -t login -p 8300 -o restart
#perl /nba/nba.pl  -s gs  -w 999999  -t web -o stop -a no
#新增端口才使用 单纯减少不需要
#perl /nba/nba.pl  -s gs  -w $id  -t web -o restart -a no
#通知运营测试

