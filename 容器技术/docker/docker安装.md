# docker安装方式

当前教程是在centos上进行安装的

## 卸载之前的老版本

> sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine

## 通过repository进行安装

安装  `yum-utils`, 主要提供了`yum-config-manager`的功能

> $ sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

## 通过命令安装稳定的仓库

> $ sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

## 可以选择`edge`或者`test`版本的仓库

> $ sudo yum-config-manager --enable docker-ce-edge
> $ sudo yum-config-manager --enable docker-ce-test

## 同时也是可以禁用版本的仓库

> $ sudo yum-config-manager --disable docker-ce-test

## 安装docker-ce版本

> $ sudo yum install docker-ce

## 同时也是安装docker的指定版本

> sudo yum list docker-ce --showduplicates | sort -r

## 安装指令版本的docker

> $ sudo yum install docker-ce-&lt;VERSION STRING&gt;

## 验证docker是否安装成功

> $ sudo docker run hello-world
