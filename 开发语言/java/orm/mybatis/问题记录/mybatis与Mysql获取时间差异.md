# mybatis与Mysql获取时间存在差异

[原创链接](https://blog.csdn.net/qq_39551600/article/details/89850363)

在工作中遇到同样的一条sql在数据库查询和在程序中查询，查出的时间字段居然不一样！差了大概`13`个小时的样子，觉得很神奇，百度一番后了解到，当数据库的时区设置为CST时,会出现这样的情况，`因为在与 MySQL 协商会话时区时，Java 会误以为是 CST -0500，而非 CST +0800。而mysql认为在CST +0800时区，最终导致了大概13个小时的差距`。



## 解决方案

### 修改mysql默认配置

1、通过sql语句更改数据库时区

    SET GLOBAL time_zone = '+8:00';#修改mysql全局时区为北京时间，即我们所在的东8区
    SET time_zone = '+8:00';#修改当前会话时区
    FLUSH PRIVILEGES;#立即生效

2、直接更改my.cnf配置文件

```shel
# vim /etc/my.cnf ##在[mysqld]区域中加上
default-time_zone = '+8:00'
# /etc/init.d/mysqld restart ##重启mysql使新时区生效
```

### 程序客户端指定时区

通过上面的设置，我们把mysql数据库的时区设置成了中国的时区`‘utc+8’`，而`serverTimezone=UTC`设置的是`utc`时区，两者不同，所以会发现从数据库读出的时间与本地时间差几个小时。要解决这个问题，需要让`serverTimezone`的设置与数据库的时区保持一致。我们可以选择修改`serverTimezone`的设置为`serverTimezone=Asia/Shanghai`，或者修改数据库的时区为`‘+0:00’`



在mysql-connect-J中，可以通过`src\main\resources\com\mysql\cj\jdbc\util.TimeZoneMapping.properties`查看`serverTimezone` 具体取值信息