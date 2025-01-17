## ZooKeeper的两种执行模式

ZooKeeper分为两种模式：独立模式(standalone)和仲裁模式(quorum)。

独立模式: 就是每个服务器单独运行, 服务器直接的数据不进行复制

仲裁模式:  就是服务器之间的数据进行相互复制, 并同时为客户端同时执行。

1. 仲裁模式
   在仲裁模式下, ZooKeeper复制集群中的所有服务器的数据数。如果让客户端等待每一个数据数的复制然后才能工作, 延迟问题就会很严重。

为了解决这个问题: 通过仲裁的方式, 保证所有的服务器集群中, 达到最小的法定人数即可为客户端提供服务。例如: 有5台机器, 只要任意三台数据复制完毕, 就能够为客户端提供服务。

> NOTE: 选择法定人数指定大小是一件非常重要的事情, 法定人数的数量需要保证不管系统发生延迟或者崩溃, 服务主动确认的任何更新请求需要保持下去, 知道另外一个请求替代它.

## 会话

在对ZooKeeper集合进行操作前， 一个客户端必须与服务建立会话。会话的概念非常重要, 对ZooKeeper的运行也非常关键。客户端对ZooKeeper提交的所有操作都是关联在一个会话上, 当一个会话因为某种原因为终止时, 在这个会话期间创建的临时节点将会消失。

会话提供了顺序的保证, 这就意味着一个会话的请求都是按照`FIFO`的顺序执行。通常, 一个客户端只有一个会话, 这时客户端请求按照`FIFO`的顺序执行。如果客户端有多个会话, `FIFO`的顺序将未必能够保持。

### 会话的状态和声明周期

一个会话的主要状态分为以下几种: `CONNECTING`, `CONNECTED`, `CLOSED`, `NOT_CONNECTED`. 状态的转换依赖于客户端与服务器端之间的各种事件的转换。
![会话的状态切换](../../img/zookeeper_session.png)

1. 当ZooKeeper客户端初始化之后, 将`NOT_CONNECTED`状态更改为`CONNECTING`的状态
2. 当客户端与ZooKeeper服务器建立连接之后, 则对应的状态变为`CONNECTED`
3. 当客户端连接超时或者没有收到服务器的响应时, 则对应的状态变为`CONNECTING`, 并尝试连接其他的服务器。如果可以连接到其他的服务器, 并且连接成功, 则状态继续回复为`CONNECTED`
4. 如果不能发现其他的服务器并连接, 则状态转换为`CLOSED`状态
5. 当应用显式的关闭连接，则状态变更为`CLOSED`状态

创建一个会话, 需要设置会话超时这个参数. 如果经过这个超时时间t接收不到这个会话的任何消息, 那么这个消息就会被设置为过期。

而对于客户端, 则需要在t/3的时间未收到任何消息, 则需要向客户端发送心跳。 2t/3的时间没有收到任何消息, ZooKeeper开始寻找其他的服务器。而此时, 客户端还有t/3的时间去寻找
