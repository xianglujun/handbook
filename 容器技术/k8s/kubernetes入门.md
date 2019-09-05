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

容器提供了强大的隔离功能, 所以有必要把为Service提供服务的这组进程放入容器中进行隔离。为此, Kubernetes设计了`pod`对象, 将每个服务进程包装到响应的POD中, 使其成为Pod中运行的一个容器(Container).

为了建立Service和pod间的关联关系, Kubernetes首先给每个Pod贴上一个标签。然后给响应的`Service`定义标签选择器(Label Selector)。

## pod
- Pod运行在一个被称之为节点(Node)的环境中, 这个节点既可以是物理机, 也可以是私有云或者公有云中的一个虚拟机，通常在一个节点上有几百个POD
- 每个Pod里运行着一个特殊的被称之为Pause的容器, 其他容器则为业务容器, 这些业务容器共享Pause容器的网络栈和Volume挂载卷。因此他们之间的通信和数据交换更为高效，在设计师我们可以充分利用这一特性将一组密切相关的服务进程放到同一个POD中。
- 并不是每个Pod和它里面运行的容器都能映射到一个Service上, 只有那些提供服务的一组Pod才会被映射成一个服务。

## Master-Slave
在集群管理方面, Kubernetes将集群中的机器划分为`Master`节点和一群工作节点(`Node`). 其中, 在`Master`节点上运行着集群相关的一组进程`kube-apiserver`,`kube-controller-manager`,`kube-scheduler`. 这些进程实现了整个集群的资源管理,`Pod调度`,`弹性伸缩`,`安全控制`,`系统监控`和`纠错`等管理功能，并且是全自动完成的。

在`Node`上Kubernetes管理的最小运行单元是Pod, Node上运行着Kubernetes的`kublet`,`kube-proxy`服务进程，这些服务进程负责Pod的`创建`,`启动`,`监控`,`重启`,`销毁`以及实现软件模式的负载均衡器。
