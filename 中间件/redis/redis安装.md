# redis的安装

# 环境介绍
1. Centos7系统
2. 之前没有安装过redis
3. redis版本: 5.0.3

# 依赖软件
1. gcc
```sh
yum install gcc
```

2. tcl 8.5+
```sh
yum install tcl
```

# redis 安装
1. 解压
```
tar -zxvf redis-5.0.3.tar.gz
```

2. 编译
```sh
make MALLOC=libc
```

3. 测试
```sh
make test
```

4. 安装
```
make install
```

# 安装踩坑记录
1. `make`时失败
```sh
jemalloc 分配内存出错的问题:

说明:
在README 有这个一段话。

Allocator
———

Selecting a non-default memory allocator when building Redis is done by setting
the `MALLOC` environment variable. Redis is compiled and linked against libc
malloc by default, with the exception of jemalloc being the default on Linux
systems. This default was picked because jemalloc has proven to have fewer
fragmentation problems than libc malloc.

To force compiling against libc malloc, use:

% make MALLOC=libc

To compile against jemalloc on Mac OS X systems, use:

% make MALLOC=jemalloc

因为系统中没有jemalloc的分配器, 因此我们需要强制制定为`libc`
```
