#!/bin/bash
#write by zouliuyun 20160728
#help
if [ -z "$1" -o -z "$2" ];then
        echo -e "Usage:\n1.$0 host service\n2.$0 XXX_web01,XXX_web02 basic,node\n3.$0 XXX_mongo1,XXX_mongo2 basic,mongo\n4.$0 XXX_redis1,XXX_redis2 basic,redis\n";
	exit 0;
fi
hosts=`echo $1|sed "s/,/ /g"`
service=`echo $2|sed "s/,/ /g"`

echo -e "这些主机:$hosts\n正准备安装下列服务:$service\n=========================";
read -p "确定吗? (yes/no): " ret;
if [ $ret != "yes" ];then
   exit 1
fi

if [[ "$2" =~ "basic" ]];then
	#ssh no pass
	read -p "please input user:(root)" user
	read -p "please input passwd:" passwd
	for host in $hosts
	do
        ip = `grep /etc/hosts|awk '{print $1}'`
		sed -i "/$host/d"	/root/.ssh/known_hosts;
		sed -i "/$ip/d"	/root/.ssh/known_hosts;
		chmod +x initfirst.sh ;
		./initfirst.sh $host $user $passwd;
	done

	#rsync hosts file
	for host in $hosts
	do
	(
	    /usr/bin/rsync -avz /etc/hosts $host:/etc/

	#basic lib and yum update and epel
	    ssh $host "yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel gcc gcc-c++ make unzip git tcl && rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"


	#rsync necessary file
	    /usr/bin/rsync -avz /infra/install $host:/infra/

	#dns
	    /usr/bin/rsync -avz /etc/resolv.conf $host:/etc/

	#ntpd
	    ssh $host "yum install ntp -y"
	    ssh $host "ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime"
	    ssh $host "service ntpd start"
	    ssh $host "chkconfig ntpd on"

	#snmpd
	    rsync -avz /etc/snmp/snmpd.conf $host:/etc/snmp/
	    ssh $host "service snmpd restart"
	    ssh $host "chkconfig snmpd on"

	#yum install vim and ftp
	    ssh $host "yum install vim ftp -y"

	#create data directory
	    rsync -avz /data/nba $host:/data/
	    rsync -avz /data/downloads $host:/data/

	#upstart
	    rsync -avz /etc/init/* $host:/etc/init/

	#optmize
	    rsync -avz /etc/security/limits.d/90-nproc.conf $host:/etc/security/limits.d/
		rsync -avz /etc/security/limits.conf $host:/etc/security/
		rsync -avz /etc/sysctl.conf $host:/etc/
		ssh $host "sysctl -p"
	)&
	done
	wait
fi



#nodejs
if [[ "$2" =~ "node" ]];then
	for host in $hosts
	do
	(
		ssh $host "cd /data/downloads/node-v0.10.21 && ./configure && make && make install"
	)&
	done
	wait
fi

#nginx
if [[ "$2" =~ "nginx" ]];then
    for host in $hosts
    do
    (
        /usr/bin/rsync -avz /etc/yum.repos.d/nginx.repo $host:/etc/yum.repos.d/
        ssh $host "yum install -y nginx"
        ssh $host "chkconfig nginx on"
        ssh $host "/etc/init.d/nginx start"
    )&	
    done
    wait
fi
#puppet & zabbix
if [[ "$2" =~ "zabbix" ]] || [[ "$2" =~ "puppet" ]];then
    for host in $hosts
    do
    (

#		ssh $host "wget http://mirrors.sohu.com/python/2.7.6/Python-2.7.6.tgz && tar xvf Python-2.7.6.tgz && cd Python-2.7.6 && ./configure && make && make install"
#		ssh $host "python -V"
	ssh $host "rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
	ssh $host "yum -y install puppet && puppet agent --server puppet.mbgadev.cn"
	)&	
    done
    wait
fi
#mongo
if [[ "$2" =~ "mongo" ]];then
    for host in $hosts
    do
	(
		/usr/bin/rsync -avz /usr/bin/mongo* $host:/usr/bin/
#                /usr/bin/rsync -avz /etc/yum.repos.d/mongodb.repo $host:/etc/yum.repos.d/
#                ssh $host "yum -y install mongo-10gen mongo-10gen-server"
#                ssh $host "chkconfig mongod on"
#                ssh $host "/etc/init.d/mongod start"
    )&
	done
	wait
fi

#memcached
if [[ "$2" =~ "memcache" ]];then
    for host in $hosts
    do
	(
        ssh $host "yum -y install memcached"
        ssh $host "chkconfig memcached on"
        ssh $host "/etc/init.d/memcached start"
    )&	    
	done
	wait
fi
#redis
if [[ "$2" =~ "redis" ]];then
    for host in $hosts
    do
	(
		ssh $host "rpm -ivh http://packages.oostergo.net/other/el6/tcl-8.5.9-3.el6.x86_64.rpm"
        ssh $host "cd /root && wget http://pkgs.fedoraproject.org/repo/pkgs/redis/redis-2.6.13.tar.gz/c4be422013905c64af18b1ef140de21f/redis-2.6.13.tar.gz && tar zxvf redis-2.6.13.tar.gz && cd ./redis-2.6.13 && make && make test && make install"
		rsync -avz /etc/redis.conf $host:/etc/
		ssh $host "echo '/usr/local/bin/redis-server /etc/redis.conf' >>/etc/rc.local"
		ssh $host "mkdir -p /data/redis/log"
		ssh $host "mkdir -p /data/redis/data"
        ssh $host "/usr/local/bin/redis-server /etc/redis.conf"
	)&
	done
	wait
fi
#fluentd
if [[ "$2" =~ "fluentd" ]];then
    for host in $hosts
    do
    (
		rsync -avz /infra/install/install-redhat.sh $host:/infra/install/
        ssh $host "/bin/sh /infra/install/install-redhat.sh"
		ssh $host "yum -y install gcc"
		ssh $host "/usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-config-expander"
		ssh $host "/etc/init.d/td-agent start"
		ssh $host "chkconfig td-agent --level 2345 on"
	)&	
	done
	wait
fi
