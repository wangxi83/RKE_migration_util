# migration_util
some utils for special migration on k3s or k8s

For some reasons we need to migrate some 'Helm-Charts(from helm-repo), images' even some 'POD-Yamls'

Here're utils we used

----

1-  images

File: ./save-images-to-tar/save-images.sh

Usage:

```
1) list your images
docker images | grep <some grep>|awk '{printf("%s:%s\n",$1,$2)}'  >> images.txt
docker images | grep <some grep>|awk '{printf("%s:%s\n",$1,$2)}'  >> images.txt
.... and more images 

2) save them to a single tar file
./save-images-to-tar/save-images.sh --image-list ./images.txt
```

a `all-images.tar.gz` file will craete. We can `docker load` from it

Fearther, you can use './save-images-to-tar/load-images-registry.sh' to upload images to a registry

----

2- helm-charts

File: ./getcharts.sh

Usage:

```shell
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


```

after this, all charts will downloaded to dir ./charts-out-put , if option --save-image=true, will save docker images belong to the charts to dir ./charts-out-put/images  

3- pod-yamls

File: ./getyaml.sh

Usage:

```shell
help ()
{
    echo  ' ================================================================ '
    echo  ' --kubectl：optional。the path to kubectl '
    echo  ' --type: must。k8s resourcetype，ex. pods。'
    echo  ' --ns：must。k8s namespace'
    echo  ' --kubeconfig：optional。Kubeconfig file'
    echo  ' --grep: optional。some grep workds '
    echo  ' 使用示例:'
    echo  ' ./getyaml.sh --type=pods --ns=sobeyficus '
    echo  ' ================================================================'
}
```

after this, all yamls will download to ./getyamlout. And then we can `kubectl apply -f ./getyamlout` to apply them to another cluster


