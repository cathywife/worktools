#!/bin/bash
#by liuyun 20151114
exit_with_help()
{
    echo "Usage: $0 [OPTION] PATTERN
        Options:
            -v 静态资源版本号码 
            -H 热修版本号
            -T ios/and/yyb
            -h 打印本帮助信息;
            eg1:sh $0 -v 3456 -T NBA1
            eg2:sh $0 -H 7 -T NBA2
        "
    exit 1
}
version=""
FixVersion=""
TYPE=""
while getopts ":v:H:T:h" optname
do
        case "$optname" in
            "v")
		if [ "$OPTARG" == null ];then
			version=""
		else
                	version="$OPTARG";
		fi
                ;;
            "H")
		if [ "$OPTARG" == null ];then
			FixVersion=""
		else
                	FixVersion="$OPTARG";
		fi
                ;;
            "T")
                TYPE="$OPTARG";
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

case "$TYPE" in
        "NBA1")
                CQCip=10.96.36.81
;;
        "NBA2")
                CQCip=10.96.69.175
;;
       *)
                echo "you choose TYPE is not exsit"
                exit 1
;;
esac
ssh $CQCip "sh /home/zouly/update_CQC.sh -v \"$version\" -H \"$FixVersion\""
