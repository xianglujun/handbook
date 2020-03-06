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



## 存储状态

`StatefulSet`对存储状态的管理机制, 主要使用`Persistent Volume Claim`功能实现。



### Persistent Volume Claim(PVC) 和 Persistent Volume(PV)

这种声明Volume的方式，降低了用户声明和使用持久化Volume的门槛。

**第一步: 定义PVC, 声明想要的Volume属性**

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pv-claim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

> 在这个声明之中， storage:1Gi 表示这个Volume大小至少是1GiB.
>
> `accessModes: ReadWriteOnce` 表示这个Volume的关在方式是可读写，并且只能被挂载在一个节点上而非多个共享节点。

**第二步: 在应用Pod中，声明使用这个PVC**

```yaml

apiVersion: v1
kind: Pod
metadata:
  name: pv-pod
spec:
  containers:
    - name: pv-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: pv-storage
  volumes:
    - name: pv-storage
      persistentVolumeClaim:
        claimName: pv-claim
```

#### PV对象

```yaml

kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv-volume
  labels:
    type: local
spec:
  capacity:
    storage: 10Gi
  rbd:
    monitors:
    - '10.16.154.78:6789'
    - '10.16.154.82:6789'
    - '10.16.154.83:6789'
    pool: kube
    image: foo
    fsType: ext4
    readOnly: true
    user: admin
    keyring: /etc/ceph/keyring
    imageformat: "2"
    imagefeatures: "layering"
```

对比`PVC`和`PV`两个对象，我们可以理解为`PVC`只是对Volume进行了声明，而具体使用哪一个Volume，则是需要由`PV`来定义。这就好比`接口和实现`的思想。

也正是因为`PVC`和`PV`两个对象的存在，使得`StatefulSet`的存储状态成为可能。



### 具体实例

```yml

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
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
```

该StatefulSet额外添加了一个`volumeClaimTemplates`字段。方式被这个`Stateful`管理的Pod, 都会声明一个对应的`PVC`；而这个`PVC`的定义，就来自于`volumeClaimTemplates`这个模板字段。



这个自动创建的PVC, 与PV绑定成功之后，就会进入Bound状态，这就意味着这个Pod可以挂在使用这个PV了。



> **`PVC其实就是一种特殊的Volume`, 只不过一个PVC具体是什么类型的Volume，要在跟某个PV绑定之后才知道**



## 工作原理

1. StatefulSet的控制器直接管理的是Pod. 

这是因为，StatefulSet里的不同Pod势力，不再像ReplicaSet中那样都是完全一样的，而是有了细微的区别。比如，每个Pod的hasname, 名字等都是不同的，携带了编号的。而StatefulSet区分这些实例的方式，就是通过在Pod的名字里加上事先约定的编号。

2. Kubernetes通过Headless Service，为这些有编号的Pod，在DNS服务器中生成带有同样编号的DNS记录。
3. `StatefulSet`还为每一个Pod分配并创建一个同样编号的`PVC`

这样, Kubernetes就可以通过`Persistent Volume`机制为这个`PVC`绑定上对应的`PV`, 从而保证了每一个Pod都拥有独立的`Volume`.