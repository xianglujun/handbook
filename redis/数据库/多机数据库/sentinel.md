# Sentinel
哨兵模式
- 负责监控主从中所有的redis服务器的状态
- 当主redis发生了系统宕机之后, 并从当前主redis的从服务器中选出一个master用于主服务器. 并将其他从服务器连接到新的master之上
- 负责监听已经宕机的master服务器, 并监听master上线情况, 当master上线之后, 重新将master设置为新主服务器的从服务器。

## 启动并初始化Sentinel
启动一个`Sentinel`可以使用命令:
```sh
redis-sentinel /path/to/your/sentinel.conf

或者使用:
redis-server /path/to/your/sentinel.conf --sentinel
```

当一个Sentinel启动时, 它需要执行以下步骤:
- 初始化服务器
- 将普通Redis服务器使用的代码替换成Sentinel专用代码
- 初始化Sentinel 状态
- 根据给定的配置文件, 初始化Sentinel的监视主服务器列表
- 创建连向主服务器的网络连接。

### 初始化服务器
首先, Sentinel本质上只是一个运行在特殊模式下的Redis服务器, 所以启动Sentinel的第一步, 就是初始化一个普通的Redis服务器。

|功能|使用情况|
|:---|:------|
|数据库和键值对方面的命令, 比如`SET`,`DEL`,`FLUSHDB`   |不适用   |
|事务命令, 比如`MULTI`,`WATCH`   |不使用   |
|脚本命令, 比如`EVAL`   |不使用   |
|RDB持久化命令, 比如`SAVE`和`BGSAVE`   |不使用   |
|AOF持久化命令, 比如`BGREWRITEAOF`   |不使用   |
|复制命令, 比如`SLAVEOF`   |Sentinel内部可以使用, 但客户端不可以使用   |
|发布与订阅命令, 比如`PUBLISH`和`SUBSCRIBE`   |`SUBSCRIBE`,`PSUBSCRIBE`,`UNSUBSCRIBE`,`PUNSUBSCRIBE`四个命令在Sentinel内部和客户端都可以使用, 但`PUBLISH`命令只能在Sentinel内部使用   |
|文件事件处理器(负责发送命令请求, 处理命令回复)   |Sentinel内部使用, 但关联的事件处理器和普通Redis服务器不同   |
|时间时间处理器(负责执行serverCron函数)   |Sentinel内部使用, 时间时间的处理器仍然是`serverCron函数`, serverCron函数会调用`sentinel.c/sentinelTimer函数`, 后者包含了Sentinel要执行的所有操作   |

### 使用Sentinel专用代码
启动Sentinel的第二个步骤就是将一部分普通Redis服务器使用的代码替换成`Sentinel`专用代码。

`sentinelcmds`命令表也解释了为什么在`Sentinel`模式下, Redis服务器不能执行诸如`SET`,`DBSIZE`,`EVAL`等等这些命令, 因为服务器根本没有在命令表中载入这些命令, `PING`,`SENTINEL`,`INFO`,`SUBSCRIBE`,`UNSUBSCRIBE`,`PSUBSCRIBE`,`PUNSUBSCRIBE`这七个命令就是客户端可以对Sentinel执行的全部命令。

### 初始化Sentinel状态
在应用了Sentinel的专用代码之后, 接下来, 服务器会初始化一个`sentinelState`结构，这个结构保存了服务器中所有和Sentinel功能有关的状态:
```c
struct sentinelState {
  // 当前纪元, 用于实现故障转移
  unit64_t current_epoch;

  // 保存了所有被这个sentinel监视的主服务器,
  // 字典的键是主服务器的名字
  // 字典的值则是一个指向sentinelRedisInstance结构的指针
  dict * masters;

  // 是否进入了TILT模式
  int tilt;

  // 目前正在执行的脚本的数量
  int running_scripts;

  // 进入TILT模式的时间
  mstime_t tilt_start_time;

  // 最后一次执行时间处理器的时间
  mstime_t previous_time;

  // 一个FIFO队列, 包含了所有需要执行的用户脚本
  list *scripts_queue;
} sentinel;
```
### 初始化Sentinel状态的masters属性
Sentinel状态中的masters字典记录了所有被Sentinel监视的主服务器的相关信息， 其中:
- 字典的键是被监视主服务器的命令
- 而字典的值则是被监视主服务器对应的`sentinelRedisInstance`结构.

### 创建连向主服务器的网络连接
初始化Sentinel的最后一步是创建连向被监视服务器的网络连接, sentinel将成为主服务器客户端， 它可以向主服务器发送命令, 并从命令回复中获取相关的信息。

