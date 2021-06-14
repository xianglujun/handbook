# 更换git本地仓库地址

1. 查看当前项目下的git地址列表

```shell
git remote -v
```

2. 将本地地址更换为http格式

```shell
git remote set-url --add origin http://github.com/devops/titan-cc-consist.git
```

3. 将本地地址更换为ssh格式

```shell
git remote set-url --add origin git@github.com:devops/titan-cc-consist.git
```

4. 将本地连接地址删除

```shell
git remote set-url --delete origin git@github.com:devops/titan-cc-consist.git
```

​                              