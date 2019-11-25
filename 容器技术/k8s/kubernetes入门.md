# Kubernetes 入门

## K8s是什么
- 是一个全新的基于容器技术的分布式架构领先方案
- 提供了服务治理, 故障处理等解决方案
- 是一个开放的平台, 他不局限于任何一种语言, k8s都能够将其映射为service服务, 并通过标准的TCP协议进行通信
- 是一个完备的分布式系统支撑平台. k8s提供了完善的管理工具, 这些工具涵盖了包括开发, 部署测试、运维监控在内地各个环节。

## Service
Service是分布式集群架构的核心, 一个service对象拥有如下关键特征:
- 拥有一个唯一的名字, 比如: mysql-server
- 拥有一个虚拟IP(ClusterIP、Service IP或VIP)和端口
- 能够提供某种远程服务能力
- 被映射到了提供这种服务能力的一组容器应用上

Service的服务进程目前都是基于Socket通信方式对外提供服务, 或者是实现了某个具体业务的特定的`TCP Server`进程。 `Service`通常是由多个相关的额服务进程来提供服务, 每个服务进程都有一个独立的`Endpoint(IP+PORT)`访问点, 但Kubernetes能够让我们通过Service(虚拟Cluster IP + Service Port)链接到指定的Service上。

## Service之间的隔离实现
容器提供了强大的隔离功能, 所以有必要把为Service提供服务的这组进程放入容器中进行隔离。为此, Kubernetes设计了`pod`对象, 将每个服务进程包装到响应的POD中, 使其成为Pod中运行的一个容器(Container).

为了建立Service和pod间的关联关系, Kubernetes首先给每个Pod贴上一个标签。然后给响应的`Service`定义标签选择器(Label Selector)。

## pod
- Pod运行在一个被称之为`节点(Node)`的环境中, 这个节点既可以是物理机, 也可以是私有云或者公有云中的一个虚拟机，通常在一个节点上有几百个POD
- 每个Pod里运行着一个特殊的被称之为`Pause的容器`, 其他容器则为业务容器, `这些业务容器共享Pause容器的网络栈和Volume挂载卷`。因此他们之间的通信和数据交换更为高效，在设计师我们可以充分利用这一特性将一组密切相关的服务进程放到同一个POD中。
- 并不是每个Pod和它里面运行的容器都能映射到一个Service上, 只有那些提供服务的一组Pod才会被映射成一个服务。

## Master-Slave
在集群管理方面, Kubernetes将集群中的机器划分为`Master`节点和一群工作节点(`Node`). 其中, 在`Master`节点上运行着集群相关的一组进程`kube-apiserver`,`kube-controller-manager`,`kube-scheduler`. 这些进程实现了整个集群的资源管理,`Pod调度`,`弹性伸缩`,`安全控制`,`系统监控`和`纠错`等管理功能，并且是全自动完成的。

在`Node`上Kubernetes管理的最小运行单元是Pod, Node上运行着Kubernetes的`kublet`,`kube-proxy`服务进程，这些服务进程负责Pod的`创建`,`启动`,`监控`,`重启`,`销毁`以及实现软件模式的负载均衡器。

## k8s的服务集群的扩展原理
在k8s集群中, 只需要为扩容的service关联的Pod创建一个RC(Replication Controller)，则该Service的扩容以至于后来的Service升级等问题都可以得到解决。

在一个RC定义文件中包括以下3个关键信息:
- 目标Pod的定义
- 目标Pos需要运行的副本数量(Replicas)
- 要监控的目标Pod的标签(Label)

### 运行原理
- 在创建好RC(系统将自动创建好Pod)后, K8s会通过RC中定义的Label筛选出对应的Pod实例并实时监控其状态和数量
- 如果数量小于定义的副本数量(Replicas)，则会根据RC中定义的Pod模板来创建一个新的Pod
- 然后将此Pod调度到合适的Node上启动运行, 直到Pod实例的数量达到预定目标

## Master
k8s里的Master指的是集群控制节点, 每个k8s几区里面需要有一个Master节点来负责整个集群的管理和控制, 基本上k8s的所有控制命令都发给它, 它来负责具体的执行过程。

### 关键进程
- `Kubernetes API Server (kube-apiserver)`: 提供了HTTP Rest接口的关键服务进程, 是k8s里所有资源的增、删、改、查等操作的唯一入口，也是集群控制的入口进程
- `Kubernates Controller Manager (kube-controller-manager)`: Kubernetes 里所有资源对象的自动化控制中心, 可以理解为资源对象的管理者
- `Kubernetes Scheduler (kube-scheduler)`: 负责资源调度(Pod调度)的进程
- 在Master节点上还需要启动`etcd`服务, 所有k8s里的所有资源独享的数据全部保存在etcd中

## Node
Node节点才是Kubernetes集群中的工作负载节点, 每个Node都会被Master分配一些工作负载, 当某个Node宕机时, 其上的工作负载会被Master自动转义到其他节点上去

每个Node节点都运行着一下一组关键进程:
- `kubelet` 负责Pod对应的容器的创建、启停等任务，同时与Master节点紧密协作, 实现集群管理的基本功能
- `kube-proxy`: 实现kubernetes Service 的通信与负载均衡机制的重要组件
- `Docker Engine`: Docker引擎, 负责本机的容器创建和管理工作



### 工作原理

- Node节点可以在运行期间动态增加到kubernetes集群中, 前提是每个节点已经正确安装、配置和运行了关键进程
- 在默认情况下kubelet会想Master注册自己, 这也是kubernetes `推荐的Node管理方式`
- Node被纳入集群管理范围, kubelet 进程就汇定时向Master节点汇报自身的情报, 例如`操作系统，docker版本，机器的CPU, 内存情况，以及当前哪些Pod在运行等`, 这样Master可以获知每个Node的资源使用情况, 并实现高效均衡的资源调度策略。
- 而某个Node超过指定时间不上报信息时, 会被Master判定为"失联", Node的状态会被标记为不可用(Not Ready), 随后Master会出发"工作负载大转移"的自动流程。
