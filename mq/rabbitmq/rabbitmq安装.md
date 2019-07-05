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
