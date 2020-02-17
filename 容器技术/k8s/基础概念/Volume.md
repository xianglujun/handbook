# Volume

Volume 是Pod中能够被多个容器访问的共享目录。k8s中的Volume概念，用途和目的与Docker的Volume比较类似，但两者不能等价。

- k8s中的Volume定义在Pod上，然后被一个Pod里的多个容器挂载到具体的文件目录下
- K8s中的volume与Pod的声明周期相同, 但于容器的声明周期不想管, 当容器终止或者被重启时, Volume中的数据不会丢失
- K8s支持多种类型的Volume