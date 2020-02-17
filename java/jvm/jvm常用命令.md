<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [jvm的常用命令](#jvm的常用命令)
	- [jps](#jps)
		- [jps相关参数](#jps相关参数)
		- [实例](#实例)
	- [jstack](#jstack)
		- [分析CPU使用100%的原因](#分析cpu使用100的原因)
	- [jmap](#jmap)
	- [jinfo](#jinfo)
	- [jstat](#jstat)
	- [javap](#javap)

<!-- /TOC -->
# jvm的常用命令
## jps
> 显示当前java的进程以及相关参数
### jps相关参数
- `-q` 只显示`pid`, 不显示`class`名称, `jar`名称以及`main`方法的参数
- `-m` 输出传递给main的参数
- `-l` 输出应用程序`main`, `class`的完整`package`名称或者应用程序`jar`包的完成路径名
- `-v` 输出传递给`jvm`的参数

备注: 也可以使用`ps aux | grep 项目名称`查看对应的`pid`信息

### 实例
> jps -l -m -v

```linux
16513 eureka-service-0.0.1-SNAPSHOT.jar -Xmx100m -Xms100m -XX:+UseConcMarkSweepGC -Dserver.port=8781 -Deureka.client.serviceUrl.defaultZone=http://10.200.173.48:8771/eureka/,http://10.200.173.48:8761/eureka/ -Deureka.client.register-with-eureka=true -Deureka.client.fetch-registry=true
24577 bitun-ability-channel-service-1.0-SNAPSHOT.jar -Xmx100m -Xms100m -XX:+UseConcMarkSweepGC
738 bitun-circuit-board-service-1.0-SNAPSHOT.jar -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=19091 -Dcom.sun.management.jmxremote.ssl=false -Xmx100m -Xms100m -XX:+UseConcMarkSweepGC
```

## jstack
> 用于生成当前java虚拟机当前时刻的线程快照
### 分析CPU使用100%的原因
1. `top`查看占用CPU最多的线程
2. `top -Hp pid` 查看进程下的所有线程的运行情况(`shift+p`按照CPU使用排序; `shift+m`按照内存排序)
3. `printf '%x' pid ` 转换为16进制
4. `jstact`查看进程快照, `jstack pid | grep -C 20 a`

## jmap
> 打印指定java进程(核心文件, 远程调试服务器)的共享对象内存映射或读内存映射。

> 堆dump反应的是Java堆使用情况的内存镜像, 其中主要包括系统信息, 虚拟机属性, 完整的线程dump,所有类和对象
的状态等。 一般, 在内存不足, GC异常等情况下, 我们就会怀疑有内存泄露，这个时候我们就可以通过制作堆dump来查看具体的情况.

- 查看堆的使用情况`jmap -heap pid`
- 查看堆中的对象数量: `jmap -histo pid`
- 将内存的详细使用输出到文件： `jmap -dump:file=filepath,format=b pid`
- 将内存dump文件进行在线观看: `jhat -port dumpfile`

## jinfo
> 用于输出java进程, core文件, 或远程debug服务器的配置信息。可以使用`jps -v`进行替换

## jstat
> 用于监控虚拟机的各种状态信息命令行工具, 可以显示本地或者远程虚拟机进程中的`类加载`, `内存`, `垃圾收集`,`JIT编译`等信息

`jstat -<option> [-t] [-h<lines>] <vmid> [<interval> [<count>]]`
- 参数选型
  - `option` - 我们一般采用`-gcutil`进行gc信息查看
  - `vmid` - vm的进程号
  - `interval` - 间隔时间, 用于每隔多长的时间刷新一次, 单位(`ms`)
  - `count` - 打印次数, 如果缺省, 则默认打印无数次

例如: `jstat 12345 250 5`

## javap
> 对class文件的反编译
