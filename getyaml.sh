#!/bin/bash -e

help ()
{
    echo  ' ================================================================ '
    echo  ' --kubectl：可选。kubectl的路径'
    echo  ' --type: 必须。需要导出的资源类型，参考k8s资源类型描述，比如pods。'
    echo  ' --ns：必须。命名空间'
    echo  ' --kubeconfig：可选。指定kube配置文件。获取方法参考rancher官网文档”恢复 Kubectl 配置文件“，或在rancher界面进入集群点击【Kubeconfig文件】拷贝内容'
    echo  ' --grep: 可选。用于筛选资源内容。也就是grep的参数 '
    echo  ' 使用示例:'
    echo  ' ./getyaml.sh --type=pods --ns=sobeyficus '
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
        --kubectl) KUBECTL=$value;;
        --type) TYPE=$value ;;
        --ns) NS=$value ;;
        --kubeconfig) KEBECONF=$value ;;
        --grep) GREP=$value ;;
    esac
done

KUBECTL=${KUBECTL:-'kubectl'}

if [ -z "$TYPE" ];then
    echo 需要传入资源类型
    exit 1
fi

if [ -z "$NS" ];then
    echo 需要通过 --ns 指定命名空间
    exit 1
fi

mkdir -p ./getyamlout

for item in `$KUBECTL --kubeconfig=$KEBECONF --insecure-skip-tls-verify=true get $TYPE -n $NS | grep $(echo $GREP)|awk '{print $1}'`; 
do 
    $KUBECTL --kubeconfig=$KEBECONF --insecure-skip-tls-verify=true get $TYPE $item -n $NS -o yaml \
|sed '/creationTimestamp/,/generateName/d' \
|sed '/^status:/,$d' \
|sed '/managedFields/,/^spec:/{/^spec:/!{/^  name:/!{/^  namespace:/!d}}}' \
|sed '/pod-template-hash:/d' | tee ./getyamlout/$item.yaml
done


