# Mysql主备一致性

我们知道，mysql中的binlog可以用来归档，也可以用作主备同步。目前几乎所有的mysql高可用架构，都直接依赖于binlog, 虽然这些高可用架构已经呈现出越来越复杂的趋势，但都是从最基本的一主一从烟花过来的。



## Mysql主备的基本原理

在主备工作模式中，我们建议将Slave节点设置为readonly模式，这样做会有一下考虑:

- 有时候运营类的查询语句会被放到备库上去查，设置为只读模式可以防止误操作
- 防止切换逻辑有bug, 比如切换过程中出现双写，造成主备不一致
- 可以用readonly状态，判断节点的角色。

![img](.\a66c154c1bc51e071dd2cc8c1d6ca6a3.png)

slave节点跟master节点之间维持了一个长连接。master节点内部有一个线程(dump_thread)，专门用于服务slave的长连接，一个事务日志的同步的完整过程是这样的:

- 在slave节点上通过`change master`命令，设置master节点的IP, 端口，用户名，密码以及要从哪个位置开始请求binlog. 这个位置包含文件名和日志偏移量。
- 在slave节点上执行`start slave`命令，这时候slave会启动两个线程，分别为`io_thread`与`sql_thread`。其中`io_thread`负责与master建立连接
- master节点校验完成用户名、密码后，开始按照slave传过来的位置，从本地读取binlog, 并发送给slave 节点
- slave拿到binlog之后，写到本地文件，称为中转日志(relay log)
- sql_thread读取中转日志，分析出日志里的命令，并执行

## binlog三种存储格式

### binlog_format=STATEMENT

我们可以通过mysql客户端的方式做以下测试 具体的执行脚本如下：

```mysql
delete from t where a >=4 and t_modified<= '2018-11-10' limit 1
```

然后我们可以通过命令的方式，查看当前执行的binlog日志信息：

```mysql
show binlog events
```

具体可以看到如下的日志输出信息:

![image-20211023212753396](.\image-20211023212753396.png)

我们可以从日志中看到如下信息:

- `BEGIN`: 代表了一个事务的开始，与commit或者rollback命令相对应
- `DELETE`: 其次就是我们执行的delete语句，在执行delete语句指向，优先使用了`use test`的命令，表示我们需要使用的数据库名称。这么做可以保证日志在传到mysql备库的时候，不论当前工作线程在哪个库里，都能够正确地更新到test库的表t中。在delete之后，就是我们本来执行的delete的语句信息。
- `COMMIT`: 则写着`xid=15`。表示了当前的事务的提交。

> 在STATEMENT格式下，记录到binlog中的为执行的sql语句

### binlog_format=ROW

当我们只执行以上的语句的时候，实际上产生了一个warning信息，原始是当前的binlog设置的`STATEMENT`格式，并且语句中带有limit，所以这个命令可能是`unsafe`的。

如果在delete上带有limit, 可能会导致主备不一致的情况。

-  如果delete语句使用的是索引a, 那么根据索引a找到第一个满足条件的行，则删除a=4的记录
- 如果使用的是索引t_modified,那么删除的就是t_modified='2018-11-10'也就是a=5这一行数据

> 因为statement格式的日志中，实际上记录了执行的sql语句，这就可能导致在主备上执行的时候，因为选取的索引差异，导致主从数据不一致的情况产生。

而`ROW`格式与`STATEMENT`格式上存在比较大的差异，具体日志如下：

![img](.\d67a38db154afff610ae3bb64e266826.png)

在ROW格式的binlog中，我们可以看到没有了原来的SQL执行语句，而是替换成为了两个Event事件。

- `Table_map`: 用于说明接下来要操作的表是test库中的t表
- `Delete_rows`: 用于定义删除行为

其实，通过上面的`show binlog events`的语句，我们很难看到比较详细的信息，因此我们借助`mysqlbinlog`工具，用命令的方式查看具体的详细信息。从上图我们可以得知，binlog是从8900位置开始，因此我们在执行查看详细信息的时候，可以采用一下方式查看：

```mysql
mysqlbinlog -vv /data/master.000001 --start-position=8900
```

![img](.\c342cf480d23b05d30a294b114cebfc2.png)

从图中我们可以到一下信息：

- `server id 1`: 表示这个事务是在server_id=1的这个库上面执行的
- 每个event都有CRC32的值，这是因为我把参数binlog_checksum设置成为CRC32
- `Table_map`event与上面看到的相同，显示了接下来需要操作的表，map到的数字是226.当我们操作的时候，设计到多张表的时候, 每个表都由对应的Table_map event, 都会map到一个单独的数字，用于区分对不同表的操作。
- 我们在mysqlbinlog的命令中，使用了`-vv`参数是为了吧内容都解析出来，所以从结果里面可以看到各个字段的值
- `binlog_row_image`:的默认值是FLULL, 因此Delete_event里面，包含了删掉的行的所有字段信息的值。如果把binlog_row_image设置为MINIMAL, 则只会记录表要的信息。
- 最后是Xid Event, 用于表示事务被正确的提交了。

> 因此从上面可以看出， binlog_format使用row格式的时候，binlog里面记录了真实行的主键id, 这样binlog传到备库去的时候，肯定会删除对应的行，不会有主备删除不同行的问题。

### binlog_format=MIXED

既然STATEMENT存在主备不一致的为题，为什么不直接使用ROW解决主备不一致的问题呢？

- 因为STATEMENT格式的binlog可能导致主备不一致的问题，所以需要使用ROW格式
- 但是`ROW`的最大缺点时，占用更多的空间。例如一个delete语句删除了10万行的数据，但是statement只是一个SQL语句被记录到binlog中，占用几十个字节空间。但是如果使用rows格式的时候，需要将10万条记录都写入到binlog中，这样只会占用更大的空间，同时也消耗了更多的IO资源，影响执行速度。
- 因此`MIXED`的诞生是一个折中的方案，Mysql会自己判断SQL语句是否可能引起主备不一致，如果可能，就使用ROW格式。否则就使用statement格式。

> 如果mysql设置的binlog格式为statement时，基本上可以认为这是一个不合理的设置，至少应该设置为MIXED格式。

## 循环复制

![img](.\20ad4e163115198dc6cf372d5116c956.png)

通过上面图可以知道，M-S架构与双M结构唯一区别在于数据的相互复制，也就是互为主备。双M架构的好处在于，A和B之间总是互为主备关系。这样在主备发生切换时，就不需要手动的更改主备关系。

### 从节点开启binlog

从节点从master节点同步binlog之后，也需要生成binlog. 通过

```mysql
log_slave_updates=ON
```

该项配置表示，从节点在执行完成relay log之后，也会生成binlog.

在双M架构中，由于B在更新生成binlog之后，也会被A节点同步回去，这时就很容易产生循环复制的情况产生，可以通过以下两点来解决循环复制的问题：

- 规定两个库的`server id`必须不同，如果相同，则他们之间不能设定为主备关系
- 一个备库接到binlog并在重放的过程中，生成个与原binlog的server id 相同的新的binlog
- 每个库在收到从自己的主库发过来的日志后，线判断server id, 如果跟自己的相同，表示这个日志是自己生成的，就直接丢弃这个日志。
