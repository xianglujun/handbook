# 问题排查

在虚拟货币的app上, 需要展示交易对的行情数据, 并通过接口`/v1/market/listMarketCap`根据传入的交易对列表查询行情详细信息

## 问题现象

重启系统, 能够正常访问数据, 在系统运行不到一分钟, 所有的http请求全部阻塞, 并没有返回数据

## 排查过程

1. `lsof -i:9081`
   通过该命令查看端口状态,
   
   ```sh
   java    27142 jenkins  215u  IPv4 101808939      0t0  TCP *:9081 (LISTEN)
   java    27142 jenkins  226u  IPv4 101923132      0t0  TCP bu-core-dubbo-zookeeper1:9081->10.200.173.208:54942 > (ESTABLISHED)
   java    27142 jenkins  230u  IPv4 101934538      0t0  TCP bu-core-dubbo-zookeeper1:9081->10.200.173.207:42054 > (ESTABLISHED)
   ```

通过显示信息来看, `9081`处于正常的监听状态

2. `netstat -apn | grep 9081`
   通过netstat查看当前的端口的链接状况, 发现`CLOSE_WAIT`状态的链接有60多个，初步断定应该是程序中发生了异常，导致程序无法正常结束线程的链接.

3. 查看error日志
   查看error日志, 发现日志堆栈输出中有`java heap space`字样，是在操作数据时, `mybatis`异常堆栈之后输出, 有两种情况导致该异常的输出
   
   - 在定时任务将1分钟数据归集到其他时间段时, 数据库中对应的`valume`字段出现溢出情况，导致插入数据失败
   - 前端接口因为请求频繁, 需要加载的交易对的列表数量 较多, 需要加载较多的数据库数据到内存之中
   - 定时任务需要加载很多的交易对的数据到内存之中，并且返回的交易信息结构较深, 并且数据量偏大
     因为以上的原因, 导致程序在接收到前端请求后, 内存中的数据无法及时的清理, 导致`jvm`出现了内存的溢出的情况。

## 解决办法

1. 调整`jvm`的堆大小为`-Xms100m -Xmx200m`
   
   ## 总结
   
   以上问题也是我第一次解决由于`jvm`导致出现的异常，仅一次记录排查的过程，以便日后借鉴
