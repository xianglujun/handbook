# mysql并行复制

![img](.\bcf75aa3b0f496699fd7885426bc6245.png)

在上图中，`sql_thread`由`coordinator`来代替，而coordinator只负责从relay log中读取日志，并将日志分发给对应的worker线程执行。而worker的属性可以根据`slave_parallel_workers`设置，一般在32核物理机的情况下，该值取值为`8-16`即可。

coordinator分发的时候，需要满足以下两个基本要求:

- 不能造成更新覆盖，这就要求更新同一行的两个事务，必须被分发到同一个worker中
- 同一个事务不能被拆开，必须放到同一个worker中

## 5.6并行复制策略

官方MySQL5.6版本，支持了并行复制，只是支持的粒度是按库并行。

这个策略的并行效果，取决于压力模型。如果主库上有个多个DB, 并且各个DB的压力均衡，使用这个策略效果很好。

相比于按表和按行分发，这个策略有两个优势:

- 构造hash值的时候很快，只需要库名；并且一个实力上DB数也不会很多，不会出现需要构造100万个项这种情况
- 不要求binlog格式，因为statement格式的binlog也可以拿到数据库名称

## MariaDB的并行策略

在redo log中存在组提交(group commit)优化，而MariaDB的并行策略利用的就是这个特性：

- 能够在同一组里提交的事务，一定不会修改同一行
- 主库上可以并行执行的事务，备库上也一定可以并行执行

而MariaDB上的实现方式如下：

- 在一组里面一起提交的事务，有一个相同的commit_id, 下一组就是commit_id + 1
- commit_id 直接写入到binlog里面
- 传到备库应用的时候，相同的commit_id的事务分发到多个workder执行
- 这一组全部执行完成后, coordinator再去取下一批

## 5.7的并行复制策略

MySQL从5.7版本也提供了类似的功能，有参数`slave-parallel-type`来控制并行策略：

- DATABASE: 表示使用MySQL5.6版本的按库并行策略
- LOGICAL_CLOCK: 表示就是类似MariaDB的策略。不过， MySQL5.7这个策略，针对并行度做了优化。

![img](.\5ae7d074c34bc5bd55c82781de670c28.png)

从上图可以得知，不用等到commit阶段，只要能够达到redo log prepare 阶段，就表示事务已经通过锁冲突的检验了。

因此，在MySQL5.7并行复制策略的思想是：

- 同时处于prepare状态的事务，在备库执行是可以并行的
- 处于prepare状态的事务，与处于commit状态的事务直接，在备库执行时也是可以并行的

在binlog组提交的时候，有两个重要的参数:

- `binlog_group_commit_sync_delay`: 表示延迟多少微秒后才调用`fsync`
- `binlog_group_commit_sync_no_delay_count`: 表示累积多少次之后才调用`fsync`

这两个参数用于故意拉长binlog从write到fsync之间的时间，一次减少binlog的写盘次数。在MySQL5.7的并行策略里，它们可以用来制造更多的`同时处于prepare阶段的事务`, 这样就增加了备库复制的并行度。

## 5.7.22 并行复制策略

Mysql在5.7.22版本中新增加了一个新的并行复制策略，基于`WRITESET`的并行复制。

该复制策略可以通过`binlog-transaction-dependency-tracking`来控制，该参数有三个值:

- `COMMIT_ORDER`: 表示根据同时进入prepare和commit来判断是否可以并行的策略。
- `WRITESET`: 表示的是对于事务涉及更新的每一行，计算出这一行的hash值，组成集合`writeset`. 如果两个事务没有操作相同的行，也就是说他们的writeset没有交集，就可以并行
- `WRITESET_SESSION`: 是在WRITESET的基础上多了一个约束，即在主库上同一个线程先后执行的两个事务，在备库执行的时候，要保证相同的先后顺序。

> 为了唯一标识一行数据，这个hash值是通过`库名 + 表名 + 索引名 + 值`计算出来的。如果一个表上除了有主键索引外，还有其他唯一索引，那么对于每个唯一索引，insert语句对应的writeset就要多增加一个hash值。

这种官方实现有以下优势：

- writeset是在主库生成后直接写入到binlog里面的，这样在备库执行的时候，不需要解析binlog内容，节省了计算量
- 不需要把整个事务的binlog都扫一遍才能决定分发到哪个worker.更省内存。
- 由于备库的分发策略不依赖于binlog内容，所以benlog是statement格式也是可以的。

> 对于表上没有主键和外键约束的场景，WRITESET策略也是没法进行的，也是会暂时退化为单线程模型。