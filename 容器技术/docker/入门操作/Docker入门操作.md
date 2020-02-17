# Docker入门操作

## 查看Docker运行是否正常
```sh
docker info
```

## 执行第一个容器
```sh
docker run -i -t ubuntu /bin/bash
```
- `docker run`告诉docker容器执行命令
- `-i` 表示保证容器中`STDIN`是开启的
- `-t` 表示创建的容器分配一个伪tty终端，为新建的容器提供一个交互式SHELL
- `ubuntu` 采用ubutun镜像, 被称之为基础镜像, 由docker提供

### 执行原理
- Docker会检查本地是否包含镜像, 如果没有包含, 则从官网的`Docker Hub Registry`上查看, 如果找到镜像, 则将镜像下载到本地
- Docker文件系统内部用这个镜像创建了一个新容器, 该容器拥有自己的网络, IP地址, 以及一个用来与宿主机进行通信的桥接网络接口

### 查看当前docker中的容器列表
```sh
docker ps -a
```

## 容器命名
Docker 会为我们创建的每个容器自动生成一个随机的名称. 我们也可以通过`--name`标志来实现自定义名称。

```sh
sudo docker run --name bob_the_container -i -t ubuntu /bin/bash
```

一个合法的容器名称只能包含以下字符:
- 小写字母a~z
- 大写字母A~Z
- 数字0-9
- 下划线
- 原点
- 横线

## 重新启动已经停止的容器
1. 通过容器的名称来启动
```sh
sudo docker start bob_th_container
```

2. 通过容器的ID启动容器
```sh
docker start 586241eb3369
```

## 附着到容器上
Docker 容器重新启动的时候, 会沿用`docker run`命令时指定的参数来运行, 因此我们的容器重新启动后会运行一个交互式回话shell. 另外也可以通过`docker attach`命令, 重新附着到容器会话上.

## 创建守护式容器
除了交互式运行的容器， 也可以创建长期运行的容器。 守护式容器(daemonized container)没有交互式会话, 非常适合运行应用程序和服务。

```sh
docker run --name daemon_dave -d ubuntu /bin/sh -c "while ture; do echo hello world; sleep 1; done"
```
- `docker run`命令通过`-d`参数, 让docker容器放到后台运行。

## Doocker 内部都干了什么
```sh
1. 查看容器中的日志信息
docker logs -f daemon_dave; # -f 与tail -f 的用法一致

2. 查看日志最后几行日志
docker logs --tail 10 daemon_dave; # 余tail --tail 10 用法一致

3. 为日志加上时间
docker logs -ft daemon_dave;
```

## Docker日志驱动
从docker 1.6开始, 也可以控制守护进程和容器所用的日志驱动, 可以通过`--log-driver`选项来实现.

- json-file: 为`docker logs`命令提供了基础
- syslog: 该选项将禁用`docker logs`命令, 并将所有容器日志输出重定向到Syslog
- none: 该选项将会禁用所有容器中的日志, 导致`docker log`命令也被禁用

## 查看容器内进程
如果想要查看容器内的进程, 需要使用`docker top`
```sh
sudo docker top damon_dave
```

## Docker 统计信息
可以使用`docker stats`命令, 它用来显示一个或多个容器的统计信息.
```sh
docker stats daemon_dave daemon_kate sarah
```

## 在容器内部运行进程
在 Docker 1.3 之后, 通过`docker exec`命令在容器内部额外启动新进程。可以在容器内运行的进程有两种类型:
- 后台任务
- 交互式任务

```sh
docker exec -d daemon_dave touch /etc/new_config_file
```
> NOTE: 从1.7版本之后, 可以通过`-u`为新启动的进程指定一个用户属主

## 停止守护式容器
要停止守护式容器， 只需要执行`docker stop`。
```sh
docker stop daemon_dave

# 查看已经停止的容器状态, 显示最后x个容器
docker ps -n x
```

## 自动重启容器
由于某种错误而导致容器停止运行, 可以通过`--restart`标志, 让docker自动重新启动该容器. `--restart`
标志会检查容器的推出代码, 并据此来判断是否要重启容器。
 `--restart`重启参数:
 - always: 无论推出代码是什么, 都将会自动重启容器
 - on-failure: 只有推出代码为非0值的时候, 才会重启. 另外, 还接受一个可选的`重启次数参数` `--restart=on-failure:5`, 最多重启5次。

## 深入容器
还可以通过`docker inspect`获取更多的容器信息
```sh
docker inspect daemon_dave
```
`docker inspect 命令会对容器进行详细的检查, 然后返回其配置信息, 包括名称、命令、网络配置以及更多有用数据`

> NOTE: 可以通过`-f`或者`--format`标志来选定查看结果,
```sh
sudo docker inspect --format='{{.State.Running}}' daemon_dave

sudo docker inspect --format='{{.State.Running}},{{.HostConfig.NetworkMode}}'  2613a1db44948b777239434c5aafa278e0e0c708d3bee532f29e1eb964e6cb19

```

## 删除容器
如果不再使用,`docker rm`命令来删除他们
```sh
docker rm 2613a1db4494

# 对于运行中的容器, 可以强制删除
docker rm -f 2613a1db4494

# 批量删除容器, -a 代表列出所有容器, -1标志表示只需要返回容器ID而不会返回容器的其他信息
docker rm `sudo docker ps -a -q`
```
