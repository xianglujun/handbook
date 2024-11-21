## 第一个ZooKeeper会话

1. 下载ZooKeeper的安装包并解压
   
   ```sh
   tar -xzvf zookeeper-version.tar.gz
   ```

2. 拷贝`zoo_sample.cnf`的配置文件
   
   ```sh
   mv conf/zoo_sample.cnf conf/zoo.cnf
   ```

3. 修改`zoo.cnf`中的数据存放位置
   一般不会存放在`/tmp/zookeeper`, 以为容易将根分区的磁盘占满, 修改`dataDir`的路径
   
   ```sh
   dataDir=/usr/zookeeper
   ```

4. 启动zookeeper的服务器
   
   ```sh
   bin/zkServer.sh start
   ```

5. 通过前端的方式启动服务器
   
   ```sh
   bin/zkServer.sh start-foreground
   ```

6. 客户端连接
   
   ```sh
   bin/zkCli.sh
   ```

7. 查看根节点下的所有的znode
   
   ```sh
   ls /
   ```

8. 创建一个znode节点
   
   ```sh
   create /workers ""
   ```
   
   创建了一个节点, ""表示不想为当前的`/workers`节点初始化任何数据。

9. 创建一个临时节点
   
   ```sh
   create -e /workers ""
   ```

10. 监听一个节点
    
    ```sh
    stat /workers true
    ```

> NOTE: 通过`stat`的命令可以获取znode节点的属性, 并允许我们能够在znode节点上创建监听点. 通过在zone路径后设置true来实现。
