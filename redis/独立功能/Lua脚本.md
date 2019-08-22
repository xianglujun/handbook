# Lua脚本
Redis从2.6版本开始引入对Lua脚本的支持, 通过在服务器中迁入Lua环境, Redis客户端可以使用Lua脚本, 直接在服务器端原子地执行多个Redis命令。

## 创建并修改Lua环境
为了在Redis服务器中执行Lua脚本, Redis在服务器内嵌了一个Lua环境, 并对这个Lua环境进行了一些列修改, 从而确保这个Lua环境可以满足Redis服务器的需要.

Redis服务器创建并修改Lua环境的整个过程由一下步骤组成:
- 创建一个基础的Lua环境, 之后的所有修改都是针对这个环境进行的。
- 载入多个函数库到Lua环境里面, 让Lua脚本可以使用这些函数库来进行数据操作
- 创建全局表格redis, 这个表格包含了对redis进行操作的函数, 比如用于在lua脚本中执行redis命令的redis.call函数
- 使用redis自制的随机函数来替换lua原有的带有副作用的随机函数, 从而避免在脚本中引入副作用
- 创建排序辅助函数, lua环境使用这个辅助函数来对一部分redis命令的结果进行排序, 从而消除这个命令的不确定性
- 创建redis.pcall函数的错误报告辅助函数, 这个函数可以提供更详细的出错信息
- 对Lua环境中的全局环境进行保护, 防止用户在执行Lua脚本的过程中, 将额外的全局变量天添加到Lua环境中
- 将完成的Lua环境保存到服务器状态的Lua属性中, 等待执行服务器传来的Lua脚本

### 创建Lua环境
在开始的这一步，服务器首先调用Lua的 C API函数`lua_open`，创建爱你一个新的lua环境。

因为lua_open函数创建的只是一个基本的Lua环境，为了让这个lua环境可以满足redis操作要求, 接下来将对这个lua环境进行一系列的修改。

### 载入函数库
Redis修改lua环境的第一步, 就是将一下函数库载入到lua环境里面:
- 基础库: 这个库包含lua的核心函数. 另外, 为了防止用户从外部文件中引入不安全的代码，库中的`loadfile`函数会被删除
- 表格库（table library）: 这个库包含用于处理表格的通用函数。比如`table`,`concat`,`table.insert`,`table.remove`,`table.sort`等
- 字符串库(string library): 这个库包含用于处理字符串的通用函数, 比如用于对字符串进行查找的`string.find`函数, 对字符串进行格式化`string.format`函数, 查看字符串长度的`string.len`函数, 对字符串进行翻转的`string.reverse`
- 数学库(math library): 这个库是标准C语言数据库的接口, 它包括计算绝对值的`math.abs`函数, 返回多个数中的最大值和最小值`math.max`和`math.min`函数, 计算二次方根的`math.sprt`函数, 计算对数的math.log函数等.
- 调试库(debug library): 这个库提供了对程序进行调试所需的函数，比如对程序设置钩子和取的钩子的`debug.sethook`函数和`debug.gethook`函数, 返回给定函数相关信息的`debug.getInfo`函数, 为对象设置元数据的`debug.setmetable`函数, 获取对象元数据的`debug.getmetable`函数
- Lua cjson库: 这个库用于处理UTF-8编码的JSON格式, 其中`cjson.decode`函数将一个JSON格式的字符串转换为一个Lua值, 而cjson.encode函数将一个Lua值序列化为JSON格式的字符串。
- Struct库: 这个库用于在lua值和C结构之间进行转换, 函数`struct.pack`将多个lua值打包成一个类结构字符串，而函数`struct.unpack`则从一个类结构字符串中解包出多个lua值
- Lua cmsgpack: 这个库用于处理MessagePack格式的数据, 其中`cmsgpack.pack`函数将lua值转换为`MessagePack`数据, 而`cmsgpack.unpack`函数则将MessagePack数据转换为lua值

### 创建redis全局表格
在这一步, 服务器将在Lua环境中创建一个redis表格, 并将它设为全局变量, 这个redis表格包含以下函数:
- 用于执行Redis命令的`redis.call`和`redis.pcall`函数
- 用于记录Redis日志的`redis.log`函数, 以及相应的日志级别(level)常量:`redis.LOG_DEBUG`,`redis.LOG_VERBOSE`,`redis.LOG_NOTICE`以及`redis.LOG_WARNING`
- 用于计算`SHA1`校验和的`redis.sha1hex`函数
- 用于返回错误信息的`redis_error.reply`函数和`redis.status_reply`函数

