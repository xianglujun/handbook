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

### Pause容器作用
- 用于判断整个状态, Pause容器与业务无关，这样便于判断整个Pod模块的存在与消亡状态
- Pod里的多个业务容器共享Pause的IP, 共享Pause容器挂接的Volume， 简化了密切关联的业务容器之间的通信问题, 也很好地解决了他们之间的文件共享问题。

### Pod IP
K8S为每个Pod都分配了唯一的IP地址, 称之为PodIp, 一个Pod里的多个容器共享Pod IP地址.

### Pod 分类
- 普通POD
  - 一旦被创建,就会被放在etcd中存储,随后会被k8s master 调度到某个具体的Node上并进行绑定
  - 随后该Pod被对应的Node上的kubelet进程实例化成一组相关的Docker容器并启动起来。
  - 在默认情况下, 当Pod里的某个容器停止, k8s会自动重新启动这个Pod(重启Pod里的所有的容器)
  - 如果所在的Node宕机, 则会将这个Node上的所有Pod重新调度到其他节点上
- 静态Pod
  - 并不存在K8S的etcd存储里, 而是存放在某个具体的Node上的一个具体文件里, 并且只在此Node上运行启动

### Pod资源配额
- 在k8s里, 通常以千分之一的CPU配额为最小单位, 用`m`来表示, 通常一个容器的CPU配额定义为100~300m, 即占用0.1~0.3个CPU
- Memory配额也是一个绝对值, 它的单位是内存字节数.

### 资源配额设定
在k8s里, 一个计算资源进行配额限定需要设定一下两个参数:
- Requests: 该资源的最小申请量, 系统必须满足要求
- Limits: 该资源最大允许使用的量, 不能被突破, 当容器视图使用超过这个量的资源时, 可能会被Kubernetes Kill 并重启

## Label(标签)
Label是Kubernetes系统中另一个核心概念. 一个Label是一个key=value的键值对，其中key与value由用户自己指定。

可以通过给指定的资源对象捆绑一个或多个不同的Label来实现多维度的资源分组管理功能, 以便于灵活, 方便地进行资源分配、调度、配置、部署等管理工作。

- 标签给某个资源对象定义Label，就相当于给它打了一个标签, 随后可以通过Label Selector(标签选择器)查询和筛选拥有某些Label的资源对象。

### Label Selector
- 基于等式的(Equality-based)
  - name = redis-slave: 匹配所有具有标签 name = redis-slave的资源对象
  - env != production: 匹配所有不具有标签env=production的资源对象
- 基于集合的(Set-based)
  - name in (redis-slave, redis-master): 匹配所有具有标签name=redis-master 或者name=redis-slave资源对象
  - name not in (php-frontend): 匹配所有不具有标签name=php-frontend的资源对象.

> Note: Label Selector 表达式的组合实现复杂的条件选择, 多个表达式之间用","进行分割即可, 几个条件之间是"AND"关系。

### 应用场景：
- kube-controller 进程通过资源对象RC上定义的Label Selector 来筛选要监控的Pod副本的数量, 从而实现Pod副本的数量始终复核预期设定的全自动控制流程。
- kube0proxy 进程通过Service的Label Selector 来选择对应的Pod, 自动建立起每个Service到对应Pod的请求转发路由表, 从而实现Service的只能负载均衡机制。
- 通过对某些Node定义Label, 并且在Pod定义文件中使用NodeSelector这种标签调度策略, kube-scheduler进程就可以实现Pod`定向调度`的特性。

> NOTE: 使用Label可以给对象创建多组标签, Label和Label Selector 共同构建成了Kubernetes系统中最核心的应用模型, 使得被管理对象能够被惊喜地分组管理，同时实现了整个集群的高可用性。

## Replication controller
RC是Kubernetes 系统中最核心概念之一， 他定义了一个期望的场景，即声明某种Pod的副本数量在任意时刻都符合某个预期值, 所以RC的定义包含如下几个部门：
- Pod期待的副本数(replicas)
- 用于筛选目标Pod的Label Selector
- 当Pod的副本数量小于预期数量时, 用于创建新Pod的Pod模板(template)

> NOTE: 删除RC并不会影响通过该RC已经创建好的Pod. 为了删除所有的Pod, 可以设置`replicas`的值为0， 然后更新该RC.

### Replicas Set
由于Replication Controller 和Kubernetes 代码中的模块Replications Controller 同名, 同时这个词无法表达本意, 所以在kuberntes v1.2时, 就被升级为————Relicas Set .

- 与Replication Controller 区别:
  - Replicas Set 支持基于集合的Label Selctor (Set-based selector)
  - 而RC只支持基于等式的Label Selector (Equality-based selector)

这使得Replicas Set 的功能更强。
> NOTE: 当前我们很少单独使用Replicas Set， 它主要被Deployment这个更高层的资源对象所使用。从而形成一整套Pod创建，删除，更新的编排机制。

### RC(Replicas Set)的特性与作用
- 在大多数情况下, 我们通过定义一个RC实现Pod的创建过程及副本数量的自动控制
- RC里包括完整的Pod定义模板
- Rc通过Label Selector 机制实现对Pod副本的自动控制
- 通过改变RC里的Pod副本数量, 可以实现Pod的扩容或缩容功能
- 通过改变RC里Pod模板的镜像版本，可以实现Pod的滚动升级功能。

## Deployment
Deployment 是k8s v1.2引入的概念， 引入的目的是为了更好地解决Pod的编排问题。 Deployment 在内部使用了Replica Set 来实现。

Deployment 相对于RC的一个最大升级是我们随时知道当前Pod部署的进度。实际上由于一个Pod的创建、调度、绑定节点及在目标Node上启动对应的容器这一晚这也难怪的过程需要一定的时间，所以我们期待系统启动N个Pod副本的目标状态, 实际上是一个连续变化"部署过程"导致的最终状态。

### Demployment 使用场景
- 创建一个Deployment对象来生成对应的Replica Set并完成Pod的创建过程
- 检查Demployment 的状态来看部署动作是否完成(Pod副本的数量是否达到预期的值)
- 更新Demployment已创建新的Pod(比如镜像升级)
- 如果当前Demployment不稳定, 则回滚到一个早先的Demployment版本
- 暂停Demployment以便于一次性修改多个PodTemplateSpec的配置项, 之后再回复Demployment进行新的发布
- 扩展Demployment以对应高负载
- 查看Demployment的状态, 以此作为发布是否成功的指标
- 清理不再需要的旧版本ReplicatSet

### 定义的变更
Demployment定义与Replica Set 的定义很相似, 除了API声明与Kind类型等有所区别:
```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
```

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
