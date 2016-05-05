#!/bin/bash
#by liuyun 20151114
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -v 静态资源版本号码 
            -H 热修版本号
	    -T ios/and/yyb
            -h 打印本帮助信息;
	    eg1:sh $0 -v 3456 -T ios
	    eg2:sh $0 -H 7 -T yyb
        "
    exit 1
}
version=""
FixVersion=""
TYPE=""
while getopts ":v:H:T:h" optname
do
        case "$optname" in
            "v")
                version="$OPTARG";
                ;;
            "H")
                FixVersion="$OPTARG";
                ;;
            "T")
                TYPE="$OPTARG";
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
cd /nba/server
if [ ! -f server_config_CN_PROD.js.${TYPE} ];then
	echo "No such file :server_config_CN_PROD.js.${TYPE} "
	exit_with_help
fi
cp server_config_CN_PROD.js.${TYPE} /nba/server/logs/server_config_CN_PROD.js.${TYPE}.`date +%s` -rf
oldnum=`grep "_id:" server_config_CN_PROD.js.${TYPE}|wc -l`
if [ ! -z $version ];then
	oldversion=`grep "_id:" server_config_CN_PROD.js.${TYPE}|head -n 1|awk -F ",version:" '{print $NF}'|awk -F "," '{print $1}'|sed s/\'//g`
	sed -i "s/${oldversion}/0.${version}.0/g" server_config_CN_PROD.js.${TYPE}
	newnum=`grep "0.${version}.0" server_config_CN_PROD.js.${TYPE}|wc -l`
	if [ $oldnum -eq $newnum ];then
		echo "update server_config_CN_PROD.js.${TYPE} version:$version SUCC"
	else
		echo "update server_config_CN_PROD.js.${TYPE} version:$version FAIL"
	fi
fi
if [ ! -z $FixVersion ];then
        oldFixVersion=`grep "_id:" server_config_CN_PROD.js.${TYPE}|head -n 1|awk -F "curHotFixVersion:" '{print $NF}'|awk -F "," '{print $1}'`
        sed -i s/curHotFixVersion:${oldFixVersion}/curHotFixVersion:${FixVersion}/g server_config_CN_PROD.js.${TYPE}
        newnum=`grep "curHotFixVersion:${FixVersion}" server_config_CN_PROD.js.${TYPE}|wc -l`
        if [ $oldnum -eq $newnum ];then
                echo "update server_config_CN_PROD.js.${TYPE} HotFixVersion:$FixVersion SUCC"
        else
                echo "update server_config_CN_PROD.js.${TYPE} HotFixVersion:$FixVersion FAIL"
        fi
fi
