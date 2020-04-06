# Pod 

尽管Pod拥有一个唯一的ip, 但是这些ip不会暴露给集群外部服务访问，因此我们需要创建一个_service_来让外部服务来访问。



服务暴露方式有以下几种：

- ClusterIP(default): 在集群内部通过内部IP访问，这种方式使服务只会接收来自集群内部的请求。
- NodePort: 在集群内部使用_NAT_的方式暴露服务，通过选择器形式，是的每个被选择的Node拥有同样的端口号.
- LoadBalance: 创建一个外部负载均衡器并且分配一个固定的外部IP，并与Service进行绑定
- ExternalName: 通过使用一个随意的名称暴露服务，这种方式通过返回一个_CNAME_记录信息。这种方式没有_proxy_使用，需要在_v1.7_或者更高版本中使用。

## Pod相关属性

### NodeSelector： 一个供用户将Pod与Node进行绑定的字段

```yam
apiVersion: v1
kind: Pod
spec: 
	NodeSelector:
		disktype:ssd
```

这样一个配置, 意味着这个Pod永远只会运行在携带了"distype:ssd"标签的节点; 否则调度将会失败。



### NodeName

一旦Pod的这个字段被赋值, Kubernetes项目就会认为这个Pod已经经过了调度, 调度的结果就是赋值的节点名字。所以, 这个字段一般由调度器负责设置, 但用户可以设置它来"骗过"调度器, 当然这个做法一般是在测试或者调试的时候才会用到。



### HostAliases

定义了Pod的hosts文件(比如`/etc/hosts`)里的内容,

```yaml
apiVersion: v1
kind: Pod
spec:
	hostAliases:
	- ip: "10.1.2.3"
	  hostnames:
	  - "foo.remote"
	  - "bar.remote"
```

这个Pod的 YAML文件中, 我设置了一组IP和hostname的数据。这样, Pod启动后，`/etc/hosts`文件内容将如下所示：

```hosts
10.244.135.10 hostaliases-pod
10.1.2.3 foo.remote
10.1.2.3 bar.remote
```

> 在kuberntes项目中, 如果要设置hosts文件里的内容, 一定要通过这种方法. 否则，如果直接修改了hosts文件的话, 在Pod被删除重建之后, kubelet会自动覆盖掉被修改的内容。



> 凡是跟容器的Linux Namespace相关的属性, 也一定是Pod级别的。Pod的设计，就是要让它里面的容器尽可能多地共享Linux Namespace，仅保留必要的隔离和限制能力。这样, Pod模拟出的效果，就跟虚拟机里程序间的关系非常类似了。



### 示例

```yaml
apiVersion: v1
kind: Pod
metadata:  
	name: nginx
spec:  
	shareProcessNamespace: true  
	containers:  
	- name: nginx    
	  image: nginx  
	- name: shell    
	  image: busybox    
	  stdin: true    
	  tty: true
```

在这个YAML文件中, 定义两个容器: 一个是nginx容器, 一个是开启了tty和stdin的shell容器.

> `tty`就是Linux给用户提供的一个常驻小程序, 用于接收用户的标准输入, 返回操作系统的标准输出。 当然为了能够在tty中输入信息, 还需要同时开启`stdin`

```sh
# 创建Pod
kubectl apply -f nginx.yaml

# 使用kubectl attach命令, 链接到shell容器的tty上:
kubectl attach -it nginx -c shell
```

```shell
/ # ps ax
PID   USER     TIME  COMMAND    
1 root      0:00 /pause    
8 root      0:00 nginx: master process nginx -g daemon off;   
14 101       0:00 nginx: worker process   
15 root      0:00 sh   
21 root      0:00 ps ax
```

> 可以看到, 在这个容器里, 我们不仅可以看到他本身的`ps ax`指令, 还可以看到nginx容器的进程, 以及infra容器的`/pause`进程。这就意味着, `整个Pod`里面的每个容器的进程, 对于所有容器来说都是可见的: 他们共享了同一个`PID Namespace`.

类似地: 凡是Pod中的容器要共享宿主机的Namespace, 也一定是Pod级别的定义, 比如:

```yaml
apiVersion: v1
kind: Pod
metadata:  
	name: nginx
spec:  
	hostNetwork: true  
	hostIPC: true  
	hostPID: true  
	containers:  
	- name: nginx    
	  image: nginx  
	- name: shell    
	  image: busybox    
	  stdin: true    
	  tty: true
```

## Container属性

Kubernetes项目中对Container的定义和Docker相比没有什么太大的区别。

### Image

### Command(启动命令)

### workdir(容器的工作目录)

### Ports(容器要开放的端口)

### volumeMounts(容器要挂载的Volumes)

### ImagePullPolicy

定义了镜像的拉去策略. 

- Always: 每次创建Pod都重新拉去一次镜像, 另外, 当容器镜像类似于`nginx`或者`nginx:lates`这样的名字时, `ImagePullPolicy`也会被认为Always.
- Never: Pod永远不会主动拉去镜像
- IfNotPresent: Pod只在宿主机上不存在这个镜像时才拉取。

### Lifecycle

