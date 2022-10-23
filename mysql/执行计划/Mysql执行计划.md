# mysql执行计划

## mysql执行计划的调用方式

- EXPLAIN SELECT ..

### 变体实现

1. EXPLAIN EXTENDED SELECT ...
   将执行计划"反编译"成SQL语句, 可以通过`SHOW WARNINGS` 可得到被MYSQL优化器优化之后的SQL语句

2. EXPLAIN PARTITIONS SELECT ...
   用于分区表的EXPLAIN的操作。

## 执行计划包含的信息

- id
- select_type
- table
- type
- possible_keys
- key
- key_len
- ref
- rows
- Extra

## id

是一串数字, 用于表示查询表的SELECT的语句或者执行表的顺序。数字越大，表示越先执行

## select_type

表示SELECT类型，常见的有`SIMPLE(普通查询, 即没有联合查询)`， `PRIMARY(主查询)`， `UNION(UNION中后面的查询)`， `SUBQUERY(子查询)`

## table

当前执行计划查询的表，如果给表起别名了，则显示别名信息

## partitions

访问分区表信息

## type

表示从表中查询到行所执行的方式，查询方式是SQL优化中一个很重要的指标, 结果值从好到差依次是: system > const> eq_ref > ref > range > ALL

- system/const: 表中只有一行数据匹配，此时根据索引查询一次就能找到对应的数据
- eq_ref: 使用为索引扫描，常见于多表链接中使用主键和唯一索引作为关联条件。
- ref：非唯一索引扫描，还常见于唯一所以最左侧匹配扫描
- range: 索引范围扫描
- index: 索引全表扫描，此时遍历整个索引树
- ALL: 表示全表扫描，需要遍历全表找到对应的行

## possible_keys:

表示可能使用到的索引

## key

实际使用到的索引

## key_len

当前使用的索引的长度

## ref

关联ID等信息

## rows

查找记录所扫描的行数

## filtered

查找到所需记录占总扫描记录数的比例

## Extra

额外的xinxi ssss

## 参考

[Mysql执行计划解读: https://mp.weixin.qq.com/s/9itEKlpXhrtlM98O_ryoAA](https://mp.weixin.qq.com/s/9itEKlpXhrtlM98O_ryoAA)
