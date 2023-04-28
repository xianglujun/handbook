# Deployment

## Deployment简介

Deployment实现了一个非常重要的功能: `Pod的水平扩展/收缩(horizontal scaling out/in)`

`Deployment`遵循一种叫做"滚动更新(Rolling update)"的方式，来升级现有的容器，而这个能力的实现，依赖于kubernetes的一个重要概念（API对象）:`ReplicaSet`

### ReplicaSet简单实例

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-set
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
```

从YAML文件中，我们可以看到`一个ReplicaSet对象，其实就是由副本数目的定义和Pod模板组成的`

> 更重要的是, Deployment控制器实际操作的，正是这样的ReplicaSet对象，而不是Pod对象

### 简单的Deployment定义

```yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

### Deployment、ReplicaSet、Pod三者的关系

- `ReplicaSet`负责通过`控制器模式`，保证系统中Pod的个数永远等于指定个数
  - 这也是Deployment只允许容器的`restartPolicy=Always`的主要原因：只有在容器能保证自己始终是`Running`状态的前提下, `ReplicaSet`调整Pod的个数才有意义。
- `Deployment`也同样通过`控制器模式`，来操作`ReplicaSet`的个数和属性，从而实现`水平扩展/伸缩`和`滚动更新`编排动作。
- `Deployment Controller`实际上控制的`ReplicaSet`数量，以及每个`ReplicaSet`的属性
- 而一个应用的版本，对应的正式一个`ReplicaSet`; 这个版本应用的Pod数量，则由`ReplicaSet`通过它自己的控制器来保证
- 通过这样的多个`ReplicaSet`对象，Kubernetes项目实现了对多个"应用版本"的描述



### Deployment 水平扩展/伸缩

```sh
kubectl scal deployment nginx-deployment --replicas=4
```



## 滚动更新

1. 创建`nginx-deployment `

```sh
kubectl create -f nginx-deployment.yaml --record
```

> `--record`参数, 用于记录每次操作所执行的命令，以方便后面查看

2. 查看Deployment状态信息

```sh

$ kubectl get deployments
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3         0         0            0           1s
```

- `DESIRED`: 用户期望的Pod副本个数（`spec.replicas`值）
- `CURRENT`: 当前处于Running状态的Pod的个数
- `UP-TO-DATE`: 当前处于最新版本的Pod的个数，所谓最新版本指的是`Pod的Spec部分与Deployment里Pod模板里定义的完全一致`
- `AVAILABLE`: 当前已经可用的Pod的个数，即`既是Running状态，又是最新版本，并且已经处于Ready状态的Pod的个数`



### 查看Deployment状态变化

1. 查看`Deployment`状态变化

```sh

$ kubectl rollout status deployment/nginx-deployment

Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
deployment.apps/nginx-deployment successfully rolled out
```

2.  查看`ReplicaSet`列表

```sh
kubectl get rs
```

- 当用户提交了一个`Deployment`对象后, `Deployment Controller`就汇立即创建一个Pod副本为3的`ReplicaSet`。这个`ReplicaSet`的名字，由Deployment的名字和一个`随机字符串`共同组成
  - 这个随机字符串叫做`pod-template-hash`, `ReplicaSet`会把这个随机字符串加载它所控制的所有Pod标签里，从而保证这些Pod不会与集群里的其他Pod混淆。可以通过`kc get pod nginx-deployment-hash -o json`查看`label`信息。
- `ReplicaSet`的`DESIRED`, `CURRENT`, `READY`字段的含义，和`Deployment`中是一致的。*`相比之下，Deployment只是在ReplicaSet基础上，添加了UP-TO-DATE这个跟版本字段有关的字符`*

### 更新Deployment

1. 通过`kubectl edit`命令, 该命令直接编辑Etcd里的API对象

```sh
kubectl edit deployment/nginx-deployment
```

> 通过`kubectl edit`指令，会直接打开nginx-deployment的API对象，就可以直接修改Pod模板部分。

> `kubectl edit`命令通过把API对象的内容下载到本地文件，修改完成之后再提交上去。

```sh
kubectl describe deployment nginx-deployment
```

可以通过该命令，查看Deployment `Events`内容， 看到`滚动更新`流程。



### 滚动更新原理

- 当修改了`Deployment`里的Pod定义之后，Deployment Controller 会使用这个修改后的Pod模板，创建一个新的`ReplicaSet`，这个`ReplicaSet`的初始Pod副本数是: `0`

### 滚动更新的优点

- 如果新版本Pod有问题启动失败，那么`滚动更新`就会停止，从而允许开发和运维人员进入。而在这个过程中，由于应用本身还有旧版本的Pod在线，索引服务不会受到太大的影响
- 要求一定要使用Pod的`Health Check`机制检查应用的运行状态，而不是简单地依赖于容器的Running状态。否则可能会导致`容器已经变成Running状态，但是服务可能启动失败`, 这时`滚动更新`的效果就无法达到
- 为了进一步保证服务的连续性，`Deployment Controller` 还会确保，在任何时间窗口内，只有指定比例的Pod处于离线状态。同时，也会确保，在任何时间窗口内，只有指定的新Pod被创建出来。这两个比例的值都是可以配置的，默认都是`DESIRED值的25%`

### 配置滚动更新策略

```yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
...
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
```

- `maxSurge`: 指定的是除了`DESIRED`数量之外，在一次滚动中，Deployment控制器还可以创建多个新Pod；
- `maxUnvailable`: 值的是在一次滚动中，Deployment控制器可以删除多少个旧Pod
  - 该值还可以通过百分比的形式来指定: `maxUnvailable=50%`值的我们最多可以一次删除`50%DESIRED数量个Pod`

## 回滚更新

1. 查看回滚版本列表

```sh
kubectl rollout history deployment/nginx-deployment
```

2. 查看某个具体版本的Api细节

```sh
kubectl rollout history deployment/nginx-deployment --revision=2
```

3. 回滚到具体的某一个版本

```sh
kubectl rollout undo deployment/nginx-deployment --to-revision=2
```

这样Deployment Controller 还会按照`滚动更新`的方式，完成对Deployment的降级操作。



### 限制Deployment生成ReplicaSet的数量

Kubernetes项目提供了一个指令, 使得我们对Deployment的多次更新操作，最后只生成一个`ReplicaSet`

```sh
# 执行更新Deployment之前, 优先执行
kubectl rollout pause deployment/nginx-deployment
```

- 这个`kubectl rollout pause`的作用, 是让这个`Deployment`进入了一个"暂停"状态。

- 接下来, 就可以随意使用`kubectl edit` 或者`kubectl set image`指令，修改Deployment的内容了。
- 此时由于触发了Deployment的`暂停`状态，所以我们对Deploymentt的所有修改，都不会触发新的`滚动更新`, 也不会创建`ReplicaSet`
- 当对Deployment修改操作都完成之后, 只需要执行一条`kubectl rollout resume`，就可以将当前的Deploymentt恢复过来。

```sh
kubectl rollout resume deploy/nginx-deployment
```

> 在`kubectl rollout resume`命令执行之前， 在`kubectl rollout pause`指令之后的这段时间里, 我们队Deployment进行的所有修改，最后只会触发一次`滚动更新`



### 历史ReplicaSet数量控制

在Deployment中, 可以通过指定`spec.revisionHistoryLimit`控制保留`历史版本`个数。如果我们设置为`0`, 将不能再进行回滚操作