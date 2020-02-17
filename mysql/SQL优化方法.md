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
