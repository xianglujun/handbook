# Hive参数

## 1. hive当中的参数，变量都是以命名空间开头

| 命名空间     | 读写权限 | 含义                    |
| -------- | ---- | --------------------- |
| hiveconf | 可读写  | hive-site.xml当中的个配置变量 |
| system   | 可读写  | 系统变量，包含jvm运行参数        |
| env      | 只读   | 环境变量                  |
| hivevar  | 可读写  | hive -d key=value     |

变量可以通过`${}`方式进行引用，其中system, env下的变量必须以对应前缀开头。

## 2. hive参数设置方式

- 修改配置文件`${HIVE_HOME}/conf/hive-site.xml`

- 启动hive cli是，通过`--hiveconf key=value`的方式进行设置

- 进入cli之后，通过使用set命令设置

> 以上的设置方式中，第二种和第三种只是针对当前会话生效。

```shell
hive --hiveconf hive.cli.print.header=true
```

## 3. Hive set命令

在hive cli控制台可以通过set对hive中的参数进行查询、设置：

```sql
-- 设置变量的值
set hive.cli.print.header=true

-- 查看值
set hive.cli.print.header;

-- 查看所有的参数
set;
```

### 查看hive历史操作命令集

```shell
# ~/.hivehistory
```

### hive参数初始化配置

在当前用户目录下的`.hiverc`文件

```shell
~/.hiverc
```

如果没有，可直接创建该文件，将要设置的参数写到该文件中,hive启动运行时，会加载该文件中的配置。

## 4. Hive动态分区

开启支持动态分区

```sql
set hive.exec.dynamic.partition=true;
```

> 该配置默认为true

```sql
set hive.exec.dynamic.partition.mode=nostrict;
```

> 默认为strict严格模式(比如订单表以秒为单位创建分区，将会导致特别多的分区，严格模式一般不允许，但是非严格模式允许)

## 5. 开启支持分桶

```sql
set hive.enforce.bucketing=true
```

默认：false, 设置为true之后，mr运行时会根据bucket的个数自动分配reduce task个数。也可以通过`mapred.reduce.tasks`自己设置reduce任务个数，但是分桶时不推荐使用

> 一次作业产生的桶(文件数量)和reduce task个数一致

### 分桶操作

#### 往分桶中加载数据

```sql
insert into table bucket_table select column from tb1;

insert overwrite table bucket_table select columns from tb1
```

#### 桶表抽样查询

```sql
select * from bucket_table tablesample (bucket 1 out of 4 on columns)
```

- TABLESAMPLE语法：
  
  - TABLESAMPLE(BUCKET x out of y)
    
    - x：表示从哪个bucket开始抽取数据
    
    - y：表示为该表总bucket数的倍数或因子
  
  - 当表总bucket数为32时：
    
    - tablesample(bucket 3 out of 16), 抽取了哪些数据
      
      - 共抽取了(32/16)个bucket的数据，抽取第3、第19(16 + 3)个bucket的数据
    
    - TABLESAMPLE(bucket 3 out of 8)：
      
      - 共抽取了4(32/8)个bucket的数据，抽取3,11,19,27
    
    - TABLESAMPLE(bucket 3 out of 256)：
      
      - 共抽取了1/8(21/256)个bucket的数据，抽取第3个bucket的1/8数据

```sql
CREATE  table bucket1(
	id int, name string, age int
) row format delimited fields terminated by ',';
```

数据格式如下：

```textile

1,tom,11
2,cat,22
3,dog,33
4,hive,44
5,hbase,55
6,mr,66
7,alice,77
8,scala,88
```

有了以上的基础表之后，接下来创建分桶表：

```sql
create table bucket1_bucket(id int, 
name string,
age int
) clustered by (age) into 4 buckets
row format delimited fields terminated by ',';
```

有了分桶表之后，那么接下来就需要开启分桶配置：

```sql
set hive.enforce.bucketing=true
```

从原表中向分桶表中加入数据：

```sql
insert into table bucket1_bucket select id, name, age from bucket1;
```

开始执行抽样操作：

```sql
select id, name, age from bucket1_bucket tablesample(bucket 2 out of 4 on age)
```


