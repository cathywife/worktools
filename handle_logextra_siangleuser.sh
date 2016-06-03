#!/bin/bash
#wirte by zouly 20160602
#日志漏传导入
stime=`date +%s`
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -i 需要处理的区服id
			-u wid
			-d logdb
            -h 打印本帮助信息;
            eg1:sh $0 -i 19999 -u 2434354634 -d operation_log
        "
    exit 1
}
id=""
wid=""
db=""
while getopts ":i:u:d:h" optname
do
        case "$optname" in
            "i")
                id="$OPTARG";
                ;;
            "u")
                wid="$OPTARG";
                ;;
            "d")
                db="$OPTARG";
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
if [ -z "$id" -o -z "$wid"  -o -z "$db"   ];then
        exit_with_help
fi

if [ $db == "operation_log" ];then
	flag=1
elif [ $db == "operation_db" ];then
	flag=2
fi
#获取mongodb中导入的最早的日志日期和本地log目录下最早的日期和当前日期间想个的天数  
function getduringday()
{
	startdate=`cd /data/log/game$id && ls node*/*gz|awk -F [-] '{print $2}'|sort |head -n1|awk -F "." '{print $1}'`
	enddate=201`echo -e "db.nba_ope_log_$id.find({f2:$wid},{t:1}).sort({t:1}).limit(1)"|mongo --quiet $db|awk '{print $(NF-1)}'`
	if [ $startdate -gt $enddate ];then
		echo "get date err"
		exit
	fi
	diff=1
	while true
	do
		tmpdate=`date -d "-${diff}days" +%Y%m%d`
		if [ "$startdate" == "$tmpdate" ];then
			ediff=$diff
			break;
		fi
        if [ "$enddate" == "$tmpdate" ];then
            sdiff=$diff
        fi
		diff=$(($diff+1))  
	done
	
}
getduringday
echo $startdate $enddate $sdiff $ediff
tmp_fifofile="/tmp/$$.fifo"
mkfifo $tmp_fifofile      # 新建一个fifo类型的文件
exec 6<>$tmp_fifofile      # 将fd6指向fifo类型
rm $tmp_fifofile

thread=15 # 此处定义线程数
for ((i=0;i<$thread;i++));do 
echo
done >&6 # 事实上就是在fd6中放置了$thread个回车符

sdiff=$(($siff-1))
for diff in `seq $sdiff $ediff`
do
	read -u6
{	 
	# 一个read -u6命令执行一次，就从fd6中减去一个回车符，然后向下执行，
	# fd6中没有回车符的时候，就停在这了，从而实现了线程数量控制
	dtime=`date -d "-${diff}days" +%Y%m%d` 
	echo $dtime
	zcat /data/log/game$id/node*/game1.log-$dtime.gz|grep OPE|grep -w $wid|/usr/bin/python /home/statistic/tools/scripts/analyse_ope_log.py simple $id $flag 
	echo >&6 # 当进程结束以后，再向fd6中加上一个回车符，即补上了read -u6减去的那个
}&

done

wait # 等待所有的后台子进程结束
exec 6>&- # 关闭df6
etime=`date +%s`
mailaddr="liuyun.zou@dena.jp"
ssh root@nba_ope "ssh `hostname` \"echo $wid $startdate $stime $etime \"|/bin/mailx -v -s \"NBA1 `hostname` $0 exec log\" $mailaddr "