对于每个被sentinel监视的主服务器来说, sentinel会被创建两个连向主服务器的一步网络接口：
- 一个是命令连接, 这个链接专门用于向主服务器发送命令, 并接受命令回复
- 另一个是订阅链接，这个链接专门用于定于订阅主服务器的_sentinel_:hello频道。
- 、

## 获取主服务器信息
Sentinel默认会以每十秒一次的频率, 通过命令连接向被监视的主服务器发送INFO命令, 并通过分析INFO命令的回复来获取主服务器的当前状态。

通过分析主服务器返回的`INFO`命令回复, Sentinel可以获取以下两方面的信息:
- 一方面是关于主服务器本身的信息, 包括`run_id`域记录的服务器运行ID, 以及role域记录的服务器角色.
- 另一封面是关于主服务器属下所有从服务器的信息, 每个从服务器都由一个"slave"字符串开头的行记录, 每行的ip=域记录了从服务器的IP地址, 而port=域则记录了从服务器的端口号. 根据这些IP地址和端口号, sentinel无须用户提供从服务器的地址信息, 就可以自动发现从服务器。

对于新的从服务器而言, 在主服务器的`slaves`结构中没有对应的服务器信息, 因此会在发现的时候，判断为新的从服务器，从而为新的服务器创建服务结构的数据.

- 主服务器实例结构的`flags`属性的值为`SRI_MASTER`, 而从服务器实例结构的`flags`属性的值为`SRI_SLAVE`.
- 主服务器实例结构的`name`属性的值是用户使用`sentinel`配置文件设置的, 而从服务器实例结构的`name`属性的值则是`sentinel`根据从服务器的ip地址和端口号自动设置的。

## 获取从服务器信息
当Sentinel发现主服务器有新的从服务器出现时, sentinel除了回味这个心的从服务器创建响应的实例结构之外, sentinel还会创建链接到从服务器的命令连接和订阅链接.

sentinel会以每十秒一次的频率从从服务器中获取服务器的状态信息, 根据info命令的回复, sentinel会提取出以下信息:
- 从服务器的运行ID run_id;
- 从服务器的角色role
- 主服务器的IP地址master_host, 以及主服务器的端口号master_port'
- 主从服务器的链接状态`master_link_status`
- 从服务器的优先级`slave_priority`
- 从服务器的赋值偏移量`slave_repl_offset`

根据这些信息, sentinel会对从服务器的实例结构进行更新, sentinel根据上面的INFO命令回复对从服务器的实例结构进行更新之后

## 向主服务器和从服务器发送信息
在默认情况下, sentinel会以`每两秒一次`的频率, 通过命令连续向所有被监视的主服务器和从服务器发送以下格式的命令:
```sh
PUBLISH _sentinel_:hello "<s_ip>,<s_port>,<s_runid>,<s_epoch>,<m_name>,<m_ip>,<m_port>,<m_epoch>"
```
- 其中以`s_`开头的参数记录的是`sentinel`本身的信息, 各个参数的意义如下
- 而`m_`开头的参数记录的则是主服务器的信息, 各个参数的意义如下。 如果sentinel监视的是主服务器, 那么这些参数记录的就是主服务的信息; 如果sentinel正在监视的是从服务器, 那么这些参数记录的就是从服务器正在复制的主服务器的信息。

|参数|意义|
|:---|:---|
|s_ip   |sentinel的IP地址   |
|s_port   |sentinel的端口号   |
|s_runid   |Sentinel的运行ID   |
|s_epoch   |Sentinel当前的配置纪元(configuration epoch)   |
|m_name   |主服务器的命令   |
|m_ip   |主服务器的IP地址   |
|m_port   |主服务器的端口号   |
|m_epoch   |主服务器当前的配置纪元   |

sentinel 通过`PUBLISH`命令向主服务器发送信息:
> 127.0.0.1, 26379,....,0,mymaster,127.0.0.1,6379,0

## 接收来自主服务器和从服务器的频道信息
当sentinel与一个主服务器或者从服务器建立起订阅链接之后, sentinel就会通过订阅链接, 向服务器发送以下命令:
```sh
SUBSCRIBE _sentinel_:hello
```
Sentinel对`_sentinel_:hello`频道的订阅会一直持续到Sentinel与服务器的链接断开为止.

对于监视同一个服务器的多个sentinel来说, 一个sentinel发送的信息会被其他sentinel接收到, 这些信息会被用于更新其他sentinel队发送信息sentinel的认知, 也会用于更新其他sentnel对被监视服务器的认知。

