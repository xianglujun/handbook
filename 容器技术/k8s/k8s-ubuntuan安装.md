# 关闭防火墙
```sh
sudo ufw disable
```

# 关闭系统swap
```
sudo swapoff -a
```

# 安装docker

# 安装k8s使用
```sh
$ apt-get update && apt-get install -y apt-transport-https
$ curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
$ cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
$ apt-get update
$ apt-get install -y kubelet kubeadm kubectl
```

# 初始化
```sh
sudo kubeadm init --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.14.1 --pod-network-cidr=10.240.0.0/16
```

# 安装成功后执行
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

> 在安装完Master节点后，查看节点信息（ kubectl get nodes)会发现节点的状态为noready。journalctl -xeu kubelet查看noready的原因发现network plugin is not ready: cni config uninitialized是由于cni插件没有配置。其实这是由于还没有配置网络。

# 安装flannel网络配件
Pod之间通过该网络配件进行网络通信
```sh
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 使用该插件
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
```
