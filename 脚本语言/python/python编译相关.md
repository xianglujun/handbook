# "Compiled" python File 

为了提高加载python的modules,  Python会将编译module的版本存入本地缓存。存放在`__pycache__/module.version.pyc`文件中。该编译文件包含了`python`版本号文件.

- 在python 3.3 发布版本中, 编译了`spam.py`的文件, 该文件将会被保存在`__pycache__/spam.cpython-33.pyc`.

- Python通过检查源文件的修改日期, 判断编译文件是否已经过期以及是否需要重复编译. 这个操作完全是自动进行的。
- 编译的文件是平台独立的, 对于相同的`library`能够在不同的系统中进行共享。



### Python有两种情况不会检查缓存

- 直接通过命令行加载的module, python不会重复编译并且保存`module`的结果.
- 如果没有原始的`module`, python也不会检查缓存。



### 对于python的一些建议

- 可以通过`-o`或者`-oo`开启命令减少编译的`module`的大小.
  - `-o`: 主要用来移除`assert statement`语法
  - `-oo`: 主要用来移除`assert statement`以及`__doc__`字符串信息.
- 读取`.pyc`文件不会比读取`.py`文件快.  对于`.pyc`文件而言, `.pyc`的文件已经被加载过。
- `compileall`能够为所有的`module`创建`.pyc`文件.



## dir() 方法

- `dir()` 可以找到`module`定义的名称列表

  ```python
  >>> import fibo, sys
  >>> dir(fibo)
  ['__name__', 'fib', 'fib2']
  >> dir(sys)
  ```

- 当`dir()`没有参数时，用于列出当前环境定义的所有的名称。

```python
>>> a = [1,2,3,4,5]
>>> import fibo
>>> fib = fibo.fib
>>> dir()
['__builtins__', '__name__', 'a', 'fib', 'fibo', 'sys']
```

> NOTE: 列出的所有的名称中, 包含了: `variables`, `modules`, `functions` etc



## Packages

- python中使用package来实现代码的结构化, `package`的使用使用使用`.`的方式来调用。
- `__init__.py`: 该文件是用来让Python相信当前的文件夹中包含了`package`的文件. 该文件能够避免在python中具有相同的文件夹名称
  - 同时`__init__.py`文件中能能够执行初始化代码
  - 设置`__all__`变量的设置
- 可以通过包名执行单个`module`的导入

```python
import sound.effects.echo

//导入子module时, 需要指定全限定包名
sound.effects.echo.echofilter(input, output, delay=0.7, atten=4)

// 导入子module的另一种方式, 这种方式可以避免使用包名前缀
from sound.effects import echo
echo.echofilter(input, output, delay=0.7, atten =4)

// 直接导入需要的function或者variables
from sound.effects.echo import echofilter
echofilter(input, output, delay=0.7, atten=4)
```

> NOTE: 在使用 `from package import item`, 其中`item`可以是package下的submodule, 也可以是定义在package下的`function`, `class`,`variable`. python首先判断当前定义在package之下, 如果判断失败, 则尝试当前的import当做一个module来加载, 如果仍然失败, 则抛出`ImportError`异常



### Importing * from Package

当前命令会到文件系统中, 查找submodule是否出现, 并且加载所有的submodule. 这种方式会花费较长的时间import sub-modules. 这种引入方式会有比较明显的无法想象的问题。



为了解决这样的问题, 可以在每个package中的`__init__.py`文件定义`__all__`. 这个变量在碰到了`from package import * `这样的命令时, 应当加载具体的某些`sub-modules`.



```python
__all__=["echo", "surround", "reverse"]
```

- 上面的定义意味着：在`from sound.effects import *`将会导入三个命名的`submodules`.

- 如果`__all__`没有定义, `from sound.effects import *`不会从`sound.effects`导入所有的`submodule`到当前的命名空间. 这个命令会保证`sound.effects`被导入到当前命名空间, 以及定义在当前`package`下的所有命名(包括: 定义在`__init__.py`).同事也包括了明确使用`import`命令加载过的submodule.

### Intra-package References

当package被加入到了一个subpackage的时候, 我们可以使用绝对导入指向到subpackage. 例如: `sound.filters.vocoder`需要使用在`sound.effects`的`echo`module, 我们可以通过`from sound.effects.import ech`来进行导入。



同时我们通过相对导入的方式来引入`module`,  我们通过`.`的方式来暗示当前`package`和`parent package`。例如:

```python
from . import echo
from .. import formats
from ..filters import equalizer
```

> NOTE：相对导入的方式依赖于当前的module, `main module	`的名称是`__main__`. 当前的module想要使用其他的module的功能, 必须使用绝对导入的方式.

### Packages in Multiple Directories

Packages支持多个特殊的属性,在package文件夹中的文件执行之前, . `__path__`指定持有package的`__init__.py`的文件夹列表, 



