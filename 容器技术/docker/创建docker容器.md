# 创建docker容器
需要优先执行[下载并安装完成docker](docker安装.md)

## 当前需要用到的命令列表
```sh
docker build -t friendlyhello .  # Create image using this directory's Dockerfile
docker run -p 4000:80 friendlyhello  # Run "friendlyname" mapping port 4000 to 80
docker run -d -p 4000:80 friendlyhello         # Same thing, but in detached mode
docker container ls                                # List all running containers
docker container ls -a             # List all containers, even those not running
docker container stop <hash>           # Gracefully stop the specified container
docker container kill <hash>         # Force shutdown of the specified container
docker container rm <hash>        # Remove specified container from this machine
docker container rm $(docker container ls -a -q)         # Remove all containers
docker image ls -a                             # List all images on this machine
docker image rm <image id>            # Remove specified image from this machine
docker image rm $(docker image ls -a -q)   # Remove all images from this machine
docker login             # Log in this CLI session using your Docker credentials
docker tag <image> username/repository:tag  # Tag <image> for upload to registry
docker push username/repository:tag            # Upload tagged image to registry
docker run username/repository:tag                   # Run image from a registry
```

## docker的使用步骤
### 1. 定义`Dockerfile`文件
`Dockerfile`文件定义了容器内部的执行环境, 该文件定义了一些网络接口, 以及硬盘的驱动信息, 并且与当前的系统进行隔离. 因此需要制定一个端口号, 与外部系统进行映射。以及制定哪些文件会被拷贝进当前的环境之中。

#### 1.1 创建一个新的文件夹, 并且在该文件中创建`Dockerfile`文件。编辑并拷贝一下内容到文件之中
```docker
# Use an official Python runtime as a parent image
FROM python:2.7-slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt

# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
ENV NAME World

# Run app.py when the container launches
CMD ["python", "app.py"]
```
`Dockerfile`文件指向了连个文件, 他们分别是`requirements.txt`和 `app.py`的文件


### 2. 创建app
在当前的问价中创建一下两个文件夹: `app.py`和`requirements.txt`文件. 其中会通过`app.py`通过http的方式对其进行访问。
#### 2.1 创建`requirements.txt`文件
```docker
Flask
Redis
```
#### 2.2 创建`app.py`文件
```python
from flask import Flask
from redis import Redis, RedisError
import os
import socket

# Connect to Redis
redis = Redis(host="redis", db=0, socket_connect_timeout=2, socket_timeout=2)

app = Flask(__name__)

@app.route("/")
def hello():
    try:
        visits = redis.incr("counter")
    except RedisError:
        visits = "<i>cannot connect to Redis, counter disabled</i>"

    html = "<h3>Hello {name}!</h3>" \
           "<b>Hostname:</b> {hostname}<br/>" \
           "<b>Visits:</b> {visits}"
    return html.format(name=os.getenv("NAME", "world"), hostname=socket.gethostname(), visits=visits)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
```

### 3. 构建`app`
#### 3.1 通过命令的方式常见一个`image`镜像文件
> docker build -t friendlyhello

当前的构建的镜像文件被构建到本地机器上的`repository`列表之中, 可以通过如下命令进行查看
> docker image ls

#### 3.2 对于`linux`用户的问题解决:
- proxy server setting
当容器启动起来之后, Proxy server 会阻塞web应用的链接, 如果`docker`工作在代理服务器之后, 需要在`Dockerfile`文件中配置一下内容
> ENV http_proxy host:port
> EVN https_proxy host:port

- DNS setting
如果`DNS`无法正常的使用, 会影响`pip`, 因此需要修改`DNS`地址让`pip`能够正常的使用, 也许需要修改`docker`的默认的DNS的配置信息, 可以修改或者创建`/etc/docker/daemon.json`进行修改:
> {
  "dns": ["your_dns_address", "8.8.8.8"]
}

在保存`daemon.json`之后, 需要重启`docker`的服务
```sh
sudo service docker restart
```

### 4. 运行`app`
```sh
docker run -p 4000:80 friendlyhello
```
当`app`执行起来之后, 可以通过`http://localhost:4000`进行访问.

> NOTE: 如果当前的docker的`toolbox`是运行在Windows7上面的, 只需要使用`IP`替换掉`localhost`的使用。

同时也可以使用`curl`的语句进行连接的测试:
```sh
curl http://localhost:4000
```
> NOTE: 在window中, 通过`CTRL + C`并不能停止`docker`的运行, 而是要先通过`docker container ls`列出正在执行的容器, 并显式的通过`docker container stop <container Name Or Id>`进行停止。

### 5. 在后台执行`app`
```sh
docker run -d -p 4000:80 friendlyhello
```

当app在后台执行的时候, 可以通过`docker container ls`命令查看container ID等信息, 如下:
```sh
$ docker container ls
CONTAINER ID        IMAGE               COMMAND             CREATED
1fa4ab2cf395        friendlyhello       "python app.py"     28 seconds ago
```

这是, 可以通过以下命令对docker app进行停止:
```sh
docker container stop 1fa4ab2cf395
```

### 6. 共享镜像
共享镜像是通过将`image`文件上传到第三方的仓库, 方便其他人能够使用. 这里使用的是docker提供的仓库来实践

#### 6.1 创建docker 的仓库的账号
需要通过[仓库账号创建](https://hub.docker.com/r/19911212/xianglj1991/tags/)创建一个账号, 并同时需要创建自己的仓库的地址.

#### 6.2 通过docker登录
```sh
docker login
```
这里这里需要我们输入`username`和`password`信息

#### 6.3 标记镜像文件(Tag the image)
标记是通过一个注册的名称将本地的镜像进行关联, 具体格式为`username/repository:tag`， 其中的`tag`是一个可选的参数, 但是建议加上. 建议在进行命名的时候, 命令一些有意义的名称.

`docker`将通过`username`、`repository`,`tag`来标记当前的`image`应该上传都哪一个仓库下, 具体命令如下:
```sh
docker tag image username/repository:tag
```
例如:
```sh
docker tag image 19911212/xianglj1991:part2
```
> NOTE: 当前的上传必须要保证

通过该命令，会在镜像列表中创建一个新的镜像的`tag`, 可以通过`docker image ls`查看:
```sh
docker image ls
```
```
19911212/xianglj1991      part2               897eb1c0a16a        2 hours ago         132MB
friendlyhello             latest              897eb1c0a16a        2 hours ago         132MB
xianglj1991/get-started   part2               897eb1c0a16a        2 hours ago         132MB
<none>                    <none>              ed818f5aefb1        2 hours ago         132MB
python                    2.7-slim            804b0a01ea83        2 days ago          120MB
hello-world               latest              4ab4c602aa5e        5 weeks ago         1.84kB
```

#### 6.4 发布镜像(publish image)
```sh
docker publis username/repository:tag
```

当上面的命令执行完成之后, 那么发布镜像就完成了. 可以在自己的`repository`后台看到自己的发布的镜像文件

#### 6.5 获取并执行image镜像
```sh
docker run -p 4000:80 username/repository:tag
```

#### 6.6 后台运行镜像
```sh
docker run -d -p 4000:80 username/repository:tag
```

#### 6.7 查看运行的容器列表
```sh
docker container ls
```
