## SortedMap学习

- key 必须继承`Comparable`接口或者继承`Comparator`的实例
- key无论进过多少次的比较, 都必须具有相同的结果

### 子类
- NavigableMap
  - TreeMap

## TreeMap
- 对于`get`.`containKey`,`put`的时间复杂度为`O(log(n))`
- 采用二叉树(红黑树)的实现原理进行存储数据, 可以在`Map`中定义一个`Comparator`或者`key`实现`Comparable`
- 通过`Comparator`或者`Comparable`来决定放在根节点的`left`或者`right`节点之上
- `key`不能为null
