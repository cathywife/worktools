#!/bin/bsh
flag=$1
if [ -z $flag ];then
        echo "use:$0 nba2ope"
        exit 1
fi
lsgame -e -r 'echo "${host} "`curl -s ip.cn|sed "s/当前 IP：/ /"`' '_node'|grep 来自|awk -v flag=$flag '$1=flag"\t"$1{print $1"\t"$2}'>/etc/hosts_wip
