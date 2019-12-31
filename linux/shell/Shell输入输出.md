# Shell 输入/输出重定向
大多数UNIX系统命令从你的中断接收输入并将所产生的输出发送回到您的终端。一个命令通常从一个叫标准输入的地方读取输入, 默认情况下，这恰好是你的终端。同样, 一个命令通常将其输入写入到标准输出, 默认情况下, 这也是你的终端.

|命令|说明|
|:---|:---|
|command > file   |将输出重定向到file   |
|command < file   |将输入重定向到file   |
|command >> file   |将输出以追加的方式重定向到file   |
|n > file   |将文件描述符为n的文件重定向到file   |
|n>>file   |将文件描述符为n的文件以追加的方式重定向到file   |
|n>&m   |将输出文件m和n合并   |
|n<&m   |将输入文件m和n合并   |
|<<tag   |将开始标记tag和结束标记tag之间的内容作为输入   |

> NOTE: 需要注意的是文件描述符0, 通常是标准输入(STDIN), 1是标准输出STDOUT, 2是标注错误输出(STDERR)

## 输出重定向
重定向一般通过在命令插入特定的符号来实现。特别的, 这些符号的语法如下表示:
```sh
command1 > file1
```
上面这个命令执行command1然后将输出的内容存入file1

注意任何file1内的已经存在的内容将被新内容替代. 如果要将新内容添加在文件末尾, 请使用`>>`操作符.

下面执行的`who`命令, 他将命令的完整的输出重定向在用户文件中:
```sh
who > users
```

## 输入重定向
和输出重定向一样, Unix命令也可以从文件获取输入, 语法为:
```sh
command1 > file1
```

这样, 本来需要从键盘获取输入的命令会转移到文件读取内容。

>NOTE: 输出重定向是大于号(>), 输入重定向是小于号(<)

接着以上实例, 我们需要统计user文件中的行数, 执行以下命令
```sh
wc -l users
```

也可以将输入重定向到user文件:
```sh
wc -l < users
```

## 重定向深入理解
一般情况下, 每个Unix/Linux命令运行时 都会打开三个文件:
- 标准输入文件(stdin): stdin的文件描述符为`0`, Unix程序默认从stdin读取数据
- 标准输出文件(stdout): stdout的文件描述符为`1`, Unix程序默认想stdout输出数据
- 标准错误文件(stderr): stderr的文件描述符为`2`, Unix程序会想stderr流中写入错误信息。

### 错误文件追加
如果希望`stderr`重定向到file, 可以这样写:
```sh
command 2 > file
```

如果希望`stderr`追加到file文件尾, 可以这样写:
```sh
command 2 >> file
```

## Here Document
Here Document是Shell中的一种特殊定位方式, 用来将输入重定向到一个交互式Shell脚本或程序。

```sh
command << delimiter
  Document
dilimiter
```
它的作用是将两个delimiter之间的内容作为输入传递给command.

> 注意:
> - 结尾的delimiter一定要顶格写, 前面不能有任何字符, 后面也不能有任何字符，包括空格和tab缩进
> - 开始的delimiter前后的空格会被忽略掉

```sh
$ wc -l << EOF
    欢迎来到
    Shell脚本教程
    www.runoob.com
EOF
```

## /dev/null文件
如果希望之星某个命令， 但又不希望在屏幕上显示输出结果, 那么可以将输出重定向到/dev/null

```sh
command > /dev/null
```
`/dev/null`是一个特殊的文件,写入到它的内容都会被丢弃;如果尝试从该文件读取内容, 那么什么也读不到。但是`/dev/null`文件非常有用, 将命令的输出重定向到它，将会起到"禁止输出"的效果.
