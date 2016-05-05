#!/bin/bash
#by zouly 20151214
if [ -z "$1" ];then
        echo "检测server配置中端口连接情况"
        echo "use:sh $0 10001 "
        exit 1
else
        file=server_$1
        id=$1
fi

if [ ! -f /nba/server/$file ];then
        echo "no such file /nba/server/$file"
        exit 1
fi

rpm -q nc >/dev/null 2>&1
if [ $? != 0 ];then
yum -y install nc >/dev/null 2>&1
fi

cd /nba/server
line=`cat $file|wc -l`
for ((i=2;i<=$line;i++));
do
        row=`awk -v r=$i 'NR==r{print $0}' $file`
        host=`echo $row|awk '{print $1}'`
        fport=`echo $row|awk '{print $4}'`
        fport=` expr $fport - 1 `
        nums=`echo $row|awk '{print $3}'`
        for p in `seq 1 $nums`
        do
                port=$(echo ` expr $fport + $p`)
		nc -z $host $port |grep -w "succeeded"
		if [ $? -ne 0 ];then
			echo "Connection to $host $port port [tcp/*] failed!"	
		fi
        done
done

