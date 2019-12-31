# centos7 防火墙相关

在centos7中, 默认使用的`firewalld`作为防火墙，如果使用`iptables`, 则需要另行安装.

1. 关闭防火墙
```sh
systemctl stop firewalld
```

2. 禁止防火墙开机启动
```sh
systemctl disable firewalld.service
```

# centos7 iptables防火墙
1. 安装`iptables防火墙`
```sh
yum -y install iptables-services
```

2. 新增防火墙规则
防火墙配置路径: `/etc/sysconfig/iptables`
```sh
vi /etc/sysconfig/iptables

新增一下内容(新增3306端口):
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT
```

3. 重启`iptables`防火墙
```sh
systemctl restart iptables.services
```

4. 设置防火墙开机启动
```sh
systemctl enable iptables.services
```

5. 查看端口是否开放
```sh
firewalld-cmd --query-port=8080/tcp
# 开放80端口
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=8080-8085/tcp
# 移除端口
firewall-cmd --permanent --remove-port=8080/tcp

#查看防火墙的开放的端口
firewall-cmd --permanent --list-ports
```

6. 查看防火墙规则
```sh
firewall-cmd --list-all
```

7. 添加服务器到防火墙
```sh
# 查看开启的服务
firewall-cmd --list-services

# 添加服务器
firewall-cmd --permanent --add-service=redis

# 查看服务器列表
firewall-cmd --get-services
```
