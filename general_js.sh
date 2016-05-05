#/bin/bash
#by liuyun 20151110
if [ -z "$1" -o -z "$2" ];then
	echo "use:sh $0 10001 '2015-11-17'"
	exit 1
else
	file=server_$1
	id=$1
	openday=$2
fi
if [ ! -f /nba/server/$file ];then
	echo "no such file /nba/server/$file"
	exit 1
fi
start=`date +%Y,%m,%d -d ''$openday' -7days'` 
start="["$start",6,30]"
#lstart 联赛时间 现在还未使用
thisDay=`date +%u -d ''$openday''`
netxmonday=$(( 7 - ${thisDay} + 1 ))
lstart=`date +%Y,%m,%d -d ' '$openday' '$netxmonday' days'`
if [ $id -gt 10000 ];then
        type="yyb"
	redisserver=tnba2_redis$id
	trueid=` expr $id - 10000 `
	title="{_id:${id},n:'应用宝公测${trueid}服'"
else
        type="and"
	trueid=` expr $id - 2000 `
	title="{_id:${id},n:'联合${trueid}服'"
	redisserver=nba2_redis$id
fi
echo "===$id区:$type==="
while true
do
	cd /nba/server
	game="["
	ngame="ngame:["
	line=`cat $file|wc -l`
	for ((i=2;i<=$line;i++));
	do  
		row=`awk -v r=$i 'NR==r{print $0}' $file` 
		host=`echo $row|awk '{print $1}'`
		fport=`echo $row|awk '{print $4}'`
		fport=` expr $fport - 1 `
		nums=`echo $row|awk '{print $3}'` 
		wip=`ssh $host "curl -s ip.cn"|awk -F"：" '{print $2}' |awk '{print $1}'`
		nip=`grep -w $host /etc/hosts|awk '{print $1}'`
		for p in `seq 1 $nums`
		do
			port=$(echo ` expr $fport + $p`)
			game=$game"{h:'$wip',p:$port},"
			ngame=$ngame"{h:'$nip',p:$port},"
		done
	done
        echo $game |grep "h:'',p:860"
        if [ $? -ne 0 ];then
                break
        fi
done 
game=`echo $game|sed "s/,$//"`
ngame=`echo $ngame|sed "s/,$//"`
game=${game}"]"
ngame=${ngame}"]"
game=$game,$ngame
oldredis=`grep "{_id:"  /nba/server/server_config_CN_PROD.js.$type|tac|sed -n '1p'|awk -F "fighting_db" '{print $2}'|awk -F [\'] '{print $2}'`
newrow=`grep "{_id:" /nba/server/server_config_CN_PROD.js.$type|tac |sed -n '1p'|sed "s#\({.*,game:\).*\(,gn:'NBA2',union_chaos_fighting.*\)#\1$game\2#"|sed "s/,v:1,/,v:0,/"|sed "s#\({.*,start:\).*\(,close:.*\)#\1$start\2#"|sed "s/$oldredis/$redisserver/g" |sed "s#.*\(,combine:.*\)#$title\1#"`
echo $newrow
if [ "$3" == "w" ];then
	tmpfile="/tmp/`date +%s`"
	tac /nba/server/server_config_CN_PROD.js.$type|sed -r '2s/.*/&,/'|sed "2i$newrow" |tac >$tmpfile
	cp $tmpfile /nba/server/server_config_CN_PROD.js.$type -rf && rm -rf $tmpfile
fi
