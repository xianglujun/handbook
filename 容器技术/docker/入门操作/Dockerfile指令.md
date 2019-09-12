在docker中, 包含了许多的指令:
- CMD
- ENTRYPOINT
- ADD
- COPY
- VOLUME
- WORKDIR
- USER
- ONBUILD
- LABEL
- STOPSIGNAL
- ARG
- ENV

## CMD
CMD指令用于指定一个容器启动时要运行的命令。`CMD的命令是在容器启动时执行命令`
`RUN命令则是在容器编译的时候执行的命令。`
```sh
sudo docker run -i -t test/test /bin/true

# 采用CMD命令实现
CMD ["/bin/true"]

# 也可以在CMD命令中指定参数
CMD ["/bin/bash","-l"]
```

> NOTE: 需要注意的是, 要运行命令是存放在一个数组结构中。这将告诉Docker按指定的原样来运行该命令。当然也可以不使用数组而是指定`CMD指令`, 这时候`DOCKER`会在指定的命令钱加上`/bin/sh -c`, 可能会产生意料之外的行为。

> NOTE: Dockerfile中只能指定一条CMD命令, 如果指定了多条CMD命令, 也只有最后一条CMD指令会被使用。如果想在启动容器时运行多个进程或者多条命令, 可以考虑使用类似Supervisor这样的服务管理工具.

## ENTRYPOINT
- `CMD`指令在`docker run`命令行中覆盖CMD指令
- `ENTRYPOINT` 指令不容易被覆盖, 并且在`docker run`中传入的参数, 最终会作为`ENTRYPOINT`的参数
- 同时也可以通过`docker run --entrypoint `的方式来覆盖`ENTRYPOINT`默认的行为

```Dockerfile
# 通过ENTRYPOINT指定参数
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]

# 在ENTRYPOINT中不指定参数
ENTRYPOINT ["/usr/sbin/nginx"]

# 在docker run 中指定的参数, 最红会传递给ENTRYPOINT
docker run -ti test/test -g "daemon off;"

# ENTRYPOINT 和 CMD 指令同时使用
ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-h"]
# 当docker run 不指定任何参数的时候, 可以直接使用 /usr/sbin/nginx -h 的方式执行
```

## WORKDIR
- `WORKDIR` 指令用来在从镜像创建一个新容器时, 在容器内部设置一个工作目录, `ENTRYPOINT`和`/`或`CMD`指定的程序会在这个目录下执行。
- `-w` 标志可以在运行时覆盖工作目录

```sh
# 为不同的命令设置不同的工作目录
WORKDIR /opt/webapp/db
RUN bundle install
WORKDIR /opt/webapp
ENTRYPOINT ["rackup"]

# 运行时替换容器内的工作目录设置
sodu docker run -ti -w /var/log ubuntu pwd
```

## ENV
`ENV`指令用来在镜像构建过程中设置环境变量。

