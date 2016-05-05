#!/bin/bash
#by liuyun 20151114
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -v 静态资源版本号码
            -H 热修版本号
	    -G 是否单独更新gm
            -t ios/and/yyb
            -h 打印本帮助信息;
            eg1:sh $0 -v 3456 -t iod
            eg2:sh $0 -H 7 -t yyb
            eg3:sh $0 -H 7 -v 3456 -t yyb
        "
    exit 1
}
version=""
FixVersion=""
TYPE=""
gm="false"
while getopts ":v:GH:t:h" optname
do
        case "$optname" in
            "v")
                version="$OPTARG";
                ;;
            "H")
                FixVersion="$OPTARG";
                ;;
            "t")
                TYPE="$OPTARG";
                ;;
            "G")
                gm="true";
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

case "$TYPE" in
        "ios")
		loginhost=" nba2_login01 nba2_login02"
		gmhost="nba2_gmtool_ios nba2_gmtool_and"
		cdndomain="download-nba2-ios.mobage.cn"
;;
        "and")
		loginhost="nba2_login01 nba2_login02 "
		gmhost="nba2_gmtool_ios nba2_gmtool_and"
		cdndomain="download-nba2.mobage.cn"
;;
        "yyb")
		loginhost="tnba2_login1 tnba2_login2"
		gmhost="tnba2_gmtool"
		cdndomain="download-nba2-yyb.mobage.cn"
;;
       *)
                echo "you choose TYPE is not exsit"
                exit 1
;;
esac
#检测cdn url 是否正常访问
check_url()
{
	DOWNLOADURL=$1
	wget --spider $DOWNLOADURL 2>&1 |grep "Remote file exists" 
	if [ $? -ne 0 ];then
		echo "download $DOWNLOADURL FAIL"
		if [ "$TYPE" <> "yyb" ];then
			exit 1
		fi
	fi
}

gmupdate()
{
        #单独更新gmtool
        sh /nba/server/tools/rsync_code.sh -H "$gmhost" -T $TYPE -y yes
	if [ $TYPE == "and" ];then
		ssh nba2_gmtool_ios "sh /nba/reload_gm.sh ios"
		ssh nba2_gmtool_and "sh /nba/reload_gm.sh and"
	else
		lsgame -r 'sh /nba/reload_gm.sh ' 'gmtool'
	fi
	exit 0
}

restart_login()
{
        if [ ! -z $1 ];then
                action="$1"
        else
                action="restart"
        fi
        echo "重启login..."
        perl /nba/nba.pl --host $loginhost -t login -p 8100 -o $action
        perl /nba/nba.pl --host $loginhost -t login -p 8300 -o $action
}

restart_node()
{
	if [ ! -z $1 ];then
		action="$1"
	else
		action="restart"
	fi
        echo "重启gamenode..."
        for i in `awk -F ',' '{print $1}' /nba/server/server_config_CN_PROD.js.$TYPE|awk -F"_id:" '$2 != ""{print $2}'|sort`
        do
                perl /nba/nba.pl  -s gs  -w $i -t web -o $action -a no
	done
}

rsync_code()
{
        echo "拉代码..."
        sh /nba/server/tools/rsync_code.sh -H "$gmhost" -T $TYPE -y yes
        for i in `awk -F ',' '{print $1}' /nba/server/server_config_CN_PROD.js.$TYPE|awk -F"_id:" '$2 != ""{print $2}'|sort`
        do
                sh /nba/server/tools/rsync_code.sh -i $i -y no
        done
        sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE 
        sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE 8100
}

update_static()
{
        if [ "$TYPE" != "yyb" ];then
		sh /nba/server/tools/scpNBA2_web.sh -t "$TYPE yyb" -f StaticData_${version}_0.gz
        fi
	url="http://${cdndomain}/nba2/StaticData_${version}_0.gz"
	check_url "$url"
	sh /nba/server/tools/update_js.sh -v $version -T $TYPE
	rsync_code
	restart_login
	restart_node
}

update_FixVersion()
{
        if [ "$TYPE" != "yyb" ];then
		sh /nba/server/tools/scpNBA2_web.sh -t "$TYPE yyb" -f HotfixScripts/Hotfix_${FixVersion}.gz
        fi
        url="http://${cdndomain}/nba2/HotfixScripts/Hotfix_${FixVersion}.gz"
        check_url "$url"
	sh /nba/server/tools/update_js.sh -H $FixVersion -T $TYPE
	sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE
	sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE 8100
	restart_login
}

update_FixVersion_static()
{
        if [ "$TYPE" != "yyb" ];then
		sh /nba/server/tools/scpNBA2_web.sh -t "$TYPE yyb" -f StaticData_${version}_0.gz
        	sh /nba/server/tools/scpNBA2_web.sh -t "$TYPE yyb" -f HotfixScripts/Hotfix_${FixVersion}.gz
	fi
        url="http://${cdndomain}/nba2/StaticData_${version}_0.gz"
        check_url "$url"
        url="http://${cdndomain}/nba2/HotfixScripts/Hotfix_${FixVersion}.gz"
        check_url "$url"
        sh /nba/server/tools/update_js.sh -v $version -T $TYPE
	sh /nba/server/tools/update_js.sh -H $FixVersion -T $TYPE
	rsync_code
	restart_login
	restart_node
}

pullcode()
{
	sh /nba/server/tools/rsync_code.sh -H "$gmhost" -T $TYPE -y yes

        for i in `awk -F ',' '{print $1}' /nba/server/server_config_CN_PROD.js.$TYPE|awk -F"_id:" '$2 != ""{print $2}'|sort`
        do
                sh /nba/server/tools/rsync_code.sh -i $i -y no
        done
	restart_node
}
echo "========================更新$TYPE=============================="
if [ "$gm" == "true" ];then
        gmupdate
fi
if [ ! -z "$version" -a ! -z "$FixVersion" ];then
        update_FixVersion_static
	gmupdate
elif [ ! -z "$version" ];then
        update_static
	gmupdate
elif [ ! -z "$FixVersion" ];then
        update_FixVersion
elif [ ! -z "$TYPE" ];then
        pullcode
	gmupdate
else
        exit_with_help
fi