如果其中一个sentinel对订阅消息发送了`_sentinel_:hello`消息, 那么其他sentinel也会接收到消息, 并对消息中的参数进行判断：
- 如果信息中记录的sentinel运行ID和接收信息的sentinel运行ID相同, 那么说明这条信息是自己发送的, sentinel将丢弃这条消息, 不做进一步处理.
- 相反地, 如果信息中记录的sentinel运行ID和接收信息的sentinel的运行ID不同, 那么说明这条信息是监视同一个服务器的其他sentinel发来的, 接收信息的sentinel将根据信息中各个参数，对响应主服务器的实例结构进行更新。

### 更新sentinels字典
sentinel在发送订阅消息的时候, 其他的sentinel会接收到消息, 并根据参数更新自己的`masters`信息
目标sentinel会在自己的sentinel状态的`masters`字典中查找对应的主服务器实例结构, 然后根据提取出的sentinel参数, 检查主服务器实例结构的sentinels字典中, 源sentinel的实例结构是否存在:
- 如果源sentinel的实例结构已经存在, 那么对源sentinel的实例结构进行更新
- 如果源sentinel的实例结构不存在, 那么说明源sentinel是刚刚开始监视主服务器的新sentinel, 目标sentinel会为源sentinel创建一个新的实例结构, 并将这个结构添加到sentinels字典里面。

### 创建连向其他sentinel的命令连接
当sentinel通过频道信息发现一个新的`Sentinel`时, 它不仅会为新sentinel在sentinels字典中创建响应的实例结构, 还会创建一个连向新`Sentinel`的命令连接, 而新Sentinel也会同样创建连向这个sentinel的命令连接, 最终监视同一个主服务器的多个sentinel将形成互相连接的网络。

#### Sentinel之间不会创建订阅链接
Sentinel在链接主服务器或者从服务器时, 会同时创建命令连接和订阅链接, 但是在链接其他Sentinel时, 却只会创建命令连接，而不创立订阅链接。因为因为Sentinel需要通过接受主服务器或者从服务器发来的频道信息来发现未知的新Sentinel, 所以才需要建立订阅链接, 而相互已知的Sentinel只需要使用命令连接来进行通信就够了。

## 检测主管下线状态
在默认情况下, Sentinel会以`每秒一次`的频率向所有与它建立了命令连接的实例(包括主服务器,从服务器, 其他sentinel在内)发送PING命令, 并通过实例返回的PING命令回复来判断是否在线。

实例对PING命令的回复可以分为以下两种情况:
- 有效回复: 实例返回`+PONG`,`-LOADING`,`-MASTERDOWN`三种回复中的其中一种。
- 无效回复: 实例返回除`+PING`,`-LOADING`,`MASTERDOWN`三种回复之外的其他回复, 或者在指定时限内没有返回任何回复。

Sentinel配置文件中的`down-after-milliseconds`选项指定了`Sentinel`判断实例进入主观下线所需的时间长度:`如果一个实例在down_after_milliseconds毫秒内, 连续向Sentinel返回无效回复, 那么Sentinel会修改这个实例所对应的实例结构, 在结构的flags属性中打开SRI_S_DOWN标识, 一次来表示这个实例已经进入主观下线状态`

#### 主观下线时长选项的作用范围
用户设置的`down_after_milliseconds`选项的值, 不仅会被Sentinel用来判断主服务器的主观下线状态, 还会被用于判断主服务器属下的所有从服务器, 以及所有同样监视这个主服务器的其他Sentinel的主观下线状态。

#### 多个Sentinel设置的主观下线时长可能不同
`down_after_milliseconds`选项另一个也需要注意的地方是, 对于监视同一个主服务器的多个Sentinel来说, 这些Sentinel所设置的`down_after_milliseconds`选项的值也可能不同. 因此, 当一个`Sentinel`将主服务器判断为主观下线时, 其他sentinel可能仍然会认为主服务器处于在线状态。

## 检查客观下线状态
当Sentinel将一个主服务器判断为主观下线后, 为了确认这个主服务器是否真的下线了，它会向同样监视这一主服务器的其他Sentinel进行询问, 看他们是否也认为主服务器已经进入了下线状态. 当sentinel从其他sentinel哪里接收到足够数量已下线判断之后, sentinel就会将从服务器判定为客户端下线, 并对主服务器执行`故障转移`操作。

