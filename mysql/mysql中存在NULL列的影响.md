# NULL列对数据库的影响
## 1. NULL列的影响
Mysql 官方文档：
> NULL columns require additional space in the row to record whether their values are NULL. For MyISAM tables, each NULL column takes one bit extra, rounded up to the nearest byte.

《高性能mysql第二版》中描述：
> Mysql难以优化引用可空列表查询, 它会使索引, 索引统计和值更加复杂。可空列需要更多的存储空间。还需要mysql内部进行特殊处理。可空列被索引后，每条记录都需要一个额外的字节，还能导致MyISAM中固定大小的索引编程可变大小的索引.

## 2. 为什么不适用NULL
- 所有使用NULL值的情况, 都可以通过一个有意义的值的表示, 这样有利于代码的可读性和可维护性，并能从约束上增强数据的规范性
- NULL值到非NULL值的更新无法做到原地更新，更容易发生索引分裂，从而影响性能
> _但把NULL列改为NOT NULL带来的性能提升很小，除非确定它带来了问题, 否则不要把它当成优先的优化措施，最重要的是使用的列的类型的适当性_
- NULL值在timestamp类型下容易出问题, 特别是没有启动参数`explicit_defaults_for_timestamp`
- `NOT IN`, `!=`等负向条件查询在有NULL值的返回情况下返回永远为空结果, 查询容易出错
- NULL 列需要更多的存储空间: 需要额外字节作为判断是否为NULL的`标志位`

+-------------------------------------+
| 我要举个栗子，别拦着我                  |
+-------------------------------------+
```sql
-- 建表SQL
create table table_2 (
 `id` INT (11) NOT NULL,
user_name varchar(20) NOT NULL
)


create table table_3 (
 `id` INT (11) NOT NULL,
user_name varchar(20)
)

-- 初始化数据
insert into table_2 values (4,"zhaoliu_2_1"),(2,"lisi_2_1"),(3,"wangmazi_2_1"),(1,"zhangsan_2"),(2,"lisi_2_2"),(4,"zhaoliu_2_2"),(3,"wangmazi_2_2")

insert into table_3 values (1,"zhaoliu_2_1"),(2, null)

-- 1. NOT IN 字句在有NULL值的情况下返回永远为空结果，查询容易出错
select user_name from table_2 where user_name not in (select user_name from table_3 where id!=1)

-- 2. 单列索引不存在NULL值，复核索引不存全为NULL的值，如果列允许为NULL，可能会导致`不和预期`的结果集
-- 如果user_name允许为NULL, 索引不存储NULL值, 结果集中不会包含这些记录。所以，请使用`NOT NULL`约束以及默认值
select * from table_3 where user_name != 'zhaoliu_2_1'

-- 3. 如果在两个字段进行拼接: 首先需要各字段进行非NULL判断, 否则只要任意一个字段为空都会造成拼接结果为NULL
select CONCAT('1', NULL) from dual   -- 执行结果为NUL
+-------------------+
| CONCAT('1', NULL) |
+-------------------+
| NULL              |
+-------------------+

-- 4. 如果有NULL column存在的情况下, count(NULL column)需要格外注意, null值不会参与统计
select * from table_3
+------------------+
| count(user_name) |
+------------------+
|                1 |
+------------------+

-- 5、注意NULL字段的判断方式, `= NULL`将会得到错误的结果
-- 创建索引
create index IDX_test on table_3 (user_name)
-- 查询列值为NULL的数据
select * from table_3 where user_name is null;
+----+-----------+
| id | user_name |
+----+-----------+
|  2 | NULL      |
+----+-----------+
select * from table_3 where user_name = null;
`Empty set`

-- 6. 查看描述信息
desc select * from table_3 where user_name = null \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: NULL
   partitions: NULL
         type: NULL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: NULL
     filtered: NULL
        Extra: no matching row in const table
1 row in set, 1 warning (0.00 sec)

-- 7. 通过is null 判断空列
desc select * from table_3 where user_name is null \G;

*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: table_3
   partitions: NULL
         type: ref
possible_keys: IDX_test
          key: IDX_test
      key_len: 83
          ref: const
         rows: 1
     filtered: 100.00
        Extra: Using index condition
1 row in set, 1 warning (0.00 sec)

-- 测试存在NULL类需要更多的存储空间
alter table table_3 add index idx_user_name (user_name);
alter table table_2 add index idx_user_name (user_name);
explain select * from table_2 where user_name = 'zhaoliu_2_1';

*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: table_2
   partitions: NULL
         type: ref
possible_keys: idx_user_name
          key: idx_user_name
      key_len: `82`
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)

explain select * from table_3 where user_name = 'zhaoliu_2_1';

*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: table_3
   partitions: NULL
         type: ref
possible_keys: idx_user_name
          key: idx_user_name
      key_len: `83`
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)

-- 从该处可以看到, 为NULL的列要比非NULL的列多一个byte
```

## explain中key_len列的计算规则
>key_len 82 == 20 * 4(utf8mb4-4字节) + 2(存储varchar边长字符长度2字节,订场字段无需额外字节)

> key_len 83 = 20 * 4(utf8mb2 - 4字节) + 1(是否为Null的表示) + 2(存储varchar边长字符长度2字节,订场字段无需额外字节)
