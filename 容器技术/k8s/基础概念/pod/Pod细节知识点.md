# Pod相关知识点

### 为什么Pod必须是原子调度单位

- 举例：两个容器紧密协作
  - App: 业务容器，写日志文件
  - LogController: 转发日志文件到ElasticSearch中
- 内存要求:
  - App: 1G
  - LogController: 0.5G
- 当前可用内存：
  - Node_A: 1.25G
  - Node_B: 2G
- 如果App最先被调度到`Node_A`上，将会导致`LogController`最终调度失败
- `Task co-scheduling`问题
  - Mesos: 资源囤积(resource hoarding)
    - 所有设置了`Affinity`约束的任务都到达时，才开始统一调度
    - `缺陷`: 调度效率损失和死锁
  - Google Omega: 乐观锁处理冲突
    - 先不管这些冲突，而是通过精心设计调度机制，在出现问题之后解决问题(`乐观锁`)
    - `缺陷`：复杂
  - Kubernetes: Pod

## 再次理解Pod

- 亲密关系 - `调度解决`
  - 两个应用需要运行同一台宿主机上
- 超亲密关系 - `Pod解决`
  - 会发生直接的文件交换
  - 使用`localhost`或者`Socket`文件进行本地通信
  - 会发生非常频繁的`RPC`调用
  - 会共享某些`linux Namespace`（比如，一个容器需要加入另一个容器的`Network Namespace`）

## Pod的实现机制

 ### Pod要解决的问题

- 共享网络
  - 容器A和容器B
    - 通过`Infra Container`的方式共享同一个`Network Namespace`
      - 镜像`k8s.gcr.io/pause`, 汇编语言编写的，用于处于`暂停`：大小1--0200kb
    - 通过使用`localhost`进行通信
    - 看到的网络设备跟`infra`容器看到的完全一样
    - 一个`Pod`只有一个`IP`地址，也就是这个`Pod`的`Network Namespace`对应的IP地址
      - `所有网络资源，都是一个Pod一份，并且被该Pod种所有容器共享`
    - 整个Pod的声明周期跟`Infra`容器一致，而与容器`A`和`B`无关。
- 共享存储
  - 通过`hostPath`挂载的方式，在对应宿主机上的目录被同时`绑定挂在`进了上述两个容器当中

## 容器设计模式

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: javaweb-2
spec:
    initContainers:
    - image: resource/simple:v2
      name: war
      command: ["cp", "/simple.war", "/app"]
      volumeMounts:
      - mountPath: /app
        name: app-volume
     containers:
     - image: resouces/tomcat:7.0
       name: tomcat
       command: ["sh", "-c", "/root/apache-tomcat-7.0.42-v2/bin/start.sh"]
       volumeMounts:
       - mountPath: /root/apache-tomcat-7.0.42-v2/webapps
         name: app-volume
         ports:
         - containerPort: 8080
           hostPort: 8001
      volumes:
      - name: app-volume
        emptyDir: {}
```



- InitContainer
  - `InitContainer`回比`spec.containers`定义的用户容器先启动，并且严格按照定义顺序依次执行
  - `/app`是一个`Volume`
  - Tomcat容器，同样声明了挂在该Volume到自己的`webapps`目录下
  - 故当tomcat容器启动时，它的`webapps`目录下就一定会存在`simple.war`文件。

### Sidecar

- 通过在Pod里定义专门容器，来执行主业务容器需要的辅助工作
  - 比如:
    - 原本需要SSH进去执行的脚本
    - 日志收集
    - Debug应用
    - 应用监控
  - 优势:
    - 将辅助功能同主业务容器解耦，实现独立发布和能用重用

#### Sidecar: 应用与日志搜集

- 业务容器将日志写在Volume里
- 日志容器共享该Volume从而将日志转发到远程存储当中
  - `Fluentd`等

#### Sidecar: 代理容器

- 代理容器对业务容器屏蔽被代理的服务集群，简化业务代码的实现逻辑
  - 容器之间通过lcoalhost直接通信(`没有性能损耗`)
  - 代理容器的代码可以被全公司重用

#### Sidecar: 适配器容器

- 适配器容器将业务容器暴露出来的接口转换为另一种格式
- 举例:
  - 业务容器暴露出来的监控接口是`/metrics`
  - `Monitoring Adapter`将其转换为`/healthz`以适配新的监控系统
  - 提示：
    - 容器之间通过localhost通信
    - 代理容器的代码可以被全公司重用