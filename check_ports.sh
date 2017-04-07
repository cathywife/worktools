#!/bin/bash
rpm -q nc >/dev/null 2>&1
if [ $? != 0 ];then
yum -y install nc >/dev/null 2>&1
fi
#config_dir='/nba/server/'
config_dir='/data/nba/nba_game_server/app/config_data_cn/'
server_dir='/nba/server/'
and_config='server_config_CN_PROD.js.and'
ios_config='server_config_CN_PROD.js.ios'
default='server_config_CN_PROD.js'
server_id=$(awk -F'_id:' '{print $2}' $config_dir$default|grep -v ^$ |awk -F',' '{print $1}')
ok_log='/tmp/check_ports_ok.log' 
#[ -f $ok_log ] && rm -f $ok_log
fail_log='/tmp/check_ports_fail.log'
#[ -f $fail_log ] && rm -f $fail_log
flag_log='/tmp/faild.flag'
touch $ok_log $faid_log $flag_log
>/tmp/arter.ok

#########################
#check_host_ports
########################
function check_host_port()
{  	   
host=$1
check_port=$2	
n=0
for ((i=1;i<=3;i++))
do
  check_result=`nc -z $host $check_port`
  if [[ $check_result =~ 'succeeded' ]] && [[ $i == 3 ]];then
		echo "`date +'%F %T'` $host $check_port OK" >> /tmp/arter.ok
		if grep "$host $check_port" $fail_log > /dev/null 2>&1;then
			if grep "$host $check_port" $ok_log > /dev/null 2>&1;then
				sed -i "/$host $check_port/d" $fail_log
				continue
			else
				echo "`date +'%F %T'` $host $check_port OK" >> $ok_log
				sed -i "/$host $check_port/d" $fail_log
			fi
		else
			sed  -i "/$host $check_port/d" $ok_log
		fi
  elif [[ $check_result =~ 'succeeded' ]] ;then
	continue
  else
          let "n = n+1"
	  sleep 2
	  if [[ $n -ge 3 ]];then
		if grep "$host $check_port" $fail_log > /dev/null 2>&1;then
			sed  -i "/$host $check_port/d" $ok_log
			#echo "1" > $flag_log
			continue
		else
			echo "`date +'%F %T'` $host $check_port FAILED" >> $fail_log
			sed  -i "/$host $check_port/d" $ok_log
			#echo "1" > $flag_log
		fi 
	  fi
  fi
done
}
########check_redis################
function check_redis()
{
id=$1
host="nba_redis$id"
check_ports='8700 8701 6379 8500 8501 8400 27017'
for check_port in $check_ports
do
	check_host_port $host $check_port
done

}

########################
#check_node_ports
########################
for id in $server_id
do 
check_redis $id
server_file=${server_dir}server_$id
grep -Ev '^#|#|^$' $server_file|while read host aredid port_nums port
do 
     for ((j=0; j< $port_nums;j++))
     do 
     	
        check_port=$(($port+$j))
        check_host_port $host $check_port
      done
done
done

######################
#check_common_ports
####################################
function check_common_ports()
{
hosts=$1
check_ports=$2	
for host in $hosts
do 
	for check_port in $check_ports
	do 
		check_host_port $host $check_port
	done
	#ssh $host "echo \"db.currentOp()\"|mongo admin|grep fsyncLock" >>$fail_log
done
}

###############################
#check_fighting
###############################
#hosts=('nba2_fighting01 nba2_fighting02 nba2_fighting01_ios nba2_fighting02_ios')
#check_ports='8885'
#check_common_ports "$hosts"  "$check_ports"

###############################
#check_commonredis
###############################
#hosts=('nba_commonredis1')
hosts="nba_mongod24  nba_mongod9 nba_mongod14 nba_mongod12 nba_mongod7 nba_mongod21 nba_mongod5 nba_mongod8 nba_mongod13 nba_mongod4 nba_mongod10 nba_mongod17  nba_mongod15 nba_mongod1 nba_mongod2 nba_mongod3"
check_ports="27017"
check_common_ports "$hosts" "$check_ports"

hosts=('nba_mongod102 nba_mongod103')
check_ports="37017"
check_common_ports "$hosts" "$check_ports"
#跨服
hosts=('nba_redis10001')
check_ports="8900 8500 27017"
check_common_ports "$hosts" "$check_ports"

hosts=('nba_node1
nba_node112
nba_node115
nba_node119
nba_node2
nba_node20
nba_node29
nba_node34
nba_node35
nba_node41
nba_node43
nba_node53
nba_node56
nba_node66
nba_node69
nba_node70
nba_node76
nba_node77
nba_node96
nba_nodebk2')
check_ports="8400"
check_common_ports "$hosts" "$check_ports"
mail='liuyun.zou@dena.jp,1325659373@qq.com,infra-em@em.denachina.com'
#mail='infra_cn@dena.jp'

theme="NBA-1-CN"
#[ -s $ok_log ]  && [ -s $flag_log ] && [ ! -s $fail_log ] && cat  $ok_log|mailx -v -s "$theme check ports recovery" $mail  && rm -f $flag_log
#[ -s $ok_log ]  && [ -s $flag_log ]  && >  $flag_log && cat  $ok_log|mailx -v -s "$theme check ports recovery" $mail 
#[ -s $fail_log ] && echo "1" > $flag_log  && cat $fail_log|mailx -v -s "$theme check ports fail" $mail 


[ -s $ok_log ]  && [ -s $flag_log ]  && >  $flag_log && sh  /nba/server/tools/sendEmail.sh -t $mail -u "$theme check ports recovery" -m "`cat $ok_log`" 
#[ -s $fail_log ] && echo "1" > $flag_log  && sh  /nba/server/tools/sendEmail.sh -t $mail -u "$theme check ports fail" -m "`cat $fail_log`"  
touch /tmp/md5
md5=`cat /tmp/md5`
if [ -s $fail_log ];then
        newmd5=`cat $fail_log|md5sum|awk '{print $1}'`
        if [ "$md5" == "$newmd5" ];then
                exit 0
        fi
	echo "1" > $flag_log
        sh  /nba/server/tools/sendEmail.sh -t $mail -u "$theme check ports fail" -m "`cat $fail_log`"
        echo $newmd5 >/tmp/md5
fi

