#!/bin/bash -e

help ()
{
    echo  ' ================================================================ '
    echo  ' 在当前目录的 charts-out-put 目录中，创建rancher中特定的charts最新版本 '
    echo  ' --rancher-server: 必选，rancher的访问地址'
    echo  ' --rancher-api-key: 必须。从rancher的api&key中获取的apikey'
    echo  ' --rancher-project-id：必须。在rancher上点击一个项目，从地址栏中取得的项目id'
    echo  ' --harbor-server: 必须。harbor的地址'
    echo  ' --save-image：可选，默认false，设置chats里面对应的docker镜像输出目录。如果设定，则会把images导出到charts-out-put/images '
    echo  ' 使用示例，导出project-id=c-bsv8l:p-rcv69的所有charts，并且把镜像输出到images目录'
    echo  ' ./getcharts.sh --rancher-server=dbu.rancher.com --rancher-api-key=token-9zqtt:lj2j78jqjcqmgdx8n4kftn5j79rmq99j7hn548q8jc54shw9t8v2bm \'
    echo  ' --rancher-project-id=c-bsv8l:p-rcv69  --harbor-server=harbor.sobey.com --save-image=true'
    echo  ' ================================================================'
}

case "$1" in
    -h|--help) help; exit;;
esac

if [[ $1 == '' ]];then
    help;
    exit;
fi

CMDOPTS="$*"
for OPTS in $CMDOPTS;
do
    key=$(echo ${OPTS} | awk -F"=" '{print $1}' )
    value=$(echo ${OPTS} | awk -F"=" '{print $2}' )
    case "$key" in
        --rancher-server) RSERVER=$value;;
        --rancher-api-key) RAPIKEY=$value ;;
        --rancher-project-id) RP=$value ;;
        --harbor-server) HARBOR=$value ;;
        --save-image) SAVEIMG=$value ;;
    esac
done

if [ -z "$RSERVER" ];then
    echo 必须传入 --rancher-server
    exit 1
fi

if [ -z "$RAPIKEY" ];then
    echo 必须传入 --rancher-api-key
    exit 1
fi

if [ -z "$RP" ];then
    echo 必须传入 --rancher-project-id
    exit 1
fi

if [ -z "$HARBOR" ];then
    echo 必须传入 --harbor-server
    exit 1
fi 

mkdir -p ./charts-out-put

ACCEPT="Accept:application/json"
AUTHOR="Authorization:Bearer $RAPIKEY"
URL="https://$RSERVER/v3/projects/$RP"

echo "---------导出charts------------"

# 从rancher的api中获取app列表，通过替换字符串的方式构建app charts的版本文件
RS=`curl -k -H "$ACCEPT" -H "$AUTHOR" "$URL/apps"|sed 's/,/\n/g'|grep '\"externalId\"\:\"catalog' | sed 's/"externalId":.*template=//g' | sed 's/\\u0026version=/-/g' | sed 's/\"/.tgz/g'`


for item in `echo -e $RS |sed 's/ /\n/g'|sed 's/\\\\//g' | awk '{print $1}'`;
do
    echo 处理 $item
    curl -k --progress -o ./charts-out-put/$item --progress https://$HARBOR/chartrepo/helm-repo/charts/$item
done

if [ "$SAVEIMG" = "true" ]; then
    echo -e "\n\n\n-----------导出镜像------------\n"
    mkdir -p ./charts-out-put/images
    # 从apps数据中提取工作负载
    RS=`curl -k -H "$ACCEPT" -H "$AUTHOR" "$URL/workload" | sed 's/,/\n/g' | grep '\"id\":'|sed 's/"id"://g'|sed 's/"//g'`
    for iname in `echo -e $RS|sed 's/ /\n/g'|awk '{print $1}'`; 
    do
        #  获取工作负载对应的镜像
        echo -e "========导出$iname的镜像======="
        RS=`curl -k -s -H "$ACCEPT" -H "$AUTHOR" "$URL/workload/$iname" | sed 's/,/\n/g' | grep '\"image\":' | sed 's/[{]*"image"://g'|sed 's/"//g'`
        for image in $RS; 
        do
            imgname=`echo ${image##*/}|sed 's/:/./'`
            docker save -o "./charts-out-put/images/${imgname}.tar"  $image
        done
    done
fi