在这些函数里面, 最常用也是最重要的要数`redis.call`函数和`redis.pcall`函数, 通过这两个函数, 用户可以直接在Lua脚本中执行Redis命令。

### 使用Redis自制的随机函数来替换Lua原有的随机函数
为了保证相同的脚本可以在不同的机器上产生相同的记过, Redis要求所有传入服务器的lua脚本, 以及lua环境中的所有函数, 都必须是无副作用的纯函数.

但是, 在之前载入lua环境的`math`函数库中, 用于生成随机数的`math.random`函数和`math.randomseed`函数都是带有副作用的, 他们不符合Redis对lua环境的服务作用要求.

因为这个原因, Redis使用自制的函数替换了math库中原有的math.random函数和`math.randomseed`函数, 替换之后的两个函数有以下特征:
- 对于相同的seed来说,`math.random`总产生相同的随机数序列, 这个函数是一个纯函数
- 除非在脚本中使用`math.randomseed`显式地修改seed, 否则每次运行脚本时, lua环境都使用固定的`math.randomseed(0)`语句来初始化`seed`

### 创建排序辅助函数
Redis将SMEMBERS这种在相同数据集上可能会产生不同输出的命令称为`带有不确定性的命令`, 这些命令包括：
- SINTER
- SUNION
- SDIFF
- SMEMBERS
- HKEYS
- HVALS
- KEYS

为了消除这些命令带来的不确定性, 服务器会为lua环境创建一个排序辅助函数`redis_compare_helper`， 当lua脚本执行完一个带有不缺性命令之后, 程序会使用`_redis_compare_helper`作为对比函数， 自动调用`table.sort`函数对命令的返回值做一次排序, 以此来保证相同的数据集总是产生相同的输出.

### 创建redis.pcall函数的错误报告辅助函数
在这一步, 服务器将为Lua环境创建一个名为`_redis_err_handler`的错误处理函数, 当脚本调用`redis_pcall`函数执行Redis命令，并且被执行的命令出现错误时, `_redis_err_handler`就会打印出错代码的来源和发生错误的次数, 为程序的调试提供方便。

### 保护Lua的全局环境
在这一步, 服务器将对Lua环境中的全局变量进行保护, 确保传入服务器的脚本不会因为忘记使用`local关键字而将额外的全局变量添加到lua环境`.

因为全局便令保护的原因, 当一个脚本试图创建一个全局变量时, 服务器将报告一个错误:
```sh
EVAL "x = 10" 0
```

除此之外, 试图获取一个不存在的全局变量也会引发一个错误：
```sh
redis> EVAL "return x" 0
```

不过Redis并未禁止用户修改已存在的全局变量, 所以在执行Lua脚本的时候, 必须非常小心, 以免错误地修改了已经存在的全局变量.

### 将lua环境保存到服务器状态的lua属性里面
经过以上的一系列修改, Redis服务器对Lua环境的修改工作到此就结束了, 在左后的一步, 服务器会将Lua环境和服务器状态的lua属性关联起来。

因为Redis使用串行化的方式来执行Redis命令, 所以在任何特定时间里, 最多都只会有一个脚本能够被放进lua环境里面运行，因此，真个Redis服务器只需要创建一个lua环境即可.

## Lua环境协作组件
除了创建并修改Lua环境之外, Redis服务器还创建了两个用于与Lua环境进行协作的组件, 他们分别是负责执行Lua脚本中的Redis命令的伪客户端，以及用于保存lua脚本的`lua_scripts`字典。

### 伪客户端
因为执行Redis命令必须有相应的客户端状态, 所以为了执行Lua脚本中包含的Redis命令, Redis服务器专门为Lua环境创建了一个伪客户端, 并由这个伪客户端专门负责处理Lua脚本中包含的所有Redis命令。

