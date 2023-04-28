# rabbitmq安装

rabbitmq是erlang语言编写的, 安装rabbitmq之前, 首先需要安装erlang环境.

## erlang 安装
```sh
wget http://erlang.org/download/otp_src_21.1.tar.gz
tar -zxvf otp_src_21.1.tar.gz
cd otp_src_21.1

# 这里要新建一个erlang文件夹，因为erlang编译安装默认是装在/usr/local下的bin和lib中，这里我们将他统一装到/usr/local/erlang中，方便查找和使用。
mkdir -p /usr/local/erlang

# 在编译之前，必须安装以下依赖包
yum install -y make gcc gcc-c++ m4 openssl openssl-devel ncurses-devel unixODBC unixODBC-devel java java-devel

./configure --prefix=/usr/local/erlang

# 编译源码
make && make install

# 配置erlang环境
vi /etc/profile

# 添加环境变量
PATH=$PATH:/usr/local/erlang/bin

# 重新加载变量
source /etc/profile
```

## rabbitmq安装
```sh
# 下载源码包
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.8/rabbitmq-server-generic-unix-3.7.8.tar.xz

# 解压
tar -xvf rabbitmq-server-generic-unix-3.7.8.tar.xz -C /usr/local/

# 添加环境变量
vim /etc/profile
------  添加如下内容  ------
PATH=$PATH:/usr/local/rabbitmq_server-3.7.8/sbin


# 重载一下环境变量
source /etc/profile

# 添加web管理插件
rabbitmq-plugins enable rabbitmq_management
```

### rabbitmq配置安装
默认rabbitmq是没有配置文件的, 需要去官方github上, 复制一个配置文件模板, 并放在`RABBITMQ_HOME/etc/rabbitmq/`之下, 配置文件下载链接[rabbitmq config配置文件](https://github.com/rabbitmq/rabbitmq-server/tree/master/docs)

### rabbitmq web管理工具
```sh
rabbitmq-plugins enable rabbitmq_management
```
可以通过命令开启webui管理, 默认端口是`15672`

#### 登陆rabbitmq
默认用户为guest/guest登陆, 首次登陆会出现错误, 错误信息为`User can only log in via localhost`. 因为默认限制了guest用户只能在本机登陆, 也就是只能登陆`localhost:15672`.

修改方式, 在`RABBITMQ_HOME/etc/rabbitmq`中找到`rabbitmq.cnf`文件, 将配置项`loopback_users`访问取消,

```cnf
{loopback_users,[<<"guest">>]}
loopback_users.guest=false
```

## rabbmitmq常用命令

### 服务器启动/停止
```sh
# 启动
rabbitmq-server -detached

# 停止
rabbitmqctl stop
```
### 查件管理
```sh
# 查件列表
rabbitmq-plugins list

# 启动查件
rabbitmq-plugins enable xxx

# 停用插件
rabbitmq-plugins disable xxx
```

### 用户管理
```sh
# 添加用户
rabbitmqctl add_user username password

# 删除用户
rabbitmqctl delete_user username

# 修改密码
rabbitmqctl change_password username newpassword

# 设置用户角色
rabbitmqctl set_user_tags username tag

# 列出用户
rabbitmqctl list_users
```

### 权限管理
```sh
# 列出所有用户权限
rabbitmqctl list_permissions

# 查看指定用户权限
rabbitmqctl list_user_permissions username

# 清楚用户权限
rabbitmqctl clear_permissions [-p vhostpath] username

# 设置用户权限
rabbitmqctl set_permissions [-p vhostpath] username conf write read
### conf: 一个正则匹配那些资源能被用户访问
### write: 一个正则匹配那些资源能被该用户写入
### read: 一个正则匹配哪些资源能被该用户读取.
```
