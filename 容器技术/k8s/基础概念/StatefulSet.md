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

> 所谓`Headless Service`，其实仍是一个标准Service的YAML文件，只不过，它的`clusterIP`字段的值时`None`. 所以这个Service被创建后并不会被分配到一个VIP。而是以DNS记录的方式暴露出锁代理的Pod

### 如何关联Pod

而它所代理的Pod, 依然采用`Label Selector`机制选择出来。然后通过`selector`与Pod进行关联。

当你按照这样的方式创建了一个`Headless Service`之后，它所代理的所有Pod的IP地址，都会被绑定一个这样格式的DNS记录

```txt
<pod-name>.<svc-name>.<namespace>.svc.cluster.local
```

这个DNS记录，正式Kubernetes项目为Pod分配的唯一的`可解析身份`

## StatefulSet 通过DNS维持Pod拓扑状态

### 创建StatefulSet

```yaml

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 2
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
        image: nginx:1.9.1
        ports:
        - containerPort: 80
          name: web
```

- `serviceName=nginx`: 该字段就是为了告诉`StatefulSet`控制器，在执行控制循环的时候，请使用这个`Headless Service`来保证Pod的`可解析身份`.

当通过`kubectl create `的方式创建了上面这个`Service`和`StatefulSet`之后，就就汇看到如下两个对象：

```shell
# 创建Headless Service
kubectl create -f svc.yaml
kubectl get service nginx

# 创建并查看statefulset
kubectl create -f statefulset.yaml
kubectl get statefulset web

# 监控Pod的执行状态
kubectl get pods -w -l app=nginx
```

通过上面这个Pod的创建过程，可以看出，`StatefulSet`给它所管理的所有Pod的名字，进行了编号，编号规则是：`-`

而且这些编号都是从0开始累加，与StatefulSet的每个Pod实例一一对应, 绝不重复。

### 查看`hostname`

```sh
kubectl exec web-0 -- sh -c 'hostname'

kubectl exec web-0 --sh -c 'hostname'
```

### 验证解析规则是否正确

```sh
kubectl run -i --tty --image busybox:1.28.4 dns-test --restart=Never --rm /bin/sh

## 进入容器后，通过nslookup查看
nslookup web-0
```

> 注意: 在StatefulSet使用中，如果希望能够解析DNS, 需要启动`Headless Service`以及`StatefulSet`两个对象，否则在解析`nslookup`是，可能出现`nslookup: can't resolve 'web-0.nginx'`

### Stateful 执行原理

当我们尝试将`有状态应用`的Pod删除掉的时候:

```sh
kubectl delete pod -l app=nginx
```

可以看到，当我们把两个Pod删除之后，Kubernetes会按照原先编号的顺序，创建出了两个新的Pod。并且，Kubernetes依然为他们分配了与原来相同的`网络身份`.`web-0.ngixn`和`web-1.nginx`

通过这种严格的对应规则，***`StatefulSet就保证了Pod网络标识的稳定性`***



通过这种方式, `Kubernetes就成功地将Pod的拓扑状态(比如: 哪个节点先启动，哪个节点后启动)，按照Pod的"名字+编号"的方式固定了下来`, 同事还为每一个Pod提供了一个固定并且唯一的访问入口：`即这个Pod对应的DNS记录`

这些状态，在`StatefulSet`的整个生命周期里都会保持不变，绝不会因为对应Pod的删除或者重新创建而失效。



> NOTE: 尽管`web-0.nginx`这条记录本身不会变，但它解析到的Pod的IP地址，并不是固定的。