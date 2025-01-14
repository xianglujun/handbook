# HBase和Hive整合

## HBase表和Hive表关联



## 总结

1. 创建Hive的内部表，要求HBase中不能有对应的表

2. 创建Hive外部表，要求HBase一定要有对应的表

3. 映射关系通过一下语法实现

```sql
with serdeproperties ("hbase.columns.mapping":":kye,cf:id,cf:username,cf:age")
with serdeproperties
```

4. stored by 指定Hive中存储数据的时候，由该类来处理，该类会将数据放到HBase的存储中，同时Hive在读取数据的时候，由该类负责处理HBase的数据和Hive的对应关系。定义类型为`STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'`

5. 指定Hive表和HBase中的表对应关系，`outputtable`负责当`hive insert`数据的时候将数据写入到HBase具体表

6. 如果HBase中的表名和Hive中表名一致，则可以不指定`tblproperties`




