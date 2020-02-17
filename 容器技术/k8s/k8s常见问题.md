## 1. centos安装k8s完成后, 创建rc成功, 但是通过`kubectl get pods`却发现`No Resources found`
### 解决方案
  - 具体为删除/etc/kubernetes/apiserver配置中，KUBE_ADMISSION_CONTROL 中的ServiceAccount字段
```
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"

# 重启apiServer
systemctl restart kube-apiserver
```
>Service account是为了方便Pod里面的进程调用kubernetes API或其他外部服务而设计的。可以理解为pod中的进程调用kubernetes API需要认证，就如用户使用kubectl调用kubernetes API需要认证一样。
>如果kubernetes开启了ServiceAccount（–admission_control=…,ServiceAccount,… ），那么会在每个namespace下面都会创建一个默认的default的sa。
```sh
[root@CentOS-7-4 /home/k8s]# kubectl get sa --all-namespaces
NAMESPACE     NAME      SECRETS   AGE
default       default   0         34m
kube-system   default   0         34m
```
> 我们都只知道，要验证，肯定需要个密钥，也就是这个secrets。从上面查看的情况，系统上并没有这个文件。这本应该是由kubernetes自动创建，但是由于未知原因却没有创建。所以关闭ServiceAccount就无需用到这secrets，就不会报错。

### 完成验证
```sh
1、生成签名密钥:
openssl genrsa -out /tmp/serviceaccount.key 2048

2、更新/etc/kubernetes/apiserver，增加如下配置:
KUBE_API_ARGS="--service_account_key_file=/tmp/serviceaccount.key"

3、更新/etc/kubernetes/controller-manager，增加如下配置:
KUBE_CONTROLLER_MANAGER_ARGS="--service_account_private_key_file=/tmp/serviceaccount.key"

# 重启服务
systemctl restart kube-controller-manager kube-apiserver
```

## 2. 容器一直处于`ContainerCreating`状态中
```sh
# 查看容器的日志状态
kubectl describe pod mysql-nwht2

# 查看日志错误信息为: details: (open /etc/docker/certs.d/registry.access.redhat.com/redhat-ca.crt: no such file or directory)

# 安装rhsm软件
yum install *rhsm*

# 如果还是失败, 需要手工创建ca文件
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm

rpm2cpio python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm | cpio -iv --to-stdout ./etc/rhsm/ca/redhat-uep.pem | tee /etc/rhsm/ca/redhat-uep.pem
```
