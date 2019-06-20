# Shell字符串
字符串是Shell标称中最常用最有用的数据类型, 字符串可以用`单引号`也可以使用`双引号`，亦可以`不用引号`

## 单引号
```sh
str='this is a string'
```
- 单引号字符串的限制
  - 单引号里面的任何字符都会原样输出, 单引号字符串的变量是无效的
  - 单引号字符串中不能出现单独的单引号(对单引号使用转移符后也不行), 但可成对出现，作为字符串拼接使用

## 双引号
```sh
your_name='Johnny'
str="Hello, I know you are \"$your_name\" \n"
echo -e $str
```
- 优点
  - 双引号里可以有变量
  - 双引号里可以出现`转义字符`

## 拼接字符串
```sh
your_name="Tom"
# 使用双引号拼接
greeting="hello, "$your_name"!"
greeting_1="hello, ${your_name}"
echo $greeting $greeting_1

# 使用单引号拼接
greeting_2='hello, '$your_name' !'
greeting_3='hello, ${your_name}!'
echo greeting_2 greeting_3
```

## 获取字符串长度
```sh
string="abcd"
echo ${#string} # 输出4
```

## 提取子字符串
```sh
string "google is good site"
echo ${string:1:4} # 输出00gl
```

## 查找子字符串
查找字符i或o的位置
```sh
string="google is good site"
echo `expr index "$string" io` # 输出4
```
