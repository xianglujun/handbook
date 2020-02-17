# 什么是dubbo
Dubbo是一个开源分布式服务框架, 它的最大特点是按照分层的方式来架构, 使用这种方式可以使各个层之间解耦合。从服务模型的角度来看, Dubbo采用的是一种非常简单的抹胸，要没事提供方提供服务, 要么是消费方提供服务。

## 总体架构
dubbo架构设计一共划分了10个层, 最上面的Service层是留给实际想要使用Dubbo开发分布式服务的开发者实现业务逻辑的接口层。
- 服务接口层(Service): 该层是与实际业务逻辑相关的, 根据提供方和服务消费方的业务设计对应的接口和实现层。
- 配置层(Config): 对外面配置接口, 以`ServiceConfig`和ReferenceConfig为中心, 可以直接new配置类, 也可以通过spring解析成配置生成配置类。
- 服务代理层(Proxy): 服务接口透明代理, 生成服务的客户端Stub和服务器端Skeleton, 以ServiceProxy为中心, 扩展解扣子为ProxyFactory
- 服务注册层(Registry): 封装服务地址的注册和发现, 以服务URL为中心, 扩展接口为RegistryFactory, Registry和RegistryService。可能没有注册服务中心, 此时服务提供方直接暴露服务
- 集群层(Cluster): 封装多个提供者的路由及负载均衡, 并桥接注册中心。以`invoker`为中心, 扩展接口为Cluster, Directory, Router, 和LoadBalance。将多个服务提供方组合为一个服务提供方, 实现对服务消费方透明, 只需要与一个服务提供方进行交互。
- 监控层(Monitor): RPC调用次数和调用时间监控, 以Statistics为中心, 扩展接口为MonitorFactory, Monitor和MonitorService
- 远程调用层(Protocol): 封装RPC调用, 以`Invocation`和`Result`为中心, 扩展接口为`Protocol`,`invoker`和`Exporter`。
  - `Protocol`是服务域, 它是`Invoker`暴露和引用的主功能入口。它负责`Invoker`的生命周期管理
  - `Invoker`是实体域, 它是Dubbo的核心模型，其他模型都向它靠拢, 或转换成它，它代表一个可执行体，可想它发起invoke调用，它有可能是一个本地的实现, 也可能是一个远程的实现, 也可能是一个集群实现。
- 信息交换(Exchange): 封装请求响应模式, 同步转一部, 以`Request`和`Response`为中心, 扩展接口为`Exchanger`, `ExchangeChannel`,`ExchangeClient`和`ExchangeServer`
- 网络传输层(Transport): 抽象mina和netty为统一接口，以Message为中心, 扩展接口为`Channel`,`Transporter`,`Client`,`Server`,`Codec`
- 数据序列化层(Serialize): 可复用一些工具, 扩展成为`Serialization`,`ObjectInput`,`ObjectOutput`和`ThreadPool`

## 各层的关系
- 在RPC中 ， Protocol是核心层, 也就是只要有Protocol + Invoker + Exporter就可以完成非透明的RPC调用, 然后在Invoker的主过程上Filter拦截点
- 图中的Consumer和Provider是抽象概念, 只是想让看图者直观的了解哪些类分属于客户端和服务器端, 不用Client和Server的原因是Dubbo在很多场景下都是用Provider和Consumer,Registry, Monitor划分逻辑拓扑节点, 保持统一概念
- 而Cluster是外围概念, 所以Cluster的目的是将多个Invoker伪装成一个Invoker, 这样其他人只要关注Protocol层Invoker即可。加上Cluster或者去掉Cluster对其它层不会造成影响, 因为只有一个提供者时, 是不需要Cluster的
- Proxy层封装了所有接口的透明化处理, 而在其他层都以Invoker为中心, 只有到了暴露给用户使用时, 才是用Proxy将Invoker转成解接口, 或将接口实现成Invoker, 也就是去掉Proxy层RPC是可以执行的, 只是不那么透明, 不那么看起来像调用本地服务
- 而Remoting实现是Dubbo协议的实现, 如果选择RMI协议, 整个Remoting都不会用上，Remoting内部再划为Transport传输层和Exchanger信息交换层。Transport 层只负责单项消息传输，是对`Mina`,`Netty`,`Grizzly`的抽象, 它也可以扩展UDP传输, 而Exchange层是在传输层上封装了Request-Response语义
- Registry和Monitor实际上不算一层, 而是一个独立的节点， 只是为了全局概览, 用层的方式花在一起

## Dubbo核心要点
### 服务的定义
服务是围绕服务提供方和消费方的, 服务提供方实现服务，而服务消费方调用服

### 服务注册
服务提供方, 它需要发布服务, 而且由于应用系统的复杂性, 服务的数量，类型也不断膨胀; 对于服务消费方, 它最关心如何规划获取它所需要的服务。而面对复杂的应用系统，需要管理大量的服务调用。而且，对于服务提供方和服务消费方来说, 他们还有可能兼具这两种角色，即既需要提供服务，又需要消费服务。
 通过将服务同意管理起来, 可以有效地优化内部应用对服务器fabu/使用的流程和管理。服务注册中心可以通过特定协议来完成服务对外的同意。Dubbo提供的注册中心有如下几种类型可供选择:
 - Multicast 注册中心
 - Zookeeper注册中心
 - Redis注册中心
 - Simple注册中心

### 服务监控
服务提供方, 还是服务消费方, 他们都需要对服务调用的实际状态进行有效的监控, 从而改进服务质量。

### 远程通信与信息交换
远程通信需要指定双方所约定的协议, 在保证通信双方协议语义的基础上, 还需要保证高效, 稳定的消息传输。Dubbo继承了当前主流的通信网络框架, 主要包括如下几个:
- Mina
- Netty
- Grizzly

## 服务调用
