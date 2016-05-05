#/bin/bash
##################################
#scp 静态资源#####################
#####by zouliuyun 20151102########
##################################
exit_with_help()
{
    echo "Usage: $0 [options] 
          Options:
            -g : 区域，NBA2_ios/NBA2_and/NBA2_yyb/NBA1_cn/NBA1_cn2015
	    -t : 重启类型gamenode/login
            -o : 操作类型 restart/stop/start	    
            -a : 是否全重启 yes/no 	    
            -id : 区服id 	    
            -p : loginport  
            -h : 帮助
	    eg:sh $0 -g NBA2_yyb -t gamenode -o restart -i 3 -a no
	    eg:sh $0 -g NBA2_yyb -p 8100  -t login -o stop
        "
    exit 1
}
while getopts ":g:t:o:a:i:p:h" optname
    do
        case "$optname" in

            "g")
                target="$OPTARG"
                ;;
            "t")
                type="$OPTARG"
                ;;
            "o")
                oprate="$OPTARG"
                ;;
            "a")
                action="$OPTARG"
                ;;
            "i")
                id="$OPTARG"
                ;;
            "p")
                port="$OPTARG"
                ;;
            "h")
                echo "Unkown option $OPTARG"
                exit_with_help;
                ;;
        esac
    done

main()

{
   	if [ $type == "gamenode" ];then
		if [ $target == "NBA2_ios" -a $action == "yes" ];then
		        for i in `awk -F ',' '{print $1}' /nba/server/server_config_CN_PROD.js.ios|awk -F"_id:" '$2 != ""{print $2}'|sort`
        		do
                		perl /nba/nba.pl  -s gs  -w $i -t web -o $oprate -a no
        		done
			exit 0
		fi
                if [ $target == "NBA2_and" -a $action == "yes" ];then
                        for i in `awk -F ',' '{print $1}' /nba/server/server_config_CN_PROD.js.and|awk -F"_id:" '$2 != ""{print $2}'|sort`
                        do
                               	perl /nba/nba.pl  -s gs  -w $i -t web -o $oprate -a no
                        done
                        exit 0
                fi
		

   		cmd="perl /nba/nba.pl  -s gs  -w $id -t web -o $oprate -a $action"
	elif [ $type == "login" ];then
   		cmd="perl /nba/nba.pl  --host $loginhost  -t login -p $port -o $oprate"
	else
		exit_with_help
	fi
	echo $cmd
	$ssh_cmd $tbjip "$cmd"
}

case "$target" in
        "NBA2_ios")
                key=""
                tbjip=10.96.69.126
		loginhost="nba2_login01 nba2_login02 "
;;
        "NBA2_and")
                key=""
                tbjip=10.96.69.126
		loginhost="nba2_login01 nba2_login02 "
;;
        "NBA2_yyb")
                key="/nba/pem/nba2-tencent.pem"
                tbjip=115.159.56.242
		loginhost="tnba2_login1 tnba2_login2"
;;
        "NBA1_cn")
                key="/nba/pem/nba_ope.pem"
                tbjip=10.96.36.70
		loginhost="nba_login1 nba_login2 nba_login3"
;;           
        "NBA1_cn2015")
                key="/nba/pem/nba2015_ope.pem"
                tbjip=10.96.46.200
                loginhost="nba2015_login1 nba2015_login2"
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
