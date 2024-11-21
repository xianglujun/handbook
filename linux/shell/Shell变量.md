# Shell 变量

## 定义变量

```sh
your_name="just a test"
```

> NOTE: `变量名和等号之间不能有空格`

## 变量的命名规则

- 命名只能使用英文字母, 数字和下划线，首个字符`不能以下划线开头`
- 中间不能有空格, 可以使用下划线`_`
- 不能使用标点符号
- 不能使用bash里的关键字(可以用`help`命令查看保留关键字)

## 变量的赋值方式

- 直接显示赋值 `your_name="just a test"`
- 使用语句为变量赋值 `for file in $(ls /etc)`

## 使用变量

使用一个定义过的变量，只要在变量名前面加`$`即可

```sh
your_name="qinjx"
echo $your_name
echo ${your_name}
```

> NOTE: 变量名外面的花括号开始可选的，花括号是为了帮助解释器识别变量的边界。

```sh
for skill in Ada Coffee Action Java; do
  echo "i am good at ${skill}Script"
done
```

> 对于上面的shell, 如果不适用花括号，可能会导致错误的结果.

## 重定义变量

```sh
your_name="TOM"
echo $your_name
your_name="Johnny"
echo $your_name
```

## 只读变量

使用`readonly`命令可以将变量定义为只读变量，只读变量的值不能被改变

```sh
#!/bin/bash
myUrl="www.baidu.com"
readonly myUrl
myUrl="www.google.com"
```

## 删除变量

使用`unset`命令可以删除变量

```sh
unset variable_name
```

> NOTE: 变量被删除之后不能再次使用, unset命令`不能删除只读变量`

```sh
#!/bin/bash
myUrl="www.baidu.com"
unset myUrl
echo $myUrl
```

## 变量类型

运行Shell时，会同时存在三种变量

1. 局部变量
   局部变量在脚本或命令中定义，仅当在当前shell实例中有效, 其他shell启动的程序不能访问局部变量
2. 环境变量
   所有的程序，包括shell启动的程序, 都能访问环境变量，有些程序需要环境变量来保证其正常运行。必要的时候, shell脚本也可以定义环境变量
3. shell变量
   shell变量是由shell程序设置的特殊变量，shell变量中有一部分是环境变量，有一部分是局部变量，这些变量保证了shell正常运行。

### 1. 本地变量

- 当前shell所有

- 生命周期跟当前shell一样

```shell
a=99
echo $a

#函数中声明
myfunc() {
    myvar=99
    local b = 10 # 此时这个变量，在方法外无法被访问
    echo $myvar
}


echo $myvar # 这里无法被访问
myfunc # 调用函数
echo $myvar 可以访问到


abc=sxt
echo $abc
echo "$abcisnothere"
echo "$(abc)isnothere"


```

### 2. 局部变量

- 只能用于函数

- local var=100

- 局部变量作用于只正对于函数内部，除了函数就无法被访问

```shell
myfunc() {
    local a=100
    echo $a
}

echo $a # 这里无法被访问
```

### 3. 位置变量

- \$1, \$2, \${11}

- 主要在脚本和函数中使用

```shell
myfunc(){
    echo $1
    echo $4
}
```

### 4. 特殊

- \$#: 位置参数个数

- \$*: 参数列表，双银行引用为一个字符串
  
  - 所有参数作为一个字符串, 五个参数作为一个字符串

- \$@：参数列表，双引号引用为单独的字符串
  
  - 所有的参数作为单个字符串，5个参数作为五个字符串

- \$$：当前shell的PID， 接受者
  
  - \$BASHPID: 真实的值
  
  - 管道

- \$?：上一个命令的退出状态
  
  - 0：成功
  
  - 其他：失败
