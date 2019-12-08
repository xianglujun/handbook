# k8s-ubuntu安装教程

## 系统配置
```sh
# 禁用swap
swapoff -a

# 禁用防火墙
systemctl stop firewalld
systemctl disable firewalld

# 禁用setlinux
apt install selinux-utils
setenforce 0
```

## 安装docker
```sh
# 安装工具包
apt-get update && apt-get install -y apt-transport-https curl

# 添加秘钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# 安装docker
apt-get install docker.io -y

# 启动docker service
systemctl enable docker
systemctl start docker
systemctl status docker

```

## 对于镜像加载慢的问题, 使用阿里云的镜像库
```sh
vim  /etc/docker/daemon.json
{
    "registry-mirrors": ["https://alzgoonw.mirror.aliyuncs.com"],
    "live-restore": true
}

# 重启docker
systemctl daemon-reload
systemctl restart docker
```

## 安装kubelet, kubectl, kubeadm
```sh
# 安装依赖插件
apt-get update && apt-get install -y apt-transport-https

# 添加秘钥(对于不同的源要添加不同的密钥)
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# 添加软件源
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

# 国内可通过该仓库安装
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main
EOF

# 阿里云的安装仓库
sudo curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 

# 设置仓库地址
sudo cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

# 执行安装
apt-get update && apt-get install -y kubelet kubeadm kubectl

# 开机启动
systemctl enable kubectl
```

## 配置Master
```sh
# 设置配置文件
export KUBECONFIG=/etc/kubernetes/admin.conf

# 重启kubelet
systemctl daemon-reload
systemctl restart kubelet

# 初始化节点
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.2.14.78 --kubernetes-version=v1.13.2 --ignore-preflight-errors=Swap

- pod-network-cidr是指配置节点中的pod的可用IP地址，此为内部IP
– apiserver-advertise-address 为master的IP地址
– kubernetes-version 通过kubectl version 可以查看到
```

### 可能存在部分源无法使用的情况
```sh
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.16.2
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.16.2
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.16.2
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.3.15-0
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.2
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.16.2
```

### 重新tag以上镜像
```sh
 docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.16.2 k8s.gcr.io/kube-controller-manager:v1.16.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.16.2 k8s.gcr.io/kube-scheduler:v1.16.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.16.2 k8s.gcr.io/kube-proxy:v1.16.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1 k8s.gcr.io/pause:3.1
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.3.15-0 k8s.gcr.io/etcd:3.3.15-0
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.2 k8s.gcr.io/coredns:1.6.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.16.2 k8s.gcr.io/kube-apiserver:v1.16.2

# 重新执行
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.3.37 --kubernetes-version=v1.16.2 --ignore-preflight-errors=Swap

```

## 安装网络控件进行通信
```sh
# 安装网络空间进行pod通信
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

## node节点链接master节点
```sh
kubeadm join 10.2.14.78:6443 --token h7u22o.nk23ias5f1ft8hj9 --discovery-token-ca-cert-hash sha256:9f93785608c9a9de3e5d74e9ed30b8302691abfee7efd946a8c1b80d8582fe92
```

## 问题列表
