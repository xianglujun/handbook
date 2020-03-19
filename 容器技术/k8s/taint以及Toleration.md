# Taint/Toleration

默认情况下, master节点是不允许运行用户Pod,而kubernetes做到这一点，依靠的是Kubernetes的Taint/Toleration机制.



## 原理

一旦某个节点被加上了一个Taint, 即被"打上了污点", 那么所有Pod都不能在这个节点上运行。除非，有个别Pod声明能"容忍"这个污点, 即声明了Toleration, 才可能在这个节点上运行。



### 为节点大上污点

```sh
kubectl taint nodes node1 foo=bar:NoSchedule
```

> 说明:
>
> foo=bar:NoSchedule是一个键值对格式的, 其中_NoShedule_, 意味着这个Taint会在调度新Pod时产生作用, 而不会影响已经在node1上运行的Pod, 那怕他们没有Toleration.



### 声明Toleration

```yaml
apiVersion: v1
kind: Pod
...
spec: tolerations: 
- key: "foo" 
  operator: "Equal" 
  value: "bar" 
  effect: "NoSchedule"
```



### 删除污点

```sh
kubectl taint nodes --all noderole.kubernetes.io/master-
```