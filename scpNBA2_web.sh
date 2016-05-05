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
            -f : 资源路径（nba2的相对路径 eg:HotfixScripts/Hotfix_3.gz or StaticData_2433_0.gz 多个文件用,分隔）
            -h : 帮助
	    eg:sh $0 -t yyb -f HotfixScripts/Hotfix_3.gz
	    eg:sh $0 -t yyb -f StaticData_2433_0.gz
	    eg:sh $0 -t \"ios and yyb\" -f HotfixScripts/Hotfix_3.gz,content
        "
    exit 1
}
while getopts ":t:f:h" optname
    do
        case "$optname" in

            "t")
                targetlist="$OPTARG"
                ;;
            "f")
                webfile="$OPTARG"
                ;;
            "h")
                echo "Unkown option $OPTARG"
                exit_with_help;
                ;;
        esac
    done
if [ -z "$targetlist" -o -z "$webfile" ];then
	echo "must have 2 values"
	exit_with_help
	exit 1
fi
main()

{
	echo "=========$target $webfile=========="
	rootdir="/www/doc/nba2"
	if [ -d /tmp/NBA2 ];then
		cd /tmp/NBA2 && rm * -rf
	else
		mkdir /tmp/NBA2
	fi
	cd /tmp/NBA2
	for file in `echo $webfile|sed 's/,/ /g'`
	do
		lastpart=`echo $file|awk -F "/" '{print $NF}'`
		nextpart=`echo $file|sed "s/$lastpart//"`
		if [ ! -d /tmp/NBA2/$nextpart ];then
			mkdir -p /tmp/NBA2/$nextpart
		fi
		ssh root@$testwebhost "[[ -d  $rootdir/$file ]]"
		if [ $? -eq 0 ];then
			
			scp -r $testwebhost:$rootdir/$file /tmp/NBA2/$nextpart/
		else
			ssh root@$testwebhost "[[ -e  $rootdir/$file ]]"
			if [ $? -ne 0 ];then
				echo "$rootdir/$file is not exsit"
				exit 1
			fi	
			scp $testwebhost:$rootdir/$file /tmp/NBA2/$nextpart/
		fi
		if [ $? -ne 0 ];then
			echo "scp $file to local FAIL,please check..."
			exit 1
		fi
	done
	for ip in `echo $webip`
	do
		cd /tmp/NBA2 && $scp_cmd -r *  root@${ip}:$rootdir/
		if [ $? -ne 0 ];then
			echo "$scp_cmd -r *  root@${ip}:$rootdir/ FAIL"
			exit 1
		fi
	done
	echo "do not forget to modify the version number and restart login node"
}

for target in $targetlist
do
case "$target" in
        "ios")
                key=""
                tbjip=10.96.69.126
                webip="10.96.69.176 10.96.69.177"
                testwebhost=10.96.36.52
;;
        "and")
                key=""
                tbjip=10.96.69.126
                webip="10.96.69.127 10.96.69.196"
                testwebhost=10.96.36.52
;;
        "yyb")
                key="/nba/pem/nba2-tencent.pem"
                tbjip=115.159.56.242
                webip="115.159.125.111 115.159.125.107"
		#nba_web2
                testwebhost=10.96.36.52
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
done
