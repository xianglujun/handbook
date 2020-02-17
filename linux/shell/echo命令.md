# echo指令, 用于字符串的输出, 命令格式:
```sh
echo string
```

## 显示普通字符串
```sh
echo "it is a test"
```
> NOTE: 这里的双引号完全可以省略

## 显示转义字符
```sh
echo "\"It is a test\""
```

## 显示变量
read命令从标准输入中读取一行, 并把输入行的每个字段的值指定给shell变量.
```sh
#!/bin/sh
read name
echo "$name It is a test"
```

> NOTE: `read`命令是从命令行中读入数据, 并放入变量之中.

## 显示换行
```sh
echo -e "OK! \n"  # -e 开启转义
echo "It is a test"
```

## 显示不换行
```sh
#!/usr/bin/env bash
echo -e "OK! \c" # -e 开启转义 \c 不换行
echo "It is a test"
```

## 显示结果定向至文件
```sh
echo "It is a test" > myfile
```

## 原样输出字符串, 不进行转义或变量(用单引号)
```sh
echo '$name\"'
```

## 显示命令执行结果
```sh
echo `date`
```

>NOTE: 这里使用的是反引号```, 结果将显示当前日期
