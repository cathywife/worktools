#!/bin/bash
#by liuyun 20151126
#变更某台机器主机名
if [ -z "$1" -o -z "$2" ];then
	echo "变更某台机器主机名"
        echo "use:$0 oldhost newhost"
        exit 1
fi
oldhost=$1
newhost=$2
grep -w $oldhost /etc/hosts
if [ $? -ne 0 ];then
	echo "oldhost $oldhost not exsit"
	exit 1
fi
ssh $oldhost "hostname $newhost"
ssh $oldhost "sed -i s/HOSTNAME=$oldhost/HOSTNAME=$newhost/ /etc/sysconfig/network && grep $newhost /etc/sysconfig/network"
cp /etc/hosts /etc/hosts.bak && sed -i "s/\<$oldhost\>/$newhost/g" /etc/hosts
cat /etc/hosts|grep  -w $newhost
if [ $? -ne 0 ];then
        echo "ERROR:update host FAIL"
        exit 1
fi

#确认ope机器上的hosts修改正确
sed -i /$oldhost/d /root/.ssh/known_hosts 
#lsgame -r 'cp /etc/hosts /etc/hosts.bak && rsync -avz 10.96.69.126:/etc/hosts /etc/hosts' 'nba2'
