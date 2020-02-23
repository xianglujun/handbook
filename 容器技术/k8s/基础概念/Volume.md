# Volume

Volume 是Pod中能够被多个容器访问的共享目录。k8s中的Volume概念，用途和目的与Docker的Volume比较类似，但两者不能等价。

- k8s中的Volume定义在Pod上，然后被一个Pod里的多个容器挂载到具体的文件目录下
- K8s中的volume与Pod的声明周期相同, 但于容器的声明周期不想管, 当容器终止或者被重启时, Volume中的数据不会丢失
- K8s支持多种类型的Volume

## ProjectVolume(投射数据卷)

在Kubernetes中, 有几种特殊的Volume, 他们存在的意义不是为了存放容器里的数据， 也不是用来进行容器和宿主机之间的数据交换。这些特殊Volume的作用, 是为了容器提供预先定义好的数据。所以, 从容器角度来看, 这些volume里的信息就是仿佛是被Kubernetes`投射`(Project)进入容器当中的。



Kubernetes支持的Projected Volume一共有四种：

- Secret
- ConfigMap
- Downward API
- ServiceAccountToken

### Secret

Secret的作用，是帮你把Pod想要访问的加密数据, 存放到Etcd中。然后可以通过Pod的容器里挂载Volume的方式, 访问到这些Secret里保存的信息。



`Secret`最典型的使用场景, 莫过于存放数据库的Credential信息, 比如:

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: test-projected-volume
spec:
	containers:
	- name: test-secret-volume
	  image: busybox
	  args:
	  - sleep
	  - "86400"
	  volumeMounts:
	  - name: mysql-cred
	    moutPath: "/projected-volume"
	    readOnly: true
	volumes:
	- name: mysql-cred
      projected:
      	sources:
      	- secret:
      		name: user
      	- secret: pass
```

> 在这个Pod中, 声明挂载的Volume并不是常见的`emptyDir`或者`hostPath`类型，而是`projected`类型。而Volume的数据来源, 则是名为`user`和`pass`的Secret对象, 分别对应的是数据库的用户名和密码。

```sh
echo "admin" > username.txt
echo "c1oudc0w!" > password.txt

kubectl create secret generic user --from-file=username.txt
kubectl create secret generic pass --from-file=password.txt
```

当然也可以通过yaml的方式创建Secret对象:

```yaml
apiVersion: v1
kind: Secret
metadata:
	name: mysecret
type: Opaque
data:
	user: YWRtaW4=
	pass: MWYyZDFlMmU2N2Rm
```

> 对于Secret中存储的数据, 必须经过`Base64`转码, 以免出现明文密码的安全隐患。



我们尝试创建这个Pod:

```yaml
kubectl create -f test-projected-volume.yaml
```

> 可以通过进入Container， 查看Secret是否已经挂载到容器之中。 这些密码信息是以`文件形式`出现在Volume目录里面。

> 通过挂载方式进入到容器里的Secret, 一旦其对应的Etcd里的数据被更新, 这些Volume里的文件内容，也会同样被更新(如果执行的删除操作, 对应的文件不会被删除). **`这是Kubelet组件在定时维护这些Volume`**

**更新会有一定的延迟, 所以在编写程序时, 在发起数据库连接的代码处写好重试和超时的逻辑, 是很有必要的。**



### ConfigMap

ConfigMap保存的是不需要加密的, 应用所需的配置信息。而ConfigMap的用法几乎与Secret 完全相同: 可以通过`kubectl create configmap `从文件或者目录创建ConfigMap, 也可以直接编写ConfigMap对象的YAML文件.

```properties
# .properties文件的内容$ cat example/ui.properties
color.good=purple
color.bad=yellow
allow.textmode=true
how.nice.to.look=fairlyNice
```

```sh
kubectl create configmap ui-config --from-file=example/ui.properties

# 查看这个configmap里保存的信息(data)
kubectl get configmap ui-config -o yaml
```



### Downward API

它的作用是：`让Pod里的容器能够直接获取到这个Pod API对象本身的信息`

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: test-downwardapi-volume
	labels:
		zone: us-est-coast
		cluster: test-culster1
		rack: rack-22
spec:
	containers:
	- name: client-container
	  image: busybox
	  command: ['sh', '-c']
	  args:
	  - while true; do
	  		if [[-e /etc/podinfo/labels ]]; then
	  			echo -en '\n\n'; cat /etc/podinfo/labels; fi;
	  		sleep 5;
	  	done;
	  volumeMounts:
	  - name: podinfo
	  	mountPath: /etc/podinfo
	  	readOnly: false
	volumes:
	- name: podinfo
	  projected:
	  	sources:
	  	- downwardAPI:
	  	    items:
	  	      - path: "labels"
	  	        fieldRef:
	  	          fieldPath: metadata.labels
```

> 该容器声明了一个`projected`类型的Volume, 只不过这次Volume的数据来源变为了`DownwardAPI`.而这个Volume, 则声明了要暴露的Pod的`metadata.labels`信息给容器。

> 通过这种声明方式, 当前Pod的Labels字段的值, 就会被Kubernetes自动关在成为容器里的`/etc/podinfo/labels`文件。

目前`DownwardAPI`支持的字段如下:

- fieldRef
  - spec.nodeName - 宿主机名字
  - status.hostIP - 宿主机IP
  - metadata.name - Pod的名字
  - metadata.namespace - Pod的namespace
  - status.podIP - Pod的IP
  - spec.serviceAccountName - Pod的Service Account的名字
  - metadata.uid - Pod的UID
  - metadata.labels['<KEY>'] - 指定<KEY>的Label值
  - metadata.annotations['<KEY>'] - 指定<KEY>的Annotation值
  - metadata.labels - Pod的所有Label
  - metadata.annotations - Pod的所有Annotation
- 使用resourceFieldRed 可以声明使用
  - 容器CPU limit
  - 容器CPU request
  - 容器 memory limit
  - 容器 memory request

> Downward API能够获取到的信息, 一定是Pod里的容器进程启动之前就能确定下来的信息。如果想要获取Pod运行后才出现的信息, 就应该考虑定义一个`sidecard`容器。

