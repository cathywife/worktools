#!/bin/bash
#by liuyun 20151114
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -i 指定id 
            -H 指定主机名
	    -T ios/and/yyb
	    -y 是否本地先更新代码
            -h 打印本帮助信息;
	    eg1:sh $0 -i 1
	    eg1:sh $0 -i 1 -y yes
	    eg2:sh $0 -H nba2_redis1111 -T ios -y no
        "
    exit 1
}
id=""
HOSTNAME=""
TYPE=""
pullcode="no"
while getopts ":i:H:y:T:h" optname
do
        case "$optname" in
            "i")
                id="$OPTARG";
                ;;
            "H")
                HOSTNAME="$OPTARG";
                ;;
            "T")
                TYPE="$OPTARG";
                ;;
            "y")
                pullcode="$OPTARG";
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
#更新ope机器代码
pull_code_ope()
{
	cd $codedir && rsync -az nba_game_server/* nba_game_server.bak/
	cd nba_game_server 
	git pull
	git pull 2 >&1|grep "would be overwritten by merge"
	if [ $? -eq 0 ];then
		echo "git pull FAIL"
		exit 1
	fi
	echo `date +%s` >$codedir/nba_game_server/zouliuyun
}
#rsync代码到指定区服以及对应login节点
rsync_code_id()
{
	if [ $id -gt 10000 ];then
        	TYPE="yyb"
		loginhost="tnba2_login1 tnba2_login2"
		redishost=tnba2_redis${id}
	else
		TYPE="and"
		redishost=nba2_redis${id}
		loginhost="nba2_login01 nba2_login02 "
	fi
	echo "===rsync code to id $id ($TYPE) ==="
        codedir=/data/nba
	bzversion=`cat $codedir/nba_game_server/zouliuyun`
	#rsycn code to login&gamenode
	cd $codedir
	for host in $loginhost
	do
		ssh root@${host} "cat /data/nba/nba_game_server/zouliuyun|grep -w $bzversion" &>/dev/null
		if [ $? -ne 0 ];then
			ssh root@${host} "cd /data/nba/ && rsync -az nba_game_server/* nba_game_server.bak/"
			rsync -az nba_game_server root@${host}:/data/nba/
			rsync -az nba_game_server root@${host}:/data/8100/
			#sh /nba/server/tools/scpjs_host.sh "$host" $TYPE
			#sh /nba/server/tools/scpjs_host.sh "$host" $TYPE 8100
		fi
	done

	gamehost=`cat /nba/server/server_$id|grep -v "#"|awk '{print $1}'`
	for host in $gamehost
	do
		ssh root@${host} "cd /data/nba/ && rsync -az nba_game_server/* nba_game_server.bak/"
		rsync -az nba_game_server root@${host}:/data/nba/
		ssh root@${host} "cat /data/nba/nba_game_server/zouliuyun" |grep -w $bzversion &>/dev/null
        	if [ $? -eq 0 ];then
                	echo "rsync code ok"
        	else
                	echo "rsync code no"
        	fi
	done

#传js 
#	sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE
#	sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE 8100
	sh /nba/server/tools/scpjs_server.sh $id
}
#rsync代码到指定主机
rsync_code_host()
{
for HOST in $HOSTNAME
do
	echo "===rsync code to host $HOST==="
	bzversion=`cat $codedir/nba_game_server/zouliuyun`
	cd $codedir
	rsync -az nba_game_server ${HOST}:/data/nba/
	sh /nba/server/tools/scpjs_host.sh "$HOST" $TYPE
	ssh root@${HOST} "cat /data/nba/nba_game_server/zouliuyun" |grep -w $bzversion &>/dev/null
	if [ $? -eq 0 ];then
		echo "rsync code ok"
	else
		echo "rsync code no"
	fi
done
}
#区分ios和and代码
codedir=/data/nba

if [ "$pullcode" == "yes" ];then
	pull_code_ope
fi

if [ ! -z "$HOSTNAME" -a ! -z "$TYPE" ];then
	rsync_code_host
fi

if [ ! -z $id ];then
	rsync_code_id
fi
