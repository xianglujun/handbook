# git 删除仓库文件

```sh
1. git rm -r -n --cached "bin/" //-n：加上这个参数，执行命令时，是不会删除任何文件，而是展示此命令要删除的文件列表预览。
2. git rm -r --cached  "bin/"      //最终执行命令. 
3. git commit -m" remove bin folder all file out of control"    //提交
4. git push origin master   //提交到远程服务器
```

