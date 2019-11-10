1. `CoreDNS 状态为ERROR, Unable to update cni config: No networks found in /etc/cni/net.d`
```sh
# 获取pod列表
kubectl get nodes

# 获取node下的所有的pod信息
kubectl get pods -n kube-system -o wide |grep 00vmdl-fabriccli-172-19-101-xx

# 查看pod的具体的日志信息
kubectl --namespace kube-system logs kube-flannel-ds-amd64-hk5sn

# 查看具体描述信息
kubectl describe pod kube-flannel-ds-amd64-hk5sn  --namespace=kube-system
```
## 解决办法
```sh
# 安装网络空间进行pod通信
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

2. `plugin/loop: Loop (127.0.0.1:49443 -> :53) detected for zone 问题解决方法`
## 官方描述
```sh
roubleshooting Loops In Kubernetes Clusters
When a CoreDNS Pod deployed in Kubernetes detects a loop, the CoreDNS Pod will start to "CrashLoopBackOff". This is because Kubernetes will try to restart the Pod every time CoreDNS detects the loop and exits.

A common cause of forwarding loops in Kubernetes clusters is an interaction with a local DNS cache on the host node (e.g. systemd-resolved). For example, in certain configurations systemd-resolved will put the loopback address 127.0.0.53 as a nameserver into /etc/resolv.conf. Kubernetes (via kubelet) by default will pass this /etc/resolv.conf file to all Pods using the default dnsPolicy rendering them unable to make DNS lookups (this includes CoreDNS Pods). CoreDNS uses this /etc/resolv.conf as a list of upstreams to forward requests to. Since it contains a loopback address, CoreDNS ends up forwarding requests to itself.

There are many ways to work around this issue, some are listed here:

- Add the following to your kubelet config yaml: resolvConf: <path-to-your-real-resolv-conf-file> (or via command line flag --resolv-conf deprecated in 1.10). Your "real" resolv.conf is the one that contains the actual IPs of your upstream servers, and no local/loopback address. This flag tells kubelet to pass an alternate resolv.conf to Pods. For systems using systemd-resolved, /run/systemd/resolve/resolv.conf is typically the location of the "real" resolv.conf, although this can be different depending on your distribution.
- Disable the local DNS cache on host nodes, and restore /etc/resolv.conf to the original.
- A quick and dirty fix is to edit your Corefile, replacing forward . /etc/resolv.conf with the IP address of your upstream DNS, for example forward . 8.8.8.8. But this only fixes the issue for CoreDNS, kubelet will continue to forward the invalid resolv.conf to all default dnsPolicy Pods, leaving them unable to resolve DNS.
```

## 解决方法
```sh
# 创建resolv.conf文件
mkdir -p /root/kubenets

# 创建文件
touch resolv.conf

# 添加内容
nameserver 114.114.114.114

# 修改文件
vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# 在 KUBERNETES_KUBECONFIG_ARGS新增
--resolv-conf=/root/kubenetes/resolv.conf

# 重启
systemctl daemon-reload
systemctl restart kubelet


# 或者直接修改pod的配置文件
kubectl edit cm coredns -n kube-system

# 将plugin/forward 修改为114.114.114.114
```
