# nginx 访问出现403问题
1. 查看nginx工作用户是否和启动用户不一致
```sh
ps aux | grep "nginx: worker process" | awk'{print $1}'

# 解决办法: 将工作用户和启动用户修改为一致即可
```

2. root目录下缺少必要的index文件
```sh
server {
      listen       80;
      server_name  localhost;
      index  index.php index.html;
      root  /data/www/;
  }

# root设置的工作目录下缺少了 index.php index.html的文件, 会导致该问题出现
```

3. root目录的工作权限不够
```sh
# 将对应的目录加上权限
chmod -R 777 /data
chmod -R 777 /data/www
```

4. 由于setlinux状态的原因, 导致403问题
```sh
# 1. 第一种方式可以禁用setlinux服务
/usr/sbin/sestatus
将SELINUX=enforcing 修改为 SELINUX=disabled 状态。

vi /etc/selinux/config
#SELINUX=enforcing
SELINUX=disabled

# 2. 第二种方式添加setlinux的规则
chcon -Rt svirt_sandbox_file_t /home/hct/sample/
```