### 发送SENTINEL is-master-down-by-addr命令
Sentinel使用:
```sh
SENTINEL is-master-down-by-addr <ip> <port> <current_epoch> <runid>
```
该命令用于询问其他Sentinel是否同意主服务器已下线, 命令中的各个参数意义如下:
|参数|意义|
|:---|:---|
|ip   |被Sentinel判断为主观下线的主服务器的IP地址   |
|port   |被Sentinel判断为主观下线的主服务器的端口号   |
|current_epoch   |Sentinel当前的配置纪元,用于选举领头Sentinel   |
|runid   |可以是`*`符号或者Sentinel的运行ID: `*`符号代表命令仅仅用于检测主服务器的可观下线状态, 而Sentinel的运行ID则用户选举领头Sentinel   |

### 接收SENTINEL is-master-down-by-addr 命令
当一个Sentinel接收到另一个Sentinel发来的`SENTINEL is_master_down_by`命令时, 目标Sentinel会分析并取出命令请求中包含的各个参数, 并根据其中的主服务器IP和端口号, 检查主服务器是否已下线, 然后向源Sentinel返回一条包含三个参数的Multi Bulk回复作为`SENTINEL is-is_master_down_by`命令的回复:
```sh
1) <down_state>
2) <leader_runid>
3) <leader_epoch>
```
|参数|意义|
|:---|:----|
|down_state   |返回目标Sentinel对主服务器的检查结果, 1- 代表主服务器已下线, 0- 代表主服务器未下线   |
|leader_runid   |可以是*符号或者目标Sentinel的局部领头Sentinel的运行ID: *- 符号代表命令仅仅用于检测主服务器的下线状态, 而局部领头Sentinel的运行ID则用于选举领头Sentinel   |
|leader_epoch   |目标Sentinel的局部领头Sentinel的配置纪元, 用于选举领头Sentinel, 仅在leader_runid的值不为* 时有效, 如果leader_runid的值为 * , 那么leader_epoch总为0   |

### 接收SENTINEL is-master-down-by-addr命令的回复
根据其他Sentinel发挥的`SENTINEL is-master-down-by-addr`命令回复, Sentinel将统计其他Sentinel同意主服务器已下线的数量, 当这一数量达到配置指定的可观下线所需的数量时, Sentinel会将主服务器实例结构`flags`属性的`SRI_O_DOWN`标志打开, 表示主服务器已经进入客观下线状态。

#### 客观下线状态的判断条件
当认为主服务器已经进入下线状态的Sentinel的数量, 超过Sentinel配置中设置的`quorum`参数的值, 那么改Sentinel就会认为主服务器已经进入可观下线状态。

```sh
sentinel monitor master 127.0.0.1 6379 2

那么包括当前sentinel在内, 只要总共有2个sentinel认为服务器已经进入下线状态, 那么当前sentinel就将主服务器判断为客观下线。
```

#### 不同sentinel判断客观下线条件的条件可能不同
对于监视同一个主服务器的多个Sentinel来说, 它们将主服务器标识为可观下线的条件可能也不相同: 当一个sentinel将主服务器判断为可观下线时, 其他sentinel可能并不是那么认为。

```sh
#sentinel 1
sentinel monitor master 127.0.0.1 6379 2

# sentinel 2
sentinel monitor master 127.0.0.1 6379 2
```

## 选举领头Sentinel
当一个主服务器被判断为可观下线时, 监视这个显现主服务器的各个Sentinel会进行协商, 选举出一个领头Sentinel, 并由领头Sentinel对下线主服务器执行故障转移操作.