Lua脚本使用`redis.call`函数或者`redis.pcall`函数执行一个Redis命令, 需要完成以下步骤:
- Lua环境将`redis.call`函数或者`redis.pcall`函数想要执行的命令传给伪客户端
- 伪客户端将脚本想要执行的命令传给命令执行器
- 命令执行器执行伪客户端传给它的命令, 并将命令的执行结果返回给伪客户端
- 伪客户端接收命令执行器返回的命令结果, 并将这个命令结果返回给Lua环境
- Lua环境在接收到命令结果之后, 将该结果返回给redis.call函数或者redis.pcall函数
- 接收到结果的redis.call函数或者redis.pcall函数会将命令结果作为函数返回值返回给脚本中的调用者。

### lua_scripts 字典
除了伪客户端之外, Redis服务器为Lua环境创建的另一个协作组件是`lua_scripts`字典, 字典的键为某个lua脚本的`SHA1`校验和, 而字典的值则是`SHA1`校验和对应的Lua脚本：
```c
struct redisServer {
  dict *lua_scripts;
}
```

Redis 服务器会将所有被`EVAL` 命令执行过的Lua脚本, 以及所有被`SCRIPT LOAD`命令载入过的`Lua`脚本都保存到`lua_scripts`字典里面:

`lua_scripts`字典有两个作用,
- 实现`SCRIPT EXISTS`命令
- 实现脚本复制功能

## EVAL命令的实现
`EVAL`命令的执行过程可以分为以下三个步骤:
- 根据客户端给定Lua脚本, 在Lua环境中定义一个Lua函数
- 将客户端给定的脚本保存到`lua_scripts`字典, 等待将来进一步使用
- 执行刚刚在lua环境中定义的函数, 以此来执行客户端给定的lua脚本

### 定义脚本函数
当客户端向服务器发送`EVAL`命令，要求执行某个lua脚本的时候, 服务器首先要做的就是lua环境中, 为传入的脚本定义一个与这个脚本相对应的lua函数， 其中, lua函数的名字由`f_`前缀加上脚本`SHA1`校验和组成, 而函数的体则是脚本本身。

使用函数来保存客户端传入的脚本有以下好处:
- 执行脚本的步骤非常简单, 只要调用与脚本相对应的函数即可
- 通过函数的局部性来让lua环境保持清洁, 减少了垃圾回收的工作量, 并且避免了使用全局变量
- 如果某个脚本所对应的函数在lua环境中被定义过至少一次, 那么只要记得这个脚本的`SHA1`校验和, 服务器就可以在不知道脚本本身的情况下, 直接通过调用Lua函数来执行脚本, 这是`EVALSHA`命令的是实现原理.

### 将脚本保存到`lua_scripts`字典
`EVAL`命令要做的第二件事就是将客户端传入的脚本保存到服务器的`lua_scripts`字典里面.

### 执行脚本函数
在为脚本定义函数, 并且将脚本保存到`lua_scripts`字典之后, 服务器还需要设置钩子, 传入参数之类的准备动作, 才能正式开始执行脚本。
真个准备和执行脚本的过程如下:
- 将`EVAL`命令中传入的键名(key name)参数和脚本参数分别保存到`KEYS`数组和`ARGV`数组, 然后将这个连个数组作为全局变量传入到lua环境里面。
- 为Lua环境装载超时处理钩子(hook), 这个钩子可以在脚本出现超时运行情况时, 让客户端通过`SCRIPT KILL`命令停止脚本, 或者通过`SHUTDOWN`命令直接关闭服务器。
- 执行脚本函数
- 移除之前装载的超时钩子
- 将执行脚本函数所得的结果保存到客户端状态的输出缓冲区里面, 等待服务器将结果返回给客户端
- 对Lua环境执行垃圾回收操作.

## EVALSHA 命令的实现
本章前面介绍`EVAL`命令的实现时说过, 每个被`EVAL`命令成功执行过的lua脚本, 在lua黄经理面都有一个与这个脚本相对应的lua函数, 函数名字由`f_`前缀加上40个字符长的SHA1校验和组成,.

只要脚本对应的函数曾经在Lua环境里面定义过, 那么即使不知道脚本的内容本身, 客户端也可以根据脚本的SHA1校验和来调用脚本对应的函数, 从而达到执行脚本的目的, 这就是EVALSHA命令的实现原理。

```sh
EVALSHA "DFDFDDFDFDFD" 0
```

