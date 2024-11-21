# shell 基础概念

shell 是一个用C语言编写的程序, 它是用户使用linux的桥梁. Shell既是一种命令语言, 又是一种程序设计语言

shell 是指一种应用程序, 这个应用程序提供了一个界面, 用户通过这个界面访问操作系统内核的服务。

## shell 脚本

Shell 脚本(shell script)是一种为shell编写的脚本程序.

## shell 环境

shell 编程跟java, php编程一样，只要有一个能编写代码的文本编辑器和一个能解释执行的脚本解释器就可以了

linux的shell种类众多，常见的有:

- Boume Shell (/usr/bin/sh或bin/sh)
- Boume Again Shell(/bin/bash)
- C Shell(/usr/bin/csh)
- K Shell(/usr/bin/ksh)
- Shell for Root(/sbin/sh)

> 默认情况下，使用的是 Bourne Again Shell, 由于易用和免费，Bash在日常工作中被广泛使用。同时Bash也是大多数Linux系统默认的Shell. 在一般情况下, 人们不区分Bourme Shell 和 Bourme Again Shell, 所以像`#!/bin/sh`， 它同样可以改为`#!/bin/bash`

## 第一个Shell 脚本

- 创建`test.sh`文件`vi test.sh`
- 加入`hello world`文本到文件中
  
  ```shell
  #!/bin/bash
  echo "Hello World!"
  ```
- `#!`是一个约定标记, 告诉系统这个脚本需要使用什么解释器来执行
- `echo` 用于向窗口输出文本

### 运行Shell 脚本

1. 作为可执行程序
   
   ```shell
   # 使脚本具有可执行权限
   chmod +x ./test.sh
   # 执行脚本
   ./test.sh
   ```
   
   > 一定需要写成`./test.sh`,运行其他二进制程序也是一样, `test.sh`linux系统会去`PATH`里寻找`test.sh`的执行命令，然而只有`/bin`, `/usr/bin`, `/usr/sbin`等在PATH里。 所以在执行命令时候，需要告知系统从当前文件夹里查找`./test.sh`

2. 作为解释器参数
   这种运行方式是, 直接运行解释器, 其参数就是Shell脚本的文件名
   
   ```shell
   /bin/sh test.sh
   /bin/php test.php
   ```
   
   > 这种方式运行的脚本, 不需要在第一行指定解释器信息。
