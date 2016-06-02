#!/bin/bash
#wirte by zouly 20160602
#日志漏传导入
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -i 需要处理的区服id
			-H logdb所在的主机ip
			-d logdb
			-t logdb中的t字段
            -h 打印本帮助信息;
            eg1:sh $0 -i '10000 9999' -H 10.96.36.181 -d operation_log -t 60602
        "
    exit 1
}
ids=""
HOST=""
db=""
times=""
while getopts ":i:H:d:t:h" optname
do
        case "$optname" in
            "i")
                ids="$OPTARG";
                ;;
            "H")
                HOST="$OPTARG";
                ;;
            "d")
                db="$OPTARG";
                ;;  
            "t")
                times="$OPTARG";
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
if [ -z "$ids" -o -z "$HOST"  -o -z "$db"  -o -z "$times" ];then
        exit_with_help
fi

if [ $db == "operation_log" ];then
	flag=1
elif [ $db == "operation_db" ];then
	flag=2
fi
  
#漏传记录显示的日期加1
dtime=201$times
for id in `echo $ids`
do 
    echo "$id:删除不完整日志"
	echo -e "use operation_db \n db.nba_ope_log_$id.remove({t:$times})"|mongo --host $HOST
	echo "$id:检查日志是否删除"
	echo -e "use operation_db \n db.nba_ope_log_$id.find({t:$times}).count()"|mongo --host $HOST
	zcat /data/log/game$id/node*/game1.log-$dtime.gz|grep OPE|/usr/bin/python /home/statistic/tools/scripts/analyse_ope_log.py simple $id $flag &>/tmp/nba_ope_log_$id.log &  
done

sleep 600
echo "waiting for python exec..."
while true
do
        ps x|grep analyse_ope_log|grep -v grep
        if [ $? -ne 0 ];then
                break
        fi
        sleep 200
done

echo "处理logtool检测db"
echo -e "db.nba_log_record.update({f:0} , { $set : { f:2 } },false,true ); "|mongo --host $HOST
echo -e "db.nba_log_record.update({f:1} , { $set : { f:2 } },false,true ); "|mongo --host $HOST
mailaddr="liuyun.zou@dena.jp"
ssh root@nba_ope "ssh `hostname` \"tail -n 10 /tmp/nba_ope_log_$id.log\"|/bin/mailx -v -s \"NBA1 `hostname` $0 exec log\" $mailaddr "
