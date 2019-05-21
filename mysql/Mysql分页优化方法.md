# mysql分页查询方法及其优化
## 方法一
语句样式: mysql中，可用如下方法： select * from 表名称 limit offset, pagesize
使用场景: 适用于数据量较少时的情况(元祖百/千级)
原因/缺点: 全表扫描, 速度会很慢，且有的数据库结果集返回不稳定. limit限制的是从结果集的M位置处取N条输出，其余抛弃

## 建立主键或唯一索引，利用索引
语句样式: mysql中，可用如下方法: select * from 表名称 where id_pk > (pageNum * pageSize) LIMIT pagesize
使用场景: 适用于数据量多的情况(元祖数上万)
原因: 索引扫描, 速度会很快

## 基于索引在排序
语句样式: mysql中，可用如下方法： select * from 表名称 where id_pk > (pageNum*pageSize) Order by id_pk asc limit pageSize
使用场景: 适用于数据量多的情况. 最好ORDER BY 后的列对象是`主键或唯一索引`, 使得 order by 操作利用索引被消除 单结果集是稳定的
原因: 索引扫描， 速度很快. 但Mysql的排序操作，`只有ASC，没有DESC`

## 基于索引使用`prepare`
_第一个问号表示pageNum, 第二?表示每页数据量_
语句样式: mysql中, 可用如下方法: prepare stmt_name from select * from 表名称 where id_pk > (? * ?) order by id_pk asc limit pagesize
使用场景: 大数据量
原因: 索引扫描，速度会很快, prepare 语句又比一般的查询快一点

## 利用mysql支持order操作可以利用索引快速定义元组，避免全表扫描
比如: 查询20000 到 20019行元组
```sql
select * from table where id_pk >= 20000 order by id_pk asc limit 20
```

## 利用"子查询/链接 + 索引"快速定位元组的位置, 然后再读取元组
### 利用子查询读取元组:
```sql
select * from table where id_pk <=
(select id from table order by id desc limit offset, pageSize)
order by id desc limit pagesize
```

### 利用链接示例
```sql
select * from table as t1
JOIN (select id from table order by id desc limt offset, pageseize) as t2
where t.id <= t2.id order by t1.id desc limit pagesize
```

> mysql 大数据量使用limit分页, 随着页码的增大, 查询效率低下

## 影响mysql分页的因素
- limit 语句的查询与起始记录的位置成正比
- mysql的limit语句方便, 但是对记录很多的表并不适合直接使用

# 对limit分页问题性能优化方法
## 利用表的覆盖索引加速分页查询
mysql在执行sql的时候, 如果利用了索引查询的语句中如果采用了覆盖索引，查询会很快。
因为利用索引查找有优化算法，且数据就在查询索引上面，就不用再去读取数据地址了。这样就节省了很多时间。mysql中也有相关索引缓存，在并发高的时候利用缓存就效果更好了。
```sql
select id from product limit 866613, 20
```

- 如果我们要查询所用的列，有两种方法, 一种采用`pk >=形式`， 另外一种采用`join`的方式
```sql
select * from product where id >=
(select id from product limit 866613, 20)
```
- 另外一种写法
```sql
select * from product a
join (select id from product limit 866613, 20) b
ON a.id = b.id
```

## 复合索引优化方法
> 如果对于有where条件, 又想走索引用Limit, 必须设计一个索引，将where放第一位, limit用到的主键放第2位，而且只能select主键