定义了Container Lifecycle Hooks. 是在容器状态发生变化时, 出发一系列钩子

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: lefycycle-demo
spec:
	containers:
	- name: lifecycle-demo-container
	  image: nginx
	  lifycycle:
	  	postStart:
	  		exec:
	  			command:["/bin/sh", "-c", "echo Hello from the postStart handler"]
	  		preStop:
	  			exec:
	  				command: ["/usr/sbin/nginx", "-s", "quit"]
```



## Pod声明周期

Pod生命周期的变化, 主要体现在Pod API对象的`Status部分`, 这是它除了Metadata和Spec之外的第三个重要字段。 其中`pod.status.phase`就是Pod的当前状态, 它有如下几种可能:

- Pending: 这种状态意味着, Pod的YAML文件已经提交给了Kubenetes, API对象已经创建并保存在Etcd当中。但是, 这个Pod里有些容器因为某种原因不能被顺利创建。
- Running: 这个状态下, Pod已经调度成功， 跟一个具体的节点绑定。它包含的容器都已经创建成功，并且至少有一个正在运行中。
- Succeeded: 这个状态意味着, Pod里的所有容器都正常运行完毕，并且已经退出了。这种情况在`运行一次性任务时最为常见`.
- Failed: 这个状态下, Pod里至少有一个容器以不正常的状态(非0的返回码)退出。这个状态出现, 意味着你的想办法Debug这个容器的应用。
- Unkown: 这是一个异常状态，意味着Pod的状态不能持续地被kubelet汇报给kube-apiserver, 这很有可能是主从节点(Master和Kubelet)间的通信出了问题。

### Conditions

Pod对象的Status字段, 可以再细分出一组Conditions. 这些细分状态值包括：

- PodScheduled
- Ready：Pod不仅正常启动(Running)，而且已经可能对外提供服务了。Running和Ready之间是有区别的。
- Initialized
- Unschedulable

用于描述造成当前Status的具体原因。



## 容器健康检查和恢复机制

### 探针（Probe）- 健康检查(livenessProbe)

在kubernetes中, 你可以为Pod容器里的容器定义一个健康检查"探针"(Probe)。这样，kubelet就会根据这个Probe的返回值决定这个容器的状态，而不是直接以容器进行是否运行作为依据。这种机制, 是生产环境中保证应用健康存活的重要手段。

```yam
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: test-liveness-exec
spec:
  containers:
  - name: liveness
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

> Kubernetes中并没有Docker的Stop语义, 所以虽然是Restart, 但实际上是重新创建了容器

### 恢复机制

Kubernetes中的Pod恢复机制, 也叫做`restartPolicy`. 它是Pod的Spec部分的一个标准字段（`pod.spec.restartPolicy`）, 默认是`Always`, 即: `任何时候这个容器发生了异常, 它一定会被重复创建.`



然后Pod的恢复过程, 永远都发生在当前节点上，而不会跑到别的节点上去。事实上, 一旦一个Pod与一个节点(Node)绑定, 除非这个绑定发生变化(`pod.spec.node`字段被修改), 否则它永远都不会离开这个节点。这就意味着，如果这个宿主机宕机了，这个Pod也不会主动迁移到其他节点上。



> 如果希望Pod调度到其他的节点上，就需要使用Deployment.



- restartPolicy恢复策略
  - Always: 在任何情况下, 只要容器不在运行状态, 就自动重启容器
  - OnFailure: 只在容器异常时才自动重启容器
  - Never: 从来不启动容器

#### Pod策略原则

- **只要Pod的restartPolicy指定的策略允许重启异常的容器, 那么这个Pod就会保持`Running`状态, 并进行容器重启。**
- **对于包含多个容器的Pod, 只有它里面所有的容器都进入异常状态后, Pod才会进入`Failed`状态**



对于`livenessProbe`也可以发起HTTP或者TCP请求的方式， 定义格式如下:

```yaml
livenessProbe:
    httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
        - name: X-Custom-Header
          value: Awesome
        initialDelaySeconds: 3
        periodSeconds: 3
```

```yam

    ...
    livenessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
```



### 探针(Probe) - readinessProbe

虽然她的用法与`livenessProbe`类似， 但作用却大不一样。`readinessProbe`检测结果的成功与否, 决定的这个Pod是不是能被通过`Service`的方式访问到，而并不影响Pod的声明周期。



## 自动填充字段（PodPreset）

该功能在`v1.11`版本上已经出现, 主要用来预置Pod属性。

```yam
apiVersion: v1
kind: Pod
metadata:
  name: website
  labels:
    app: website
    role: frontend
spec:
  containers:
    - name: website
      image: nginx
      ports:
        - containerPort: 80
```

新增一个`PodPreset`类型, 用于对属性的预定义:

```yam

apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: allow-database
spec:
  selector:
    matchLabels:
      role: frontend
  env:
    - name: DB_PORT
      value: "6379"
  volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
    - name: cache-volume
      emptyDir: {}
```

> 该PodPreset定义中, `selector`决定了只会作用于select所定义的,带有`role:frontend`标签的Pod对象。

> ***PodPreset里定义的内容, 只会在Pod API对象被创建之前追加在这个对象身上, 而不会影响任何Pod的控制器的定义***

比如: 我们当前创建一个`nginx-deployment`，那么这个Deployment对象本身是永远不会被PodPreset改变的, 被修改的只是这个Deployment创建的所有的Pod.