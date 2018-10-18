# non-root user
主要在linux上, 能够让非root用户能够使用docker, 需要执行以下命令

1. 创建`docker`用户组
> sudo groupadd docker

2. 将用户加入到`docker`用户组
> duso usermod -aG docker $USER

3. 退出当前用户的登陆, 或者重启虚拟机
4. 使用用户重新登陆进入系统, 查看是否能够执行
> docker hello-world

if you initially ran Docker CLI commands using `sudo` before adding your user to the docker group, you may see the following error, which indicates that your ~/.docker/ directory was created with incorrect permissions due to the sudo commands.

> WARNING: Error loading config file: /home/user/.docker/config.json -
stat /home/user/.docker/config.json: permission denied

To fix this problem, either remove the ~/.docker/ directory (it is recreated automatically, but any custom settings are lost), or change its ownership and permissions using the following commands:

> \$sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
>
> \$sudo chmod g+rwx "$HOME/.docker" -R
