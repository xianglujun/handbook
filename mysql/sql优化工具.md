# sql优化工具

1. 使用explain的方式查看sql执行计划
2. 通过Show Profile 分析SQL执行性能

## Explain

[explain查看sql执行计划](./SQL优化方法.md)

## Show Profile分析SQL执行性能

通过EXPLAIN 分析执行计划，仅仅是停留在分析SQL的外部执行情况，如果我们想深入分析到MYSQL内核中，从执行线程的状态和时间来分析的话，这个时候就需要选择Profile

Profile除了可以分析执行线程的状态和时间，还支持进一步选择`ALL`, `CPU`, `MEMORY`, `BLOCK IO`, `CONTEXT SWITCHES`等类型来查询SQL语句在不同系统资源上所消耗的时间。

```sql
SHOW PROFILE [type [, type]...]
[FOR QUERY n]
[LIMIT row_count [OFFSET offset]]

type参数:
| ALL: 显示所有的开销信息
| BLOCK IO: 阻塞的输入输出次数
| CONTEXT SWITCHES: 上下文相关开销信息
| CPU: 显示CPU的相关开销信息
| IPC: 接收和发送消息的相关开销信息
| MEMORY: 显示内存相关的开销，目前无用
| PAGE FAULTS: 显示页面错误相关开销信息
| SOURCE: 列出相应操作对应的函数名极其在源码中的调用位置
| SWAPS: 显示swap交换次数的相关开销信息
```

### 查看是否开启profiling

Show Profile默认从5.0.37版本开始支持的，可以通过:

```sql
select @@have_profiling

## 开启profiling
select @@profilings
set @@profilings

# 默认profile只记录最近的15条记录，可以通过设置`profiling_history_size`加大存储的记录条数

## 查看记录的sql列表
show profiles

## 查看具体的sql的执行性能
show profile for query 1190
```
