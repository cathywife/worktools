#!/bin/bash
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -u 邮件标题 必填
            -t 收件人 多个用逗号隔开 不填发给1325659373@qq.com
            -m 优先正文 必填;
	    -a 附件 可选;
            -h 打印本帮助信息;
        "
    exit 0 
}
#默认参数

title=""
mailto="1325659373@qq.com"
message=""
extra=""
while getopts "u:t:m:a:h" optname
    do
        case "$optname" in 
            "u")
                title="$OPTARG";
                ;;
            "t")
                mailto="$OPTARG";
                ;;
            "m")
                message="$OPTARG";
                ;;
            "a")
                extra="$OPTARG"
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
            "*")
                echo "Unsupported option [$optname]"
                exit_with_help;
                ;;
        esac
    done
if [ -z "$message" -o  -z "$title" ];then
	echo "参数填写错误"
	exit_with_help
fi

if [[ "$mailto" =~ "1325659373@qq.com" ]];then
	echo $mailto
else
	mailto="$mailto,1325659373@qq.com"
fi

function sendmail()
{
	from=$1
	xp=$2
	if [ -z $extra ];then
		/usr/local/bin/sendEmail.pl -f $from -t $mailto -u "$title" -xu $from -xp $xp -s smtp.163.com -m "$message"
	else
		/usr/local/bin/sendEmail.pl -f $from -t $mailto -u "$title" -a $extra -xu $from -xp $xp -s smtp.163.com -m "$message"
	fi
}
sendmail nba_email2@163.com nbadream02
if [ $? -eq 0 ];then
	echo "sendEmail SUCC"
	exit 0;
else
	echo "sendmail nba_email@163.com nbadream021"
fi
