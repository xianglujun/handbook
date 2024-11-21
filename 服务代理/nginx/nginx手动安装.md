# 手动安装nginx

## 1. 环境准备

```shell
yum install gcc openssl openssl-devel pcre pcre-devel zlib zlib-devel
```

## 2. 下载nginx

通过官方网站[nginx: download](https://nginx.org/en/download.html)下载，可以下载自己对应的版本。

## 3. 编译

```shell
# 解压
tar -xzvf nginx-1.24.0.tar.gz
# 配置nginx
./configure --prefix=/opt/apps/nginx-1.24.0 --with-http_ssl_module --with-http_gzip_static_module --error-log-path=/var/log/nginx/nginx.log --pid-path=/var/log/nginx/pid

# 编译
make install
```

到此, nginx通过手动安装的方式完成，这个时候就可以在`/opt/apps/nginx-1.24.0`目录中查看nginx执行文件，然后通过`nginx`命令启动nginx.

## 4. 增加防火墙配置

因为我使用的是centos stream 9的版本，默认的是使用的firewalld进行防火墙的规则配置，而且我安装在虚拟机里面，因此，为了能够访问80端口，则需要对80端口进行放行:

```shell
firewall-cmd --zone=public --add-port=80/tcp --permanent

# 查看防火墙的配置规则
firewall-cmd --zone=public --list-ports

# 增加防火墙之后，则需要重启一下防火墙
systemctl restart firewalld
```

## 5. 设置自动启动

```shell
vi /lib/systemd/system/nginx.service


# 输入以下内容
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
ExecStart=/opt/apps/nginx-1.24.0/sbin/nginx -c /opt/apps/nginx-1.24.0/conf/nginx.conf
ExecReload=/opt/apps/nginx-1.24.0/sbin/nginx -s reload
ExecStop=/opt/apps/nginx-1.24.0/sbin/nginx -s quit
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

```shell
# 开启自动启动
systemctl enable nginx
systemctl status nginx
systemctl start nginx
systemctl restart nginx
```

- Unit: 服务的说明
  
  - description：描述服务
  
  - After：描述服务类别

- Service: 服务运行参数设置
  
  - Type=forking:是后台运行的形式
  
  - ExecStart: 服务具体的运行命令
  
  - ExecReload：为重启命令
  
  - ExecStop：为停止命令
  
  - PrivateTmp=true：表示给服务分配独立的临时空间

- Install：运行级别下服务安装的相关配置，可设置为多用户，即系统运行级别为3

> Service的启动，重启，停止命令全部要求使用绝对路径
