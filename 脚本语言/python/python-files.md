# Reading and Writing Files

`open()`用于返回一个file对象, 主要用于两个参数调用: `open(filename, mode)`

```python
f = open('workfile', 'w')
```

- 第一个参数: 第一个参数时一个字符串参数, 包含了文件名称
- 第二个参数: 描述了我们对文件的使用方式
  - `r`: 表示文件处于只读模式
  - `w`: 表示文件处于只写模式
  - `a`: 表示打开文件, 并向文件末尾写入数据
  - `r+`: 表示打开文件, 并处于可读和可写的方式
  - 该参数可以省略, 如果该参数省略, 则默认是`r`模式



## 文件打开模式

对于python而言, 默认是以`text mode`的形式打开, 这种方式读和写都是采用`string`的形式进行操作。

如果在打开文件的过程中, 没有指定`encoding`参数, 默认的以来与平台的`encoding`集

- `b`: 该种模式是将文件以二进制的形式打开`binary mode`, 这种方式将以`byte`的形式进行操作.

对于`text mode`来说, 在读取文本类型时, 默认每行的结束依赖于平台指定的结束符(`\n`在unix上，windows上使用`\r\n`). python都只是会使用`\n`。

`with`关键字， 用于在io资源处理完成之后, 将会关闭io流。

```python
>>> with open("workfile") as f :
        read_data = f.read()
    f.closed
```

