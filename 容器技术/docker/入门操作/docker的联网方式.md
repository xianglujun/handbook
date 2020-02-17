# docker的联网方式
## docker网络栈
第一种方法涉及Docker自己的网络栈, 容器的服务在本地Docker宿主机所在的外部网络上公开

## docker内部网络
在安装Docker时, 会创建一个新的网络接口, 名字是`docker0`. 每个Docker容器都会在这个接口上分配一个IP地址。
- docker0 是一个一台网桥，用于连接容器和本地宿主网络

> NOTE: Docker自1.5.0版本开始支持IPV6, 要启动这一功能, 可以在运行Docker守护进程时加上`--ipv6`

- Docker每创建一个容器就会创建一组互联的网络接口。这组接口就像管道的两端。
- 这组接口其中一端作为容器里的`eth0`接口, 而另一端统一命名为类似`vethec6a`这种名字, 作为宿主机的一个端口。
- 该网口链接到了`docker0`虚拟网桥上

## Docker Networking
- 容器之间的网络联机用网络创建, 这被称作`Dokcer Networking`, 该功能是在`Docker 1.9`之后引入
- Docker Networking 允许用户创建自己的网络, 容器可以通过这个网上互相通信
- `docker network create app`创建一个网络
- `docker network ls` 查看所有的网络列表
- `docker run -d --net=app --name db test/test` 使用创建的网络
- `docker network inspect app` 查看原始数据信息
- `app`网络是内部启动的, 因此Docker将会感知到所有在这个网络下运行的容器, 并通过`/etc/hosts`文件将这些容器地址保存到本地DNS中
- `docker network connect 网络名称 容器名` 用于将容器链接到某个网络
- `docker network disconnect 网络名称 容器名称` 用于断开容器的网络
- `--icc=false`可以强制docker只允许有链接的容器之间通信
- `--add-host`选项, 也可以在`/etc/hosts`文件中添加相应记录
  - `docker run -p 4567 --add-host=docker:10.0.0.1 --name webapp2 --link redis:db` 在`/etc/hosts`文件中添加一个名为`docker`和`10.0.0.1`的宿主机记录

## 使用容器链接通信
有两种方式让应用程序链接到应用:
- 使用环境变量里的一些链接信息
- 使用`DNS`和`/etc/hosts`信息
