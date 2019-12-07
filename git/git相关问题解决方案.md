# git相关问题解决方案

## 如何重新保存密码

```sh
# 缓存用户输入的密码, 不用重复输入`cache，store，keychain`可以选择
git config --global credential.helper store

# 清除用户的用户名和密码
git credential-manager uninstall

# 在执行以上命令重新开启
git config --global credential.helper store
```

## 查看当前项目的git配置信息

```sh
git config --list 
```

