# 下载源码
> git clone https://github.com/yahoo/kafka-manager.git

# 执行sbt命令
> ./sbt clean dist

命令执行完成之后, 在`target/universal`生成一个zip文件, 将zip文件拷贝到需要部署的目录中

# 更改配置文件
更改`application.cnf`文件, 例如:
```c
kafka-manager.zkhosts="localhost:2181"
```

# 启动容器
```sh
bin/kafka-manager
```
 > 默认端口为:9000, 可以通过如下方式制定端口:

 ```sh
bin/kafka-manager -Dconfig.file=/path/to/application.conf -Dhttp.port=9000 -java-home /usr/local/oracle-java-8
 ```
