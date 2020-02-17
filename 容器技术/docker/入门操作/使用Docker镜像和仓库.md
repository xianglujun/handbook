# 使用Docker镜像和仓库
> 注意: docker中的基础系统， 并不是一个完整的操作系统, 它只是一个裁剪版, 只包含最低限度的支持系统运行的组件。

## 区分统一仓库中的不同镜像.
- Docker提供一种标签`Tag`功能, 以区分不同版本的docker镜像， 这种机制可能保证同一个仓库中可以存储多个镜像。

### 仓库分类
- 用户仓库
  - 用户仓库的镜像都是由Docker用户创建的
- 顶层仓库
  - 顶层仓库则是由Docker内部的人来管理的

## 拉取风险
- `docker run`命令从镜像启动一个容器时, 如果该镜像不再本地, Docker会先从Docker Hub下载该镜像。
- 如果没有指定具体的镜像标签, 那么Docker会自动下载`latest`标签的镜像
- 也可以通过`docker pull`命令, 将镜像拉取到本地

## 查找镜像
`docker search`命令查找所有`Docker Hub`上公共的可用镜像。

该命令会查找所有的镜像列表, 并返回如下信息:
- 仓库名
- 镜像描述
- 用户评价(stars) - 反应出一个镜像受欢迎的程度
- 是否官方(Official) - 由上游开发者管理的镜像
- 自动构建(Automated) - 表示这个镜像是由Dockert Hub的自动构建流程创建的。

## 构建镜像
我们可以通过以下两种方式管理和更新docker镜像:
- 使用`docker commit`命令
- 使用`docker builder`命令和`Dockerfile`文件

### 登陆docker Hub
可以通过`docker login`操作, 用于登陆docker hub 对镜像进行管理

### docker commit 命令创建镜像
```sh
# 进入容器的bash操作
sudo docker run -i -t centos /bin/bash

# 在容器中安装一些预装的软件
yum -yqq update
yum -y install apache2

# 提交定制容器
sudo dockert commit 4aab3ce3cb76 jjjj/gggg

NOTE: docker commit 提交的只是创建容器的镜像与容器的当前状态之间有差异的部分, 这使得该更新非常轻

# 提交另外一个容器
sodu docker commit -m"A new custom image" -a"James Turnbull" 15c370ce7b87 docker/java_env:java_env
```

### 使用Dockerfile构建镜像
- 并不推荐使用`docker commit`的方法来构建镜像。
- 推荐使用`Dockerfile`的定义文件和`docker build`命令来构建镜像。
- Dockerfile 使用`DSL`语法的指令来构建Docker镜像

#### 第一个Dockerfile
```sh
FROM centos
MAINTAINER xianglj "xianglj1991@163.com"
# Dockerfile 中的内容
RUN yum upgrade && yum install -y nginx
RUN echo 'Hi, i am in you container' > /usr/share/nginx/html/index.html
EXPOSE 80
```
- Docker从基础镜像运行一个容器
- 执行一条指令, 对容器做出修改
- 执行类似docker commit 的操作, 提交一个新的镜像层
- Docker再基于刚提交的镜像运行一个新容器
- 执行Dockerfile中的吓一条指令, 直到所有指令都执行完成

### Dockerfile文件规范
- 每个`Dockerfile`的第一条指令必须是`FROM`, FROM指令指定一个已经存在的镜像, 后续指令都将基于该进行进行, 这个镜像被称为基础镜像
- 接着指定了`MAINTAINER`指令, 告诉Docker该镜像的作者是谁, 以及作者的电子邮件
- `RUN` 命令用来执行具体的指令. 上面的指令值, 更新了yun库并安装了nginx, 并创建了index.html文件. `每条RUN执行都会创建一个新的镜像层, 如果该指令执行成功, 就会将此镜像提交, 之后继续执行Dockerfile中的下调指令`
- 也可以使用`exec`格式的RUN指令: RUN ['yum', " install", "-y", "nginx"]
- 紧接着, 通过`EXPOSE`指令, 这条指令告诉Docker该容器内的应用程序将会使用容器的指定端口。`默认情况下, Docker并不会自动打开该端口, 而是需要用户在使用docker run 运行容器时来指定需要打开那些接口`

> NOTE: Docker 也使用EXPOSE指令来帮助将多个容器链接, 用户也可以在运行时以`docker run `命令通过`--expose`选项来指定对外部公开的端口

#### 构建docker镜像
```sh
# 从当前文件中加载Dockerfile文件
docker build -t="test/test" .

# 从git仓库的源地址来指定Dockerfile位置
docker buil -t="test/test" git@github.com:test/docker-static_web

# 从1.5之后, 可以指定文件名称, 不必一定为Dockerfile的名称
docker build -t="test/test" -f path/to/file
```

### Dockerfile和构建缓存
- 由于每一步的构建过程都会将结果提交为镜像, 所有Docker的构建镜像过程就显得非常聪明, 它将之前的镜像层看做缓存。
- docker会将之前构建时创建的镜像当做缓存并作为新的开始点.
- 可以通过`--no-cache`标志, 跳过docker使用缓存。

### 基于构建缓存的Dockerfile模板
- 构建缓存带来的一个好处就是, 可以实现简单的`Dockerfile`模板。
```sh
FROM ubuntu:14.04
MAINTAINER xianglj "xianglj1991@163.com"
ENV REFRESHED_AT 2019-09-19
RUN apt-get -qq update
```
- 通过环境变量`REFRESHED_AT`的环境变量, 这个环境变量用来表示镜像模板最后的更新时间。
- 如果想刷新一个构建, 则只需更改`REFRESHED_AT`环境的值.

### 查看新镜像
```sh
# 列出新的镜像
docker images test/test

# 列出镜像是如何被构建出来的
docker history 22d47c8cb6e5
```

### 从新镜像启动容器
```sh
# 启动容器
docker run -d -p 80 --name static_web test/test nginx -g "daemon off;"
```
- `-d` 告诉Docker以分离的方式在后台运行。 这种方式非常适合运行类似Nginx守护进程这样的需要长时间运行进程。
- `-p` 标志, 应该公开哪些网络端口给外部。运行一个容器时, Docker可以通过两种方法来在宿主机上分配端口:
  - Docker可以在宿主机上随机选择一个位于`32768~61000`的一个比较大的端口来映射到容器中的80端口上
  - 可以在Docker宿主机中指定一个具体的端口号来映射容器中的80端口上
```sh
# 通过命令查看映射的端口
docker port 66751b94bb5c0 80

# 通过docker镜像名称获取映射的端口信息
docker port static_web 80

# 将docker容器的宽口映射到指定的端口
docker run -id -p 8080:80 --name static_web test/test nginx -g "daemon off;"
```
