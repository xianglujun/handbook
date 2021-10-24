# mysql相关命令使用

## 连接远程数据库
```sh
mysql -ubitun_admin -p -h rm-wz9ai028bfyc12903.mysql.rds.aliyuncs.com -P3306
````

## 执行mysql文件
```#!/bin/sh
source sql_file_path
```



## binlog

```mysql
# 查看是否开启binlog
show variables like 'log_bin'

# 查看当前日志
show master status

# 查看bin日志，使用
mysqlbinlog mail-bin.000001
```

### 开启binlog

在my.cnf的配置文件中加入一下配置:

```mysql
[mysqld]
log_bin=show-bin
```

