# StatefulSet

在k8s系统中, Pod的管理对象RC, Deployment, DaemonSet 和 Job都是面向无状态的服务。但现实中有很多服务是有状态的， 特别是一些复杂的中间件集群。这些中间件集群有以下一些共同点:

- 每个节点都有固定的身份ID， 通过这个ID， 集群中的成员可以相互发现并且通信
- 集群的规模是比较固定的，集群规模不能随意变动
- 集群里的每个节点都是有状态的, 通常会持久化数据到永久存储中
- 如果磁盘损坏， 则集群里的某个节点无法正常运行, 集群功能受损



## StatefulSet的特性

- StatefulSet 里的每个Pod都有稳定唯一的网络标识, 可以用来发现集群内的其他成员。
- StatefulSet 控制的Pod副本的启停顺序是受控的。操作第n个Pod时, 前 n-1个Pod已经是运行且准备好的状态
- StatefulSet 里的Pod采用稳定的持久化存储券, 通过_PV/PVC_来实现，删除Pod时默认不会删除与StatefulSet相关的存储卷

## Headless Service

StatefulSet 除了要与PV卷捆绑使用以存储Pod的状态数据, 还要与Headless Service配合使用，即在每个StatefulSet 的定义中要声明它属于哪个_Headless Service_.



_Headless Service_与普通Service的区别在于，它没有_ClusterIp_, 如果解析Headless Service的DNS域名, 则返回的是该Service对应的全部Pod的Endpoint列表. 



_StatefulSet Service_在_Headless Service_的基础上又为_StatefulSet_控制的每个Pod实例创建一个DNS域名, 这个域名格式为：

```kubernetes
${podname}:${headless service name}
```

