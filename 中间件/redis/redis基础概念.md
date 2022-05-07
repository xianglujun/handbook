# redis的基础相关
## redis支持的数据结构
1. Strings
2. Hashs:
3. Lists:
4. Sets:
5. SortedSet

### Strings
是redis中最基本的数据类型, 虽然名称为Strings， 实际上也是一个map的结构, 提供了最基本的`set`,`get`,`incr`,`descry`的一些简便的操作

### Lists
在Redis Lists中, 对应的采用的是链表的形式(LinkedList)的实现, 这就意味着, 即使List中包含了百万的元素, 在其头部或者尾部添加一个元素，基本上一个常数级别的。

在redis中采用链表的原因是, 能够在很大的列表上新增元素。

如果在对于根据索引查询列表中的则，则可以使用`sorted set`列表

### Hashs
hashs 看起来就是一个hash的样子，由键值对组成。
值的注意的是: 小的hash被用特殊方式编码, 消耗的内存特别的小。

### sets
Redis Sets 是String 的无序的排列, SADD把元素添加到set当中. 对set也可以执行其他的操作, 比如给定一个特定的元素是否存在, 对不同的set求交集, 并集或者差等。