## 脚本管理命令的实现
除了EVAL命令和EVALSHA命令之外, Redis中与Lua脚本有关的命令还有四个, 他们分别是`SCRIPT FLUSH`,`SCRIPT EXISTS`,`SCRIPT LOAD`,`SCRIPT KILL`命令.

### SCRIPT FLUSH
`SCRIPT FLUSH`命令用于清除服务器中所有和Lua脚本有关的信息, 这个命令会释放重建`lua_scripts`字典, 关闭现有的`Lua`环境并重新创建一个新的Lua环境.

### SCRIPT EXISTS
`SCRIPT EXISTS`命令根据输入的`SHA1`校验和, 检查校验和对应的脚本是否存在于服务器中。

`SCRIPT EXISTS`命令是通过检查给定的校验和是否存在于`lua_scripts`字典来实现的.

### SCRIPT LOAD
`SCRIPT LOAD`命令所做的事情和`EVAL`命令执行脚本时所做的前两步完全一样: 命令首先在Lua环境中为脚本创建相对相应的函数, 然后再将脚本保存到`lua_scripts`字典里面。

在完成了这些步骤之后, 客户端就可以使用`EVALSHA`命令来执行前面被`SCRIPT LOAD`命令载入脚本了。

```SH
redis> SCRIPT LOAD "return 'i'"
redis> EVALSHA "2f31ba2bb6d6a0f42cc159d2e2dad55440778de3" 0
```

### SCRIPT KILL
如果服务器设置了`lua-time-limit`配置选项, 那么在每次执行lua脚本之前, 服务器都会在Lua环境里面设置一个超时处理钩子(hook).

超时处理钩子在运行脚本期间, 会定期检查脚本已经运行了多久时间, 一旦钩子发现脚本的云心改时间已经超过了`lua-time-limit`选项配置的时长, 钩子将定期在脚本运行的间隙中, 查看是否有`SCRIPT KILL`命令或者SHUTDOWN命令到达服务器。

如果超时运行的脚本未执行过任何写入操作, 那么客户端可以通过`SCRIPT KILL`命令来指示服务器停止执行这个脚本，并向执行该脚本的客户端发送一个错误回复. 处理完`SCRIPT KILL`命令之后, 服务器可以继续运行。

如果脚本已经执行过写入操作, 那么客户端只能用`SHUTDOWN nosave`命令来停止服务器, 从而防止不合法数据写入到数据库中。

## 脚本复制
与其他普通Redis命令一样, 当服务器运行在复制模式之下时, 具有写性质的脚本命令也会被复制到从服务器，这些命令包括`EVAL`,`EVALSHA`,`SCRIPT FLUSH`，`SCRIPT LOAD`

### 复制EVAL, SCRIPT FLUSH, SCRIPT LOAD命令
Redis复制Eval，SCRIPT FLUSH, SCRIPT LOAD三个命令的方法和复制其他普通Redis命令的方法一样, 当主服务器执行完以上三个命令的其中一个时, 主服务器就会直接将被执行的命令传播给所有从服务器。

#### EVAL
对于EVAL命令来说, 在主服务器执行的Lua脚本同样会在所有从服务器中执行。主服务器在执行之歌EVAL命令之后, 将向所有的从服务器传播这条EVAL命令, 从服务器会接收并执行这条EVAL命令，最终结果是, 主从服务器双方都会将数据库`msg`的键设置为`hello world`, 并将命令保存在脚本字典里面`lua_scripts`
```sh
EVAL "RETURN redis.call('SET', KEYS[1], ARGV[1])" 1 "msg" "hello world"
```

#### SCRIPT FLUSH
如果客户端向主服务器发送`SCRIPT FLUSH`命令, 那么主服务器也会想所有从服务器传播`SCRIPT FLUSH`命令.

最终的结果是, 主从服务器双方都会重置自己的lua环境，并清空自己的脚本字典。

#### SCRIPT LOAD
如果客户端使用`SCRIPT LOAD`命令, 主服务器载入一个Lua脚本, 那么主服务器将向所有从服务器传播相同的SCRIPT LOAD命令, 使得所有从服务器会载入相同的lua脚本。

