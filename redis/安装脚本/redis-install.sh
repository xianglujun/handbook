```sh
#!/bin/bash
set -e
download_dr="/opt/download"
redis_version="redis-3.0.0"
file_name="${redis_version}.tar.gz"

file_full_path="$download_dr/$file_name"
# 判断文件是否存在
if [ -e $dowload_dr ]
then
    echo "$download_dr 目录已经存在"
else
    echo "$download_dr 目录不存在, 创建目录"
    mkdir -p $download_dr
fi

# 判断文件是否存在, 不存在则下载
if [ -e $download_dr/$file_name ]
then
    echo "$file_name 文件已经存在"
else
    wget -P $download_dr "http://download.redis.io/releases/$file_name"
fi

# 将文件进行解压
eval "tar -zxvf $file_full_path -C $download_dr/"

## 将文件进行移动
target_path="/usr/local"
if [ -e "$target_path/$redis_version" ]
then
    #eval "rm -R -f $target_path/$redis_version"
    echo "$target_path/$redis_version 文件已经存在"
fi

#eval "mv -f $download_dr/$redis_version $target_path"

## 进入目录
redis_path="$target_path/$redis_version"
eval "cd $redis_path"
pwd

## 进行依赖查件安装
yum install gcc tcl

## 开始编译
make
echo "编译完成"

## 开始测试
make test
echo "测试完成"

## 开始安装
make install

## 判断文件是否存在
server_start="/opt/shell/redis/start.sh"
if [ -e $server_start ]
then
    echo "$server_start 文件已经存在, 删除该文件"
    eval "rm $server_start"
else
    echo "$server_start 文件不存在, 创建文件"
fi

eval "echo '#!/bin/bash' >> $server_start"
eval "echo 'cd $redis_path/src' >> $server_start"
eval "echo 'nohup ./redis-server ../redis.conf &' >> $server_start"
eval "chmod +x $server_start"

## 生成客户端启动工具
redis_cli="/opt/shell/redis/redis_cli.sh"
if [ -e $redis_cli ]
then
    echo "$redis_cli 文件已经存在, 删除该文件"
    eval "rm $redis_cli"
else
    echo "$redis_cli 文件不存在, 创建文件"
fi

eval "echo '#!/bin/bash' >> $redis_cli"
eval "echo 'cd $redis_path/src' >> $redis_cli"
eval "echo './redis-cli' >> $redis_cli"
eval "chmod +x $redis_cli"

echo "redis 安装完成"
```
