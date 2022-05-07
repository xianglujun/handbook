# git将本地代码同步到远程仓库实现

1. 本地git仓库初始化

```sh
git init
```

2. 把文件添加到版本库中

```sh
git add .
```

3. 将本地代码提交

``````sh
git commit -m 'xxx'
``````

4. 关联到远程库

``````sh
git remote add origin '远程地址'
``````

5. 将本地库的内容推送到远程

``````sh
git push -u origin master
``````



## 冲突解决

1. 可以采用`git merge master`的方式合并冲突

2. `fatal: refusing to merge unrelated histories`

   ```sh
   git pull origin master --allow-unrelated-histories
   ```

   