### 复制EVALSHA命令
EVALSHA命令是所有与Lua脚本有关的命令中, 复制操作最复杂的一个。因为主服务器和从服务器载入Lua脚本的情况有可能有所不同, 所以主服务器不像复制EVAL命令, SCRIPT LOAD,SCRIPT FLUSH命令那样, 直接将EVALSHA命令传播给其他服务器。对于一个在主服务器被成功执行的EVALSHA命令来说, 相同的EVALSHA命令在从服务器执行时可能出现脚本未找到错误。

为了防止主从服务器加载lua脚本的差异, Redis要求主服务器在传播EVALSHA命令的时候, 必须确保EVALSHA命令要执行的脚本已经被所有从服务器载入过, 如果不能确保这一点的话, 主服务器将EVALSHA命令转换一个等价的EVAL命令, 然后通过EVAL命令来代替EVALSHA命令。

传播EVALSHA命令, 或者将EVALSHA命令转成EVAL命令, 都需要用到服务器状态的`lua_scripts`字典和`repl_scriptcache_dict`字典。

#### 判断传播EVALSHA命令是否安全的方法
主服务器使用服务器状态的`repl_scriptcache_dict`字典记录自己已经将哪些脚本传播给了所有从服务器.

```c
struct redisServer {
  dict *repl_scriptcache_dict;
}
```
`repl_scriptcache_dict`字典的键是一个个Lua脚本的SHA1校验和, 而字典的值则全部都是NULL,当一个校验和传播给了所有从服务器, 主服务器可以直接向从服务器传播包含这个SHA1校验和的EVALSHA命令, 而不必担心从服务器会出现脚本找不到错误。

如果一个脚本的SHA1校验和存在于`lua_scripts`字典, 但是却不存在与`repl_scriptcache_dict`字典, 那么说明校验和对应的lua脚本已经被主服务器载入, 但是没有传播给所有从服务器, 如果我们尝试向从服务器传播包含这个`SHA1`校验和的EVALSHA命令, 那么至少有一个从服务器会出现脚本未找到错误。

#### 清空`repl_scriptcache_dict`字典
每当主服务器添加一个新的从服务器时, 主服务器会清空自己的`repl_scriptcache_dict`字典, 这是因为随着新从服务器出现,`repl_scriptcache_dict`字典里面记录的脚本已经不再被所有从服务器载入过, 所以主服务器会清空`repl_scriptcache_dict`字典，强制自己重新向所有从服务器传播脚本，从而确保新的从服务器不会出现脚本为找到错误。

#### EVALSHA命令转成EVAL命令的方法

具体的转换方法如下:
- 根据SHA1校验和sha1, 在lua_scripts字典中查找sha1对应的lua脚本script
- 将原来的EVALSHA命令请求改写成EVAL命令请求, 并且校验和SHA1改成脚本script. 至于`numkeys`,`key`,`arg`等参数保持不变

```sh
EVALSHA "FDFDFDFDFDFDFDF"

- 最终被改成命令:
EVAL "return 'hello world'" 0
```

- 如果一个SHA1值所对应的Lua脚本没有被所有从服务器载入过, 那么主服务器可以将EVALSHA命令转换成等价的EVAL命令，然后通过传播等价的EVAL命令来代替原本想要传播的EVALSHA命令, 因此来产生相同的脚本执行效果，并确保所有从服务器都不会出现脚本未找到错误。
- 因为主服务器在传播玩EVAL命令之后, 会将被传播脚本的SHA1校验和添加到`repl_scriptcache_dict`字典里面, 如果之后EVALSHA命令再次指定这个SHA1校验和, 从服务器就可以直接传播`EVALSHA`命令, 就不必再次对EVALSHA命令进行转换。

#### 传播EVALSHA命令的方法
当主服务器成功在本机执行完一个EVALSHA命令之后, 它将根据EVALSHA命令指定的SHA1校验和是否存在于`repl_scriptcache_dict`字典来决定是想从服务器传播EVALSHA命令还是EVAL命令:
- 如果`EVALSHA`命令指定的SHA1校验和存在于`repl_scriptcache_dict`字典, 那么主服务器直接向从服务器传播`EVALSHA`命令
- 如果`EVALSHA`命令指定的SHA1校验和不存在与`repl_scriptcache_dict`字典, 那么主服务器会将`EVALSHA`命令转换成等价的EVAL命令, 然后传播这个等价的`EVAL`命令，并将`EVALSHA`命令指定的SHA1校验和添加到`repl_scriptcache_dict`字典里面。
