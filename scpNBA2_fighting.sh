#/bin/bash
##################################
#scp 静态资源#####################
#####by zouliuyun 20151102########
##################################
exit_with_help()
{
    echo "Usage: $0 [options] 
          Options:
            -t : 区域，ios/and/yyb
            -h : 帮助
	    eg:sh $0 -t ios 
	    eg:sh $0 -t "ios and yyb"
        "
    exit 1
}
while getopts ":t:f:h" optname
    do
        case "$optname" in

            "t")
                target="$OPTARG"
                ;;
            "h")
                echo "Unkown option $OPTARG"
                exit_with_help;
                ;;
        esac
    done
if [ -z $target ];then
	echo "must have 1 values"
	exit_with_help
	exit 1
fi

main()

{
	rootdir="/data/nba/"
	if [ -d /tmp/NBA2 ];then
		cd /tmp/NBA2 && rm * -rf
	else
		mkdir /tmp/NBA2
	fi
	cd /tmp/NBA2
	ssh 10.96.36.52 "cd /home/nba/ServerBuild && md5sum FightServer"
	scp -r 10.96.36.52:/home/nba/Config.txt /tmp/NBA2/
	scp -r 10.96.36.52:/home/nba/StaticData.txt /tmp/NBA2/
	scp -r 10.96.36.52:/home/nba/ServerBuild /tmp/NBA2/
	if [ $? -ne 0 ];then
		echo "scp file to local:/tmp/NBA2/ FAIL"
		exit 1
	fi
	echo "scp to fighthost........"
	for ip in  $fightip
	do
		$ssh_cmd root@${ip} "ps x|grep FightServer|grep -v grep|awk '{print \$1}'|xargs kill -9"
		sleep 1
		$ssh_cmd root@${ip} "cd $rootdir ;rm ServerBuild.bak.tgz -rf ; tar -czf ServerBuild.bak.tgz ServerBuild Config.txt StaticData.txt "
		cd /tmp/NBA2
		$scp_cmd -r *  root@${ip}:$rootdir/  &>/dev/null
		if [ $? -ne 0 ];then
			echo "$scp_cmd -r *  root@${ip}:$rootdir/ FAIL"
			exit 1
		fi
		$ssh_cmd root@${ip} "chmod -R 755 /data/nba/ServerBuild"
		$ssh_cmd root@${ip} "cd /data/nba/ServerBuild && md5sum FightServer"
		$ssh_cmd root@${ip} "/bin/bash /data/nba/ServerBuild/rs_fight.sh &>/data/nba/log/rs_fight.log 2>&1"
	done
}


case "$target" in
        "and")
                key=""
                tbjip=10.96.69.126
                fightip="10.96.69.197 10.96.69.198"
                testfighthost=10.96.36.52
;;
        "ios")
                key=""
                tbjip=10.96.69.126
                fightip="10.96.69.178 10.96.69.179"
                testfighthost=10.96.36.52
;;
        "tw")
                key="/infra/other/zhou/twnba2.pem"
                tbjip=54.92.37.194
                fightip="54.92.37.194"
                testfighthost=10.96.36.52
;;
        "yyb")
                key="/nba/pem/nba2-tencent.pem"
                tbjip=115.159.56.242
                fightip="115.159.73.143 115.159.43.232"
		#nba_web2
                testfighthost=10.96.36.52
;;
       *)
		echo "you choose target is not exsit"
		exit 1
;;
esac

if [ -z $key ];then
        ssh_cmd="ssh  -o ConnectionAttempts=60 -o ConnectTimeout=30"
        scp_cmd="scp  -o ConnectionAttempts=60 -o ConnectTimeout=30"
else
        ssh_cmd="ssh  -o ConnectionAttempts=60 -o ConnectTimeout=30 -i $key"
        scp_cmd="scp  -o ConnectionAttempts=60 -o ConnectTimeout=30 -i $key"
fi
main
