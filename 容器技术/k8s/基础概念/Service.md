# Service

Kubernetes 也遵循了常规的负载均衡器的做法, 运行在每个Node上的kube-proxy进程其实也就是一个只能的软件负载均衡器, 它负责把对Service的请求转发到后端的某个Pod实例上, 并在内部实现服务的负载均衡与会话保持机制。



## Cluster IP

Service不是共用一个负载均衡器的IP地址, 而是每个Service分配了一个全局唯一的虚拟IP地址, 这个虚拟IP被称为_Cluster IP_.

这样一来, 每个服务器就变成了具备唯一IP地址的"通信节点", 服务调用就变成了最基础的TCP网络通信问题。

Pod的Endpoint地址会随着Pod的销毁和重新创建而发生变化, 因为新Pod的IP地址与之前旧Pod的不同。 而_Service_一点被创建, kubernetes 就会自动为它分配一个可用的_Cluster IP_. 而且在Service的整个生命周期内, 它的_Cluster IP_不会发生改变.



## 多Endpoint

k8s Service 支持多个_Endpoint_, 在存在多个_Endpoint_的情况下, 要求每个_endpoint_定义一个名字来区分

```yaml
apiVersion: v1
kind: Service
metadata:
	name: tomcat-service
spec:
	ports:
	- port: 8080
	name: service-port
	-port: 8005
	name: shutdown-port
	selctor:
		tier: frontend
```

## 服务发现机制

- 每个k8s中的Service都有一个唯一的_Cluster IP_及唯一的名字, 而名字是由开发者自己定义的, 部署时也没要改变。
- 在早期的实现中采用的"环境变量"注入的方式实现
- 目前采用_add-on_增值包的方式引入DNS系统, 把服务名作为DNS域名， 这样程序就可以直接使用服务名来建立通信链接了。

## 外部系统访问Service

K8s中一共包含了三种IP地址:

- Node IP: Node节点的IP地址
- Pod IP: Pod的IP地址
- Cluster IP: Service的IP地址



_Node IP_是k8s急群众每个节点的物理网卡的IP地址，这是一个真实存在的物理网络，所有属于这个网络的服务器之间都能通过这个网络直接通信。 不管它们中是否有部分节点属于这个k8s集群。这也表明了k8s集群之外的节点访问k8s集群之内的某个节点或者_TCP/IP_服务时, 必须要通过Node IP进行通信。



_Pod IP_  : 是每个Pod的IP地址， 他是Docker Engine 根据docker0网桥IP地址段进行分配的, 通常是一个虚拟的二层网络。



_Cluster IP_: 它是一个虚拟的IP，但更像是一个伪造的IP网络:

- Cluster IP仅仅用作K8s Service这个对象, 并由k8s管理和分配IP地址(_来源于Cluster IP 地址池_)
- Cluster IP无法被PING, 因为没有一个"实体网路对象"来响应
- Cluster IP 只能结合Service Port组成一个具体的通信端口, 单独的Cluster IP不具备TCP/IP通信的基础, 并且他们属于k8s集群这样一个封闭的空间，集群之外的节点如果要访问这个通信端口, 则需要一些额外的工作
- 在k8s集群之内， Node IP 网， Pod IP网与Cluster IP网之间的通信，采用的是k8s自己设计的一种编程方式的特殊路由规则， 与我们熟知的IP路由有很大的不同

```yaml
apiVersion: v1
kind: Service
metadata:
	name: tomcat-service
	spec:
		type: NodePort
	ports:
	- port: 8080
	  nodePort: 31002
	selector:
		tier: frontend
```

_NodePort_ 的实现方式是在K8s集群里的每个Node上为需要外部访问的Service开启一个对应的TCP监听端口, 外部系统只要在任意一个Node的IP地址+具体的NodePort端口号即可访问此服务。

