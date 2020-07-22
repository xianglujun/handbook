# 声明式AP

## 声明式API工作原理

在Kubernetes项目中，一个API对象在Etcd里的完整资源路径，是由: `Group`, `Version`, `Resource`三个部分组成。



### Kubernetes对Resource, Group 和Version 解析

#### Kuberntes会匹配API对象的组

> 需要明确的是，对于Kubernetes里的核心API对象，比如： `Pod`, `Node`等，是不需要Group的， 所以，对于这些API对象来说，Kubernetes会直接在`/api`这个层级进行下一步的匹配过程。

对于非核心API对象来说，Kubernetes就必须在`/apis`这个层级里查找它对应的Group, 进而根`batch`这个Group名字，找到`/apis/batch`



#### Kubernetes会进一步匹配到API对象的版本号

在Kubernetes中，同一种API对象可以有多个版本，这正是Kubernetes进行API版本话管理的重要手段，这样，比如在CronJob的开发过程中，对于会影响到用户变更就可以通过升级新版本来处理，从而保证了向后兼容。

#### Kubernetes会匹配到API 对象的资源类型。

在前面匹配到正确的版本之后，Kubernetes就知道，我要创建的原始是一个`/apis/batch/v2alpha1`下的CronJob对象。

![img](./df6f1dda45e9a353a051d06c48f0286f.png)

- 首先，我们发起了创建`CronJob`的Post请求之后，我们编写的YAML的信息就被提交给了`APIServer`. 而`APIServer`的第一个功能，就是过滤这个请求，并完成前置工作，例如`授权`, `超时处理`, `审计`等。
- 然后，请求会进入`MUX`和`Routes`流程。该处理主要完成URL和Handler绑定的场所。而APIServer的Handler要做的事情，就是按照我刚刚介绍的匹配过程，找到对应的CronJob类型定义。
- 根据CronJob类型定义，使用用户提交的YAML文件里的字段，创建一个CronJob对象。
  - APIServer会进行一个Convert工作，把用户提交的YAML文件，转换成一个叫做`Super Version`的对象，它正式该API资源类型所有版本的字段全集。这样用户提交的不同版本的YAML文件，就都可以用这个`Super Version`对象来进行处理。
- APIServer会先后进行`Admission()`和`Validation()`操作。
  - `Admission`则是在创建资源时，能够新增自定义属性内容，提供对资源增强操作
  - `Validation`: 负责验证这个对象里的各个字段是否合。这个被验证过的API对象，都保存在了APIServer里一个叫做`Registry`的数据结构中。也就是说，只要一个API对象的定义能在`Registry`里查到，它就是一个有效的`Kubernetes API`
- APIServer会把验证过的API对象转换成用户最初提交的版本，进行序列化操作，并调用ETCD的API把它保存起来。