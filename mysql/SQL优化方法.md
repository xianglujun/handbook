# SQL优化方法

- 列类型尽量定义成数值类型, 且长度尽可能短, 如主键和外键, 类型字段等等
- 建立单列索引
- 根据需要建立多列索引
  - 当单列过滤之后还有很多数据, 那么索引的效率将会比较低, 即列的区分度较低
- 根据业务场景建立覆盖索引
  - 只查询业务需要的字段, 如果这些字段被索引覆盖, 将极大的提高查询效率
- 多表链接的字段上要建立索引
  - 如果使用外键, 在mysql中，外键默认是有索引的
- where条件上不要使用运算函数, 以免索引失效

# 对于sql优化的一些总结

- mysql嵌套子查询效率确实比较低
- 可以将其优化成连接查询
- 连接表时, 可以先用where条件对其表进行过滤, 然后做表连接
- 建立适合的索引, 必要时建立多列联合索引
- 学会分析sql执行计划, mysql会对sql进行优化， 所以分析执行计划很重要

# SQL 执行顺序

```SQL
(8)SELECT (9)DISTINCT <select_list>
(1)FROM <left_table>
(3)<join_type>JOIN <right_table>
(2)ON <join_condition>
(4)WHERE <where_condition>
(5)GROUP_BY<group_by_list>
(6)WITH {CUBE|ROLLUP}
(7)HAVING <having_condition>
(10)ORDER BY <order_by_list>
(11)LIMIT <limit_number>
```

## 覆盖索引优化查询

从辅助索引中查询的到的记录，从而不需要从聚簇索引查询获得，MySQL中将其称为覆盖索引。使用覆盖索引的好处很明显，我们不需要查询出包含整行记录的所有信息，因此可以减少大量的I/O操作。

通常在InnoDB中，除了查询部分字段可以使用覆盖索引来优化查询性能之外，统计数量也会用到。如果在执行`select count(*)`时，不存在辅助索引，此时会通过查询聚簇索引来统计行数，如果此时正好存在一个辅助索引，则会通过查询辅助索引来统计行数，减少I./O操作。

## 自增字段做主键优化查询

InnoDB创建主键做引默认为聚簇索引，数据被存放在B+树的叶子节点。也就是说，同一个叶子节点内的各个数据是按照主键顺序存放的。因此，每当一条新的数据插入时，数据库就汇根据主键插入到对应的叶子节点中。

如果们使用自增主键，那么每次插入的新数据机会按顺序加到当前索引节点的位置，不需要移动已有的数据，当页面写满，就汇自动开辟一个新页面，因为不需要重新移动数据，因此这种插入数据的方法效率非常高。

如果我们使用非自增主键，由于插入主键的索引都是随机的，因此每次插入新的数据时，都可能会插入到现有数据的中间某个位置，这将不得不移动数据来满足新数据的插入, 甚至需要从一个页面复制数据到另外一个页面，我们通常将这种情况称为页分裂。页分裂还有可能造成大量的内存碎片，导致索引结构的不紧凑， 从而影响查询效率。

## 前缀索引优化

前缀索引顾名思义就是使用某个字段中字符串的前几个字符建立索引。

索引Ian是存储在磁盘中的，而磁盘中最小分配单元是页，通常一个页的大小为`16kb`, 假设我们建立的索引的没给索引值大小为8KB, 则在一个页中，我们能够记录8个索引值，假设我们有8000行记录，则需要1000个也来存储索引。如果我们使用该索引查询数据，可能需要遍历大量的页，显然效率是地下的。

减小索引字段大小，尅增加一个页中存储的索引向，有效提高索引项的查询速度。在一些大字符串的字段作为索引时，使用前缀索引可以帮助我们减小索引项的大小。

> 不过，前缀索引是有一定的局限的，例如：order by 无法使用前缀索引，无法把前缀做引用作覆盖索引。

## 防止索引失效
