#/bin/bash
#by liuyun 20160127
#若gamenode信息发生变更 可以使用此脚本
if [ -z "$1" ];then
	echo -e "\033[32m 多个id同时调整时 确认这些id只属于安卓 ios 应用宝中一种 \033[0m"
        echo "若gamenode信息发生变更 可以使用此脚本"
        echo "use1:sh $0 10001"
        echo "use2:sh $0 '10001 10002'"
        exit
else
        ids=$1
fi
flag="n"
read -p "请确认/nba/server/下配置已经是最新(y/n)" flag
if [ $flag == "y" ];then
        echo "开始操作..."
else
        echo "请手动调整/nba/server"
        echo "回收的gamenode 端口放在server_999999"
fi
for id in $ids
do
	file=server_$id
	if [ ! -f /nba/server/$file ];then
		echo "no such file /nba/server/$file"
		exit 1
	fi

	if [ $id -gt 10000 ];then
        	type="yyb"
		redisserver=tnba2_redis$id
		loginhost="tnba2_login1 tnba2_login2"
	else
               	type="and"
		loginhost="nba2_login01 nba2_login02 "
		redisserver=nba2_redis$id
	fi
	echo "===$id区:$type==="
	while true
	do
		cd /nba/server
		game="["
		ngame="ngame:["
		line=`cat $file|wc -l`
		for ((i=2;i<=$line;i++));
		do  
			row=`awk -v r=$i 'NR==r{print $0}' $file` 
			host=`echo $row|awk '{print $1}'`
			fport=`echo $row|awk '{print $4}'`
			fport=` expr $fport - 1 `
			nums=`echo $row|awk '{print $3}'` 
			wip=`ssh $host "curl -s ip.cn"|awk -F"：" '{print $2}' |awk '{print $1}'`
			nip=`grep -w $host /etc/hosts|awk '{print $1}'`
			for p in `seq 1 $nums`
			do
				port=$(echo ` expr $fport + $p`)
				game=$game"{h:'$wip',p:$port},"
				ngame=$ngame"{h:'$nip',p:$port},"
			done
		done 
		game=`echo $game|sed "s/,$//"`
		ngame=`echo $ngame|sed "s/,$//"`
		game=${game}"]"
		ngame=${ngame}"]"
		game=$game,$ngame
                echo $game |grep "h:'',p:860"
                if [ $? -ne 0 ];then
                        break
                fi
        done
#echo game:$game
#grep "{_id:$id," /nba/server/server_config_CN_PROD.js.$type|sed "s#\({.*,game:\).*\(,gn:'NBA2',union_chaos_fighting.*\)#\1$game\2#"
	cp /nba/server/server_config_CN_PROD.js.$type /nba/server/old/server_config_CN_PROD.js.$type.bak.$id -rf
	sed -i "/{_id:$id,/s/\({.*,game:\).*\(,gn:'NBA2',union_chaos_fighting.*\)/\1$game\2/" /nba/server/server_config_CN_PROD.js.$type
	diff /nba/server/server_config_CN_PROD.js.$type /nba/server/old/server_config_CN_PROD.js.$type.bak.$id

	#开始更新node 和 redis js
	#sh /nba/server/tools/scpjs_server.sh $id
	#sh /nba/server/tools/scpjs_host.sh "$redisserver" $type
	#perl /nba/nba.pl  -s gs  -w $id  -t web -o start -a no
done
exit
#重启login
sh /nba/server/tools/scpjs_host.sh "$loginhost" $type 8100
perl /nba/nba.pl --host $loginhost -t login -p 8100 -o restart
flag="n"
read -p "确定8100测试ok吗？(y/n)" flag
if [ $flag == "y" ];then
        echo "go on ..."
else
        exit 1
fi

#用QA手机测试
sh /nba/server/tools/scpjs_host.sh "$loginhost" $type
perl /nba/nba.pl --host $loginhost -t login -p 8300 -o restart
perl /nba/nba.pl  -s gs  -w 999999  -t web -o stop -a no
