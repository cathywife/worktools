#!/bin/bash
#by liuyun 20151207
#merge执行之后的步骤
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

ii=` expr $id % 2 `
if [ $tid -gt 10000 ];then
        TYPE="yyb"
        loginhost="tnba2_login1 tnba2_login2"
        gmhost="tnba2_gmtool"
        tredis=tnba2_redis$tid
else
        tredis=nba2_redis$tid
        if [ $ii -eq 1 ];then
                TYPE="and"
                loginhost="nba2_login01 nba2_login02 "
                gmhost="nba2_gmtool_and"
        else
                TYPE="ios"
                loginhost="nba2_login01 nba2_login02 "
                gmhost="nba2_gmtool_ios"
        fi
fi

echo "请清空天梯排名数据 http://10.96.69.126:4440/project/NBA1_CN/jobs"

#开放正式入口
ssh root@$gmhost "sh /nba/reload_gm.sh"
for i in $loginhost
do
        sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE
        sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE 8100
done
perl /nba/nba.pl --host $loginhost -t login -p 8100 -o restart
perl /nba/nba.pl --host $loginhost -t login -p 8300 -o restart
for id in $sid
do
	cd /nba/server && mv  server_$id oldserver/ -f
	crontab -l |grep " $id "
done
echo "请开启监控 删除ope机器定时任务"

crontab -l|grep check_ports|grep -v grep
