#!/bin/bash
#by liuyun 20151207
#merge执行之后的步骤
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -s 被合区id(按id大小顺序传参)
            -t 目标区id 多个用空格分开
            -h 打印本帮助信息;
	    eg1:sh $0 -s '9999 10000' -t 9998
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
if [ $tid -gt 10000 ];then
        TYPE="yyb"
        loginhost="tnba2_login1 tnba2_login2"
        gmhost="tnba2_gmtool"
	tredis=tnba2_redis$tid
else
        tredis=nba2_redis$tid
        TYPE="and"
        loginhost="nba2_login01 nba2_login02 "
        gmhost="nba2_gmtool_and nba2_gmtool_ios"
fi

#部署redis
file1=/data/nba/nba_game_server/app/config_data_cn/server_config_CN_PROD.js

#清理redis机器
handredis()
{
	echo "=============handle $host ===================="
	cat /nba/server/tools/hequ/$file
	flag="n"
	read -p "确定处理redis mongo ok？(y/n)" flag
	if [ $flag == "y" ];then
        	echo "go on ..."
	else
        	exit 1
	fi
        scp /nba/server/tools/hequ/$file root@$host:/tmp
        if [ $? -eq 0 ];then
                ssh root@$host "cat /tmp/$file|mongo"
        else
                echo "scp $file FAIL"
        fi

        ssh root@$host "$1 tianti_8700;$1 rank_8500"
}

#回收redis处理
for id in $sid
do
        file=sredis
	if [ $id -gt 10000 ];then
        	host=tnba2_redis$id
	else
        	host=nba2_redis$id
	fi
        ssh root@$host "cp /8500 /8500.bak -rf"
        if [ $? -ne 0 ];then
                echo "备份8500失败"
                break
        fi
        ssh root@$host "cd /data/nba/nba_ranking_server/test && node remove_data_file $host 8500 100"
        if [ $? -ne 0 ];then
                echo "clean rank server FAIL"
                break
        fi
        ssh root@$host " sed -i \"/nba_game_server/d\" /var/spool/cron/root"
        ssh root@$host "crontab -l|grep nba"
        ssh root@$host "ps x|grep nba_game_server|grep -v grep|awk '{print \$1}'|xargs kill -9"
	handredis stop
done
#保留redis处理
file=tredis
host=$tredis
handredis restart

echo "请清空天梯排名数据 http://10.96.69.126:4440/project/NBA1_CN/jobs"

#手动修改js配置将A的config删除，将B的config的区服名字改成B-A区 及combine
flag="n"
cd /data/nba/nba_game_server
for id in $sid
do
        sed -i "/{_id:$id,/d" app/config_data_cn/server_config_CN_PROD.js
	ssid=$id
done

ii=` expr $ssid % 2 `
if [ $tid -gt 10000 ];then
	toldtitile="应用宝公测`expr $tid - 10000`服"
	tnewtitle="应用宝公测`expr $tid - 10000`-`expr $ssid - 10000`服"
else
        if [ $ii -eq 1 ];then
		toldtitile="安卓公测` expr $tid / 2 + 1 `服"
		tnewtitle="安卓公测` expr $tid / 2 + 1 `-`expr $ssid / 2 + 1`服"
        else
		toldtitile="iOS` expr $tid / 2 `服"
                tnewtitle="iOS` expr $tid / 2 `-`expr $ssid / 2`服"
        fi
fi

toldcombine="combine:\[`date +%F|sed s/-/,/g`\]"
tnewcombine="combine:\[\]"
sed -i "/{_id:$tid,/s/$toldtitile/$tnewtitle/;/{_id:$tid,/s/$toldcombine/$tnewcombine/"  app/config_data_cn/server_config_CN_PROD.js
diff app/config_data_cn/server_config_CN_PROD.js /nba/server/server_config_CN_PROD.js.$TYPE
read -p "确定js配置修改好了吗？(y/n)" flag
if [ $flag == "y" ];then
        echo "go on ..."
else
        exit 1
fi
cp app/config_data_cn/server_config_CN_PROD.js /nba/server/server_config_CN_PROD.js.$TYPE -rf


exit

echo "pull code"
sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE
sh /nba/server/tools/scpjs_host.sh "$loginhost" $TYPE 8100
for id in $tid $sid
do
	sh /nba/server/tools/rsync_code.sh -i $id -y no
done


#启动8100进程 供QA测试 
perl /nba/nba.pl -s gs -w $tid -t web -o start -a no
for host in $loginhost
do
	echo "去除8300目标区 设置8100所有区可见（临时修改）"	
	ssh $host "cd /data/nba/nba_game_server/app/config_data_cn/ && sed -i "/{_id:$tid,/d" server_config_CN_PROD.js"
	ssh $host "cd /data/8100/nba_game_server/app/config_data_cn/ && sed -i "s/w:0/w:1/g" server_config_CN_PROD.js"
done
perl /nba/nba.pl --host $loginhost -t login -p 8100 -o restart
perl /nba/nba.pl --host $loginhost -t login -p 8300 -o restart

echo "请通知QA测试"