```sh
# 该命令就如同在命令前面指定了环境变量前缀一样
ENV RVM_PATH /home/rvm

# 为RUN指令设置前缀
RUN gem install unicorn

# 从docker 1.4之后, 可以指定多个变量, 并在其他命令中使用
ENV RVM_PATH=/home/rvm RVM_ARCHFLAGS="-arch i386"
```
- 如果需要, 可以通过在环境变量前加上一个`\`来进行转移
- `docker run -e` 可以通过命令设置环境变量, 这些变量只在运行时有效

## USER
- `USER`指令用来指定该镜像会议什么样的用户去运行。
- `USER`没有指定用户, 默认用户为`root`
- `docker run -u`覆盖`USER`指令指定的值

```sh
USER user
USER user:group
USER uid
USER uid:gid
USER user:gid
USER uid:group
```

## VOLUME
- `VOLUME`指令用来向基于镜像创建的容器添加卷。
- 一个卷是可以存在于一个或者多个容器内的特定的目录, 这个目录可以绕过联合文件系统, 并提供如下共享数据或者对数据进行持久化的功能
  - 卷可以在容器间共享和重用
  - 一个容器可以不是必须和其他容器共享卷
  - 对卷的修改时立时生效的
  - 对卷的修改不会对更新镜像产生影响
  - 卷会一直存在直到没有任何容器再使用它
- `docker cp`可以从容器复制文件和复制文件到容器上
```sh
VOLUME ["/opt/project", "/data"]
```

## ADD
- ADD指令用来将构建环境下的文件和目录复制到镜像中。
- 源文件可以是一个`URL`,`构建上下文或环境中文件名或目录`
- 不能对构建目录或者上下文之外的文件进行`ADD`操作
- 如果目标地址以`/`结尾, 那么docker就认为源位置指向的是一个目录
- 如果目的地址以`/`结尾, 那么Docker就认为源位置执行的是目录
- 如果目的地址不是以`/`结尾, 那么就认为是一个文件
- 如果将一个归档文件(`gzip`,`bzip2`,`xz`)指定问源文件, Docker会自动将归档文件解开.`如果文件在目的位置中已经存在, DOCKER比不会覆盖已有的文件`
- 如果目的路径不存在, 会以全路径的方式创建目录.`文件和目录的模式为 755, 并且UID和GID都是0`
- `ADD 指令会使得构建缓存变得无效, 之后的构建, 都不能继续使用之前的构建缓存。`

```sh
# 将`构建目录下`的software.lic文件复制到容器`/opt/application`目录下
ADD software.lic /opt/application/software.lic
```

## COPY
- COPY指令非常类似于ADD, 但是`COPY`只关心在构建上下文中复制本地文件, 而不会去做`文件提取`,`解压`的工作。
- 文件源路径必须是一个与当前构建环境相对的文件或目录,`本地文件都放到和Dockerfile同一个目录下。`
- 构建环境会将文件上传到Docker守护进程, 而复制是在Docker守护进程中进行的。
- COPY指令的目的位置则必须是容器内部的一个绝对路径

## LABEL
- `LABEL`指令用于为Docker镜像添加元数据.元数据以键值对的形式展现
- `Docker 1.6`之后引入

```sh
LABEL version="1.0"
LABEL location="New York" type="Data Center" role="Web Server"

# 可以通过 docker inspect 查看label信息
docker inspect test/test
```

## STOPSIGNAL
- `STOPSIGNAL`指令用来设置停止容器时发送什么调用信号给容器。
- 这个信号必须是内核系统调用表中合法的数
- 指令是在`Docker 1.9`版本中引入

## ARG
- `ARG`指令用来定义可以在`docker build`命令运行时传递给构建运行时的变量
- 在构建的时候使用`--build-arg`标志
- 用户只能在构建构建时指定在Dockerfile文件中定义过的参数
- Docker预定了一些变量, 可以在编译的过程中直接使用
  - HTTP_PROXY
  - http_proxy
  - HTTPS_PROXY
  - https_proxy
  - FTP_PROXY
  - ftp_proxy
  - NO_PROXY
  - no_proxy
- `在Docker 1.9 版本中引入`

```sh
ARG build
# 为参数设置默认值, 如果在构建时没有为该参数指定值, 就使用默认值
ARG webapp_user=user
```

## ONBUILD
- `ONBUILD`指令能为镜像添加触发器
- 当一个镜像被用作其他进行的基础镜像的时候, 该镜像中的触发器将会被执行。
- 触发器会在构建过程中插入新指令, 我们可以认为这些指令时紧跟在FROM之后指定的。
- 可以通过`docker inspect `查看触发器的情况
- `ONBUILD`触发器会按照在父镜像中指定的顺序执行, 并且只能被执行一次(只能在子镜像中执行, 不会再孙子镜像中执行)
- 不能在`ONBUILD`指令中执行的指令
  - FROM
  - MAINTAINER
  - ONBUILD

```sh
ONBUILD ADD . /app/src
ONBUILD RUN cd /app/src * make
```
