# Hive Lateral View、试图和索引

## Lateral View

- Lateral View 用于和UDTF函数(explode, split)结合来使用

- 首先通过UDTF函数拆分成多行，再将多行结果组合成一个支持别名的虚拟表

- 主要解决在select使用UDTF做查询的过程中，查询只能包含单个UDTF，不能包含其他字段，以及多个UDTF问题

```sql
lateral view udtf(expression) tablealias as columnAlias('', columnAlias) 
```

使用方式如下：

```sql
select id, mycol1, mycol2, mycol3 from table_name
lateral view explode(column1) mytable1 as mycol1
lateral view explode(column2) mytable2 as mycol2, mycol3
```

## Hive视图

和关系型数据库中的普通视图一样，hive也支持视图。

特点：

- 不支持物化视图

- 只能查询，不能做加载数据操作

- 视图的创建，只是保存一份元数据，查询视图时才执行对应的子查询

- view定义中若包含了order by / limit语句，当查询视图时也进行了order by / limit语句操作，view当中定义的优先级更高。

### 创建视图

```sql
create view [if not exists] [db_name.]view_name 
[(column_name [comment column_comment],)]
[COMMENT view_comment]
[TBLPROPERTIES(property_name=property_value..)]
as select ..
```

### 删除视图

```sql
drop view [if exists] [db_name.]view_name
```

## Hive索引

所以主要目的是优化查询和检索性能。

### 创建索引

```sql
create index t1_index on table person2(name)
as 'org.apache.hadoop.hive.ql.index.compact.CompactIndexHandler'
with defered rebuild
in table t1_index_table;
```

- as：用来指定索引器

- in table：指定索引表，若不指定默认生成在`default_person_t1_index_`表中

### 查询索引

```sql
show index on table_name
```

### 重建索引

```sql
alter index index_name on table_name rebuild;
```

重建完毕之后，再次使用有索引的数据，即通过select查询数据

### 删除索引

```sql
drop index [if exists] index_name on table_name;
```
