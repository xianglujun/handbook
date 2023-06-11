# fedora安装mongodb

## 1. 使用yum安装

### 1.1 创建mongodb-org.repo文件

```shell
cd /etc/yum.repos.d
touch mongodb-org.repo
vi mongodb-org.repo


# 填入以下配置

[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
```

### 1.2 安装mongodb

```shell
sudo yum install -y mongodb-org
```

通过这种方式安装，能够自动的解决mongodb的依赖关系。

> 目前6.0安装会有问题，还在探索中。。


