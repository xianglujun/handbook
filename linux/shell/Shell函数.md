# Shell 函数
linux shell可以用户自定义函数, 然后在shell脚本中随便调用

shell中函数的定义格式如下:
```sh
[function] funname [()] {
  action;
  [return int;]
}
```

说明:
- 可以带 function fun()定义, 也可以直接fun()定义，不带任何参数
- 参数返回, 可以显式加: `return`返回, 如果不加, 将以最后一条命令运行结果, 作为返回值。 return 后跟值n(0-255)

```sh
#!/bin/bash

demoFun() {
  echo "这是我的第一个shell函数"
}

echo "-----函数开始执行-----"
demoFun
echo "-----函数执行完毕-----"
```

函数返回值:
```sh
#!/bin/bash

funWithReturn(){
    echo "这个函数会对输入的两个数字进行相加运算..."
    echo "输入第一个数字: "
    read aNum
    echo "输入第二个数字: "
    read anotherNum
    echo "两个数字分别为 $aNum 和 $anotherNum !"
    return $(($aNum+$anotherNum))
}
funWithReturn
echo "输入的两个数字之和为 $? !"
```

## 函数参数
在Shell中， 调用函数时可以向其传递参数, 在函数体内部, 通过`$n`的形式来获取参数的值。

```sh
funWithParam(){
    echo "第一个参数为 $1 !"
    echo "第二个参数为 $2 !"
    echo "第十个参数为 $10 !"
    echo "第十个参数为 ${10} !"
    echo "第十一个参数为 ${11} !"
    echo "参数总数有 $# 个!"
    echo "作为一个字符串输出所有参数 $* !"
}
funWithParam 1 2 3 4 5 6 7 8 9 34 73
```
