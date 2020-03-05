# StatefulSet

## 设计思想

得益于`控制器模式`的设计思想，Kubernetes项目很早就在Deployment基础上，扩展出了对`有状态应用`的初步支持。这个编排功能，就是`StatefulSet`



`StatefulSet`的设计思想其实非常容器理解，它把真实世界里的应用状态，抽象为两种情况：

- `拓扑状态`: 这种情况意味着，应用的多个实例之间不是完全对等的关系。
  - 这些应用实例，必须按照某些顺序启动，比如应用的主节点A要先于从节点B启动。而如果你把A和B两个Pod删除，他们再次被创建出来时也必须严格哪找这个顺序启动才行。
  - 新创建出来的Pod, 必须和原来的Pod的网络标识一样，这样原先的访问者才能使用同样的方法，访问到这个新Pod
- `存储状态`: 这种情况以为这多个实例分别绑定了不同的存储数据。
  - 对于这些应用实例来说，Pod A第一次读取到的数据，和隔了十几分钟之后再次读取到的数据，应该是同一份, 那怕Pod A被重新创建过
  - 最典型例子，就是一个数据库应用的额多个存储实例

## StatefulSet 核心功能

`就是按照某种方式记录这些状态，然后在Pod被重新创建时，能够为新Pod恢复这些状态`



## Headless Service

### 什么是Headless Service

`Service`是Kubernetes项目中用来将一组Pod暴露给外界访问的一种机制。例如，一个`Deployment`有3个Pod，那么我就可以定义一个Service，然后用户只要能访问到这个Service, 他就能访问具体的Pod.

### Service访问方式

- 以Service 的`VIP`(Virtual IP 即: 虚拟IP)方式。(`Normal Service 处理方式`)
  - 例如: 当我访问10.0.23.1这个Service的IP地址时，10.0.23.1其实就是一个VIP, 他会把请求转发到该Service所代理的某个Pod上。
  - 访问`my-svc.my-namespace.svc.cluster.local`解析到的，正是my-svc这个Service的VIP
- 以Service的`DNS`方式 (`Headless Service 处理方式`)
  - 例如: 只要我访问`my-svc.my-namespace.svc.cluster.local`这条DNS, 就可以访问到`my-svc`的Service所代理的某一个Pod
  - 这种情况下，你访问`my-svc.my-namespace.svc.cluster.local`解析到的，直接就是 my-svc 代理的某一个 Pod 的 IP 地址

> 两者区别在于，`Headless Service`不需要分配一个VIP， 而是可以直接以DNS记录的方式解析出被代理Pod的IP地址

### Headleass Service 创建

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
```

> 所谓`Headless Service`，其实仍是一个标准Service的YAML文件，只不过，它的`clusterIP`字段的值时`None`



