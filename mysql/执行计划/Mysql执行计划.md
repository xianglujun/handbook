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

1. id
是一串数字, 用于表示查询表的SELECT的语句或者执行表的顺序。






## 参考
[Mysql执行计划解读: https://mp.weixin.qq.com/s/9itEKlpXhrtlM98O_ryoAA](https://mp.weixin.qq.com/s/9itEKlpXhrtlM98O_ryoAA)
