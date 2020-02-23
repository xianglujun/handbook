# Service Account

## 作用

Service Account对象的作用，就是Kubernetes系统内置的一种"账户服务"， 它是Kubernetes进行权限分配的对象。

像这样的Service Account的授权信息和文件, 实际上保存在它所绑定的特殊的Secret对象里的。这个特殊的Secret对象，就叫做**`ServiceAccountToken`**. 任何运行在Kubernetes集群上的应用, 都必须使用这个ServiceAccountToken里保存的授权信息，也就是Token, 才可以合法地访问API Server。



> 为了方便使用, Kubernetes已经为你提供了一个默认的`服务账户`. 并且，任何一个运行在kubernetes里的Pod, 都可以直接使用这个默认的Service Account, 而无需显示地声明挂载它。

> **这种把kubernetes客户端以容器的方式运行在集群里, 然后使用default Service Account自动授权的方式, 被称作"InClusterConfig", 也是最推荐进行Kubernetes API 编程的授权方式**