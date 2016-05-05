#!/bin/bash
#by liuyun 20151207
#停服 执行退出俱乐部脚本
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -s 被合区id
            -t 目标区id 多个用空格分开
            -h 打印本帮助信息;
            eg1:sh $0 -s '10000 9999' -t 9998
        "
    exit 1
}
sid=""
tid=""
while getopts ":s:t:h" optname
do
        case "$optname" in
            "s")
                sid="$OPTARG";
                ;;
            "t")
                tid="$OPTARG";
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
if [ -z "$sid" -o -z "$tid" ];then
	exit_with_help
fi
flag="n"
read -p "请确认监控是否关闭(y/n)" flag
if [ $flag == "y" ];then
        echo "go on ..."
else
        exit 1
fi
if [ $tid -gt 10000 ];then
        type="yyb"
        tredis=tnba2_redis$tid
else
        tredis=nba2_redis$tid
        type="and"
fi
cp /nba/server/server_config_CN_PROD.js.$type /data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js -rf

echo "stop node..."
for id in $sid $tid
do
        perl /nba/nba.pl -s gs -w $id -t web -o stop -a no
done
