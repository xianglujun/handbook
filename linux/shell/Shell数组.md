# Shell数组

bash支持一维数组(`不支持多维数组`), 并且没有限定数组的大小.

## 定义数组

在Shell中，用括号来表示数组, 数组元素用"空格"符号分开, 定义数组一般形式为：

```shell
数组名=(值1 值2 ... 值3)
```

还可以单独定义数组的各个分量:

```shell
array_name[0]=value0
array_name[1]=value1
array_name[n]=valuen
```

> NOTE: 可以不使用连续的下标, 并且下标的范围没有限制

## 读取数组

读取数组元素的一般格式是：

```shell
${数组名[下标]}
```

2. 使用`@`可以获取数组中的所有元素
   
   ```shell
   echo ${array_name[@]}
   ```

## 获取数组的长度

获取数组长度的方法与获取字符串长度的方法相同,

```shell
# 取得数组元素的个数
length=${#array_name[@]}
length=${#array_name[*]}

# 取得单个数组元素的长度
lengthn=${#array_name[n]}
```
