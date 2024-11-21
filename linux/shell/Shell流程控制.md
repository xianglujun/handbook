# Shell流程控制

## if else

### if

if 语法格式

```shell
if condition
then
  command1
  command2
  ...
  commandN
fi
```

写成一行(适用于终端命令提示符)

```shell
if [ $(ps -ef | grep -c "ssh") -gt 1]; then echo "true"; fi
```

### if else

if else 语法格式:

```shell
if condition
then
  command1
  command2
  ...
  commandN
else
  command
fi
```

### if else-if else

if else-if else语法格式

```shell
if condition
then command1
elif [[ condition ]]; then
  command2
fi
```

判断两个变量是否相等:

```shell
a=10
b=20
if [ $a == $b ]
then
  echo "a 等于 b"
elif [[ $a -gt $b ]]; then
  echo "a 大于 b"
elif [[ $a -lt $b ]]; then
  echo "a 小于 b"
else
  echo "没有符合的条件"
fi
```

## for 循环

与其他编程语言类似, Shell支持for循环
for循环一般格式为:

```shell
for var in item1 item2 ... itemN
do
  command1
  command2
  command3
  ...
  commandN
done
```

写成一行:

```shell
for var in item1 item2 ... itemN; do command1 command2 .. done;
```

当变量在列表里, for循环即执行一次所有命令, 使用变量名获取列表中的当前取值。 命令可为任何有效的shell命令和语句。in列表可以包含替换, 字符串和文件名

in 列表时可选的, 如果不用它, for循环使用命令行的位置参数。

```shell
for loop in 1 2 3 4 5
do
  echo "The value is: $loop"
done
```

## while语句

while循环用于不断执行一系列命令， 也用于从输入文件中读取数据; 命令通常为测试条件:

```shell
while condition
do
  command
done
```

```shell
#!/bin/bash
int=1
while(($int<=5))
do
  echo $int
  let "int++"
done
```

```shell
echo '按下<CTRL-D>退出'
echo -n '输入你喜欢的网站名字'
while read FILM
do
  echo "是的!$FILM是一个好网站"
done
```

## 无限循环

无限循环语法格式:

```shell
while :
do
  command
done
```

或者:

```shell
while true
do
  command
done
```

或者:

```shell
for ((; ;))
```

## util循环

until循环执行一系列命令直至条件为true时停止
until循环与while循环在处理方式上刚好相反

一般while循环优于util循环，但在某些时候也只是极少数情况下, until循环更加有用

```shell
until [[ condition ]]; do
  #statements
done
```

condition 一般为条件表达式, 如果返回值时false, 则继续执行循环体内的的语句，否则跳出循环。

```shell
#!/bin/bash
a=0
until [[ ! $a -lt 10]]; do
  echo $a
  a=`expr $a + 1`
done
```

## case

Shell case 语句为多选择语句, 可以用case语句匹配一个值与一个模式, 如果匹配成功, 执行相匹配的命令.

```shell
case 值 in
  模式1)
  command1
  command2
  ...
  commandN
  ;;
  模式2)
  command1
  command2
  ...
  commandN
  ;;
esac
```

case 工作方式如上所示, 取值后面必须为单词in, 每一模式必须以右括号结束. 取值可以为变量或常数。匹配发现取值符合某一个模式模式后, 期间所有命令开始执行直至`;;`

```shell
echo '输入 1 到 4 之间的数字:'
echo '你输入的数字为:'
read aNum
case $aNum in
    1)  echo '你选择了 1'
    ;;
    2)  echo '你选择了 2'
    ;;
    3)  echo '你选择了 3'
    ;;
    4)  echo '你选择了 4'
    ;;
    *)  echo '你没有输入 1 到 4 之间的数字'
    ;;
esac
```

## 跳出循环

在循环过程中, 有时候需要在未达到循环结束条件时, 强制跳出循环, Shell使用两个命令来实现该功能: break和continue

### break命令

break命令允许跳出所有循环

```shell
#!/bin/bash
while:
do
  echo -n "输入 1 到 5的数字"
  read aNum
  case $aNum in
    1|2|3|4|5) echo "你输入的数字为$aNum"
    ;;
    *) echo "你输入的数字不是1到5之间的!游戏结束"
    break
    ;;
  esac
done
```

### continue

continue命令与break命令类似, 只有一点差别, 它不会跳出所有循环, 仅仅跳出当前循环。

```shell
#!/bin/bash
while:
do
  echo -n "输入 1 到 5的数字"
  read aNum
  case $aNum in
    1|2|3|4|5) echo "你输入的数字为$aNum"
    ;;
    *) echo "你输入的数字不是1到5之间的!"
    continue
    echo "游戏结束"
    ;;
  esac
done
```

```

```
