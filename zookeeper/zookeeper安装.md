## 下载ZooKeeper
[ZooKeeper下载](http://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz)

## 解压ZooKeeper安装
```sh
tar -xzvf zookeeper-3.4.10.tar.gz
```

## 复制`/conf`目录下的zoo_simple.cfg文件
```sh
cp zoo_simple.cfg zoo.cfg
```

## 通过后端模式启动服务器
```sh
bin/zkServer.sh start
```

## 通过前端的方式启动服务器
```sh
bin/zkServer.sh start-foreground
```
