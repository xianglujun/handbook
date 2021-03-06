# 并发问题的症状

# HashMap数据结构
HashMap通常会用这个指针数组作为分散所有的key, 当一个key被加入时, 会通过Hash算法通过key算出这个数组的下表`i`, 然后把这个插到table[i]中, 如果两个不同的key被算在了同一个i, 那么就叫冲突又叫做碰撞, 这样会在table[i]的索引上形成一个链表.

如果table[]的尺寸很小, 比如只有2个，如果要放进10个keys的话, 那么瓶装非常频繁，于是O(1)的查找算法，就变成了链表遍历，性能编程了O(n)，这是Hash表的缺陷

所以Hash表的尺寸和容量非常的重要。一般来说，Hash表这个容器当有数据要插入时, 都会检查容量有没有超过`thredhold`, 如果超过, 需要增大Hash表的尺寸, 这样一来, 整个Hash表里的元素都要被重新计算一遍, 这叫rehash, 这个`成本相当的大`

1. 如果存在hash冲突, 则以链表的形式存储数据
2. 如果链表的长度超过`8`, 则执行转换为`tree`的操作, 但是在转换树的时候, 需要判断table的长度是否超过`64`，如果没有超过, 则继续执行`resize`操作
3. 如果`HashMap`的长度超过64的时候，将链表转换为红黑数

## 多线程put后可能导致get死循环

## 多线程put的时候可能导致元素丢失
1. put非null元素后get出来的却是null
> 在1.8中, 扩容操作时, 在讲新的newTab替换老的数据时, 可能这时数据还没有写入到新的集合之中, 这时导致对应索引读取的值为NULL

2.
