# redis持久化
## 什么是redis持久化
持久化就是把内存的数据写到磁盘中去, 防止服务宕机了内存数据丢失

## redis 数据持久化方式
### RDB
rdb是Redis DataBase缩写
功能核心函数rdbSave和rdbLoad两个函数
- rdbSave是将对象保存到RDB文件中
- rdbLoad是将RDB文件中的数据加载到内存之中

### AOF
Aof 是Append-only file缩写
每当执行服务器任务或函数时, flushAppendOnlyFile函数会被调用, 这个函数执行以下两个工作
- WRITE: 根据条件, 将aof_buf中的缓存写入到AOF文件
- SAVE : 根据条件, 调用fsync或fdataasync函数, 将AOF文件保存到磁盘中
