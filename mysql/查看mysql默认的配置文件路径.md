# 查看mysql默认的配置文件路径
- 通过查找文件名称的方式
```sh
find / -name my.cnf
```

- 通过`which`命令, 查看mysql的安装路径
```sh
which mysql
```

- 通过执行`mysqld`的方式查看读取配置文件的路径
```sh
/usr/local/mysql/bin/mysqld --verbose --help |grep -A 1 'Default options'
```