- 所有在线的Sentinel都有被选为领头Sentinel的资格, 换句话说,监视同一个主服务器的多个在线Sentinel中的任意一个都有可能成为领头Sentinel.
- 每次进行领头Sentinel选举之后, 不论选举是否成功, 所有Sentinel的配置纪元的值都会自增一次. 配置纪元实际上就是一个计数器, 并没有什么特别的。
- 在一个配置纪元里面, 所有Sentinel都有一次将某个Sentinel设置为局部领头Sentinel的机会, 并且局部领头一旦设置, 在这个配置纪元里面就不能再更改
- 每个发现主服务器进入可观下线的Sentinel都会要求其他Sentinel将自己设置为局部领头Sentinel.
- 当一个Sentinel向另一个Sentinel发送`SENTINEL is-master-down-by-addr`命令, 并且命令中的`runid`参数不是"*"而是源sentinel的运行ID时, 这表示源Sentinel要求目标Sentinel将前者设置为后者的局部灵丘Sentinel.
- Sentinel设置局部领头Sentinel的规则是先到先得: 最想向目标Sentinel发送设置要求的源Sentinel将成为目标Sentinel的局部领头Sentinel, 而之后接收到的所有设置要求都会被目标Sentinel拒绝。
- 目标Sentinel在接收到`SENTINEL is-master-down-by-addr`命令之后, 将向源Sentinel返回一条命令回复, 回复中的`leader_runid`参数和`leader_epoch`参数分别记录了目标Sentinel的局部领头Sentinel的运行ID 和配置纪元。
- 源sentinel的实例结构是否存在接收到目标Sentinel返回的命令回复之后, 会检查回复中`leader_epoch`参数的值和自己的配置纪元是否相同，如果相同的话, 那么源Sentinel继续去除回复中的`leader_runid`参数, 如果`leader_runid`参数的值和源Sentinel的运行ID一致, 那么表示目标Sentinel将源Sentinel设置成了局部领头Sentinel.
- 如果有某个Sentinel被半数以上的Sentinel设置成了局部领头Sentinel, 那么这个Sentinel会成为领头Sentinel。
- 因为领头Sentinel的产生需要半数以上Sentinel的支持, 并且每个Sentinel在每个配置纪元里面只能设置一次局部领头Sentinel, 所以在一个配置纪元里面, 只会出现一个领头Sentinel.
- 在给定实现内, 没有一个Sentinel被选举为领头Sentinel, 那么各个Sentinel将在一段时间之后再次进行选举, 直到选出领头Sentinel为止。

## 故障转移
在选举产生领头Sentinel之后, 领头Sentinel将对已下线的主服务器执行故障转移操作, 该操作包含以下三个步骤：
- 在已下线主服务器属下的所有从服务器里面, 挑选出一个从服务器, 并将其转移为主服务器。
- 让已下线主服务器属下的所有从服务器改为复制新的主服务器
- 将已下线主服务器设置为新的主服务器的从服务器, 当这个旧的主服务重新上线时, 它就会成为新的主服务器的从服务器。

### 选出新的主服务器
故障转移操作第一步要做的就是在已下线主服务器属下的所有从服务器中，挑选出一个状态良好, 数据完整的从服务器，然后向这个从服务器发送`SLAVEOF no one`命令, 将这个服务器转换为主服务器。

#### 新的主服务器时怎样挑选出来的
领头Sentinel会将已下线主服务器的所有从服务器保存到一个列表里面，然后按照以下规则, 一项一项地对列表进行过滤:
- 删除列表中所有处于下线或者断线状态的从服务器, 这可以保证列表中剩余的从服务器都是正常在线的。
- 删除列表中所有最近`五秒`内没有回复过领头Sentinel的INFO命令的从服务器, 这可以保证在列表中剩余的从服务器都是最近成功进行过通信的
- 删除所有与已下线主服务器链接断开超过`down-after-milliseconds * 10`毫秒的从服务器: `down-after-milliseconds`选项指定了主服务器下线所需的时间, 而删除断开超过`down-after-milliseconds * 10`毫秒的从服务器, 则可以保证列表中剩余的从服务器都没有过早地与主服务器断开链接。这样可以保证从服务器保存的数据都是比较新的。

之后, 领头Sentinel将从服务器的优先级, 对列表中剩余的从服务器进行排序, 并选出其中优先级最高的从服务器。

如果有多个具有相同最高优先级的从服务器, 那么领头Sentinel 将按照从服务器的复制偏移量, 对具有相同最高优先级的所有从服务器进行排序, 并选出其中偏移量最大的从服务器。

> NOTE: 在发送`SLAVEOF no one`命令之后, 领头Sentinel会以`每秒一次`的频率(平时是每十秒一次), 向被升级的服务器发送`INFO`命令, 并观察命令回复中的角色(role)信息,当被升级服务器的role从原来的salve变为master时, 领头Sentinel就知道被选中的从服务器已经顺利升级为主服务器了。

### 修改从服务器的复制目标
当新的主服务器出现之后, 领头Sentinel下一步要做的就是, 让已下线主服务器下属的所有从服务器去复制新的主服务器, 这一动作可以通过向从服务器发送`SLAVEOF`命令来实现

### 将旧的主服务器变为从服务器
故障转移操作最后要做的是, 将已下线的主服务器设置为新的主服务器的从服务器。

因为旧的主服务器已经下线, 所以这种设置是保存在server1对应的实例结构里面的, 当server1从新上线时, Sentinel就会向它发送`SLAVEOF`命令, 让它成为`server2`的从服务器。
