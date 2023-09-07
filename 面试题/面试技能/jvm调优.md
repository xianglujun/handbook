# jvm调优

## 类加载器

- 为什么要使用双亲委派？    
  
  - 1。 加载过的类不需要重复加载
  
  - 2。 主要是为了安全考虑

- 自定义ClassLoader
  
  - findInCache -> parent.loadClass -> findClass()
  
  - 实现findClass方法
  
  - 使用defineClass将二进制转换为Class对象

- LazyLoading的五种情况

- 检测热点代码：
  
  - -XX:CompileThreshold=10000

- 什么情况打破双亲委派
  
  - ThreadContextClassLoader可以实现基础类调用实现类代码，通过thread.setContextClassLoader指定。线程上下文
  
  - 热启动，热部署
    
    - osgi, tomcat 都是自己的模块指定classload, (可以加载同一个类的不同版本） 

## 类加载链接阶段

- 验证
  
  - 验证文件是否符合JVM规定

- 准备
  
  - 静态成员变量附默认值

- 解析
  
  - 将类、方法。属性等符号引用解析为直接引用
  
  - 常量池中的各种符号引用解析为指针、偏移量等内存地址的直接引用

## 类初始化阶段

1. 调用类初始化<clinit>, 为静态变量赋默认值

## JMM内存模型

### 1. 硬件层数据一致性

- CPU一致性协议很多，Intel采用的MESI数据一致性的实现

- 读取缓存以cache line为基本单位，目前为64字节(bytes)

- 位于同一缓存行的两个不同数据，被两个不同的CPU锁定，产生互相影响的伪共享问题

- 伪共享问题：JUC/C_028_FalseSharing

- <mark>解决：使用缓存行的对齐来提高运行效率</mark>。

### 2. 执行顺序

> 读指令的同时可以同时执行不影响的其他指令而写的同时可以进行合并写，这样的CPU的执行就是乱序的。

- CPU为了提高执行令的执行效率，会在一条指令的执行过程中（内存比cpu慢大概100倍），取同时执行令另一条指令，前提是，两条指令没有依赖关系。

- 写操作也可以进行合并(WCBuffer: Write Combine Buffer), (cnblogs.cn/liushaodong/p/)

#### 如何保证不乱序执行

- 使用volatile关键字,防止指令重排序

- 对不需要重排的代码段加锁

- <mark>硬件层面主要使用内存屏障</mark>

#### JSR内存屏障

- LoadLoad屏障：
  
  - 对于这样的语句Load1;LoadLoad;Load2
    
    - 在Load2及后续读取操作要读取的数据被访问前，保证Load1要读取的数据被读取完毕

- StoreStore屏障
  
  - 对于这样的语句Store1;StoreStore;Store2
    
    - 在Store2及后续写入操作执行前，保证Store1的写入操作对其他处理器可见

- LoadStore屏障
  
  - 对于这样的语句Load1;LoadStore;Store2
    
    - 在Store2及后续写入操作被刷出前，保证Load1要读取的数据被读取完毕

- StoreLoad屏障
  
  - 对于这样的语句Store1;StoreLoad;Load2
    
    - 在Load2及后续所有读取操作执行前，保证Store1的写入对所有处理器可见

#### volatile的实现细节

- 系统底层的屏障，比如windows的lock指令

#### synchronized实现细节

- 当synchronized关键字加在了方法上，则会使用ACC_SYNCHRONIZED标记

- 当锁定的是对象时，则使用monitorenter和monitorexit虚拟机指令

- 硬件层面主要使用的lock的指令实现

#### hapen-before原则

...

## 3. 对象的内存布局

### 问题列表

- 请解释一下对象的创建过程?

- 对象在内存中存储布局?

- 对象头具体包括什么？

- 对象怎么定位?

- 对象怎么分配?

- Object o = new Object()在内存中占用多少字节?

#### 对象的创建过程

1. class Loading

2. class linking

3. class initializing

4. 申请对象内存

5. 成员变量赋默认值

6. 调用构造方法`<init>`
   
   1. 成员变量顺序赋初始值
   
   2. 执行构造方法语句

#### 对象在内存中的存储布局

1. 观察虚拟机配置
   
   1. java -XX:+PrintCommandLineFlags -version

2. <mark>普通对象</mark>
   
   1. 对象头：markword 8字节
   
   2. ClassPointer指针：-XX:UseCompressedClassPointers 为4字节；不开启为8字节
   
   3. 实例数据
      
      1. 引用类型：-XX:UseCompressedOops为4字节，不开启为8字节
      
      2. Oops: 实体类中的属性压缩，ordinary object pointers ，可以开启 -XX:+UseCompressedOops
   
   4. Padding对齐，8的倍数

3. 数组对象
   
   1. 对象头：`markword`: 8字节
   
   2. ClassPointer指针同上：4字节或者8字节
   
   3. 数组长度：4字节
   
   4. 数组数据
   
   5. 对齐8的倍数

#### 对象头包含哪些?

- 下图为32位系统

![](C:\Users\自来也\AppData\Roaming\marktext\images\2023-07-29-10-55-01-image.png)        

- 下图为64位的结构
  
  ![](C:\Users\自来也\AppData\Roaming\marktext\images\2023-07-29-10-59-46-image.png)

#### 当对象记录过IdentityHashCode值之后，是否能进偏向锁

不能，是因为计算hashcode之后，那么偏向锁的数据则无法存储。因此无法进入偏向锁状态。

#### 对象怎么定位？

- 句柄池：效率相对低一些，在垃圾回收时，效率较高

- 直接指针

#### 对象怎么分配?

![](C:\Users\自来也\AppData\Roaming\marktext\images\2023-07-29-11-10-58-image.png)

## 4. JVM 运行时数据区域和JVM Instructions(指令集)

### 运行时数据区域

- Program Counter
  
  - 指令的存放位置
  
  - 虚拟机的运行，类似于循环：
    
    - while (not end) {
      
      - 取PC中的位置，找到对应位置的指令；
      
      - 读取指令：
      
      - pc++；
    
    - }

- 线程栈
  
  - 线程栈中存储的是栈帧
    
    - 局部变量表：LocalVariableTable,也是本地变量
    
    - 操作数栈：Operate Stack
    
    - Dynamic Linking
    
    - Return Address
  
  - 常用指令
    
    - store
    
    - load
    
    - invoke
      
      - InvokeStatic: 执行静态方法
      
      - InvokeVirtual：自带多态，执行创建实际对象的方法
      
      - InvokeInterface：
        
        - 执行接口方法，例如
        
        - List<String> list = new ArrayList(); list.add("ss")
      
      - InvokeSpecial：可以直接定位，不需要多态的方法
        
        - 例如：private方法
        
        - 构造器方法
      
      - InvokeDynamic
        
        - lambda表达式或者反射或者其他动态语言，或者CGLIB ASM动态产生的class, 所产生的命令

- 本地方法栈：JNI，调用C的代码

- 直接内存：操作系统管理的内存，不归JVM管理

- 方法区：class, 常量池
  
  - Perm Space (<1.8)
    
    - 字符串常量位于PermSize
    
    - FGC不会清理
    
    - 大小启动的时候指定，不能改变
  
  - Meta Space(>=1.8)
    
    - 字符串常量位于堆
    
    - 会触发FGC
    
    - 启动时不设定的话，最大就是物理内存

## 5. 如何发现垃圾

- 引用计数算法
  
  - 不能解决循环引用问题

- 可达性分析

## 6. GC算法

- 标记清除
  
  - 算法相对简单，存活对象比较多的情况下效率较高
  
  - 两边扫描，效率偏低
    
    - 第一遍标记出存活的对象
    
    - 第二遍清理垃圾对象
  
  - 容易产生碎片

- 复制算法
  
  - 适用于存活对象较少的情况，只烧苗一次，效率提高，没有碎片
  
  - 浪费空间，移动复制对象，需要调整对象引用

- 标记整理
  
  - 不会产生碎片，方便对象分配，不会产生内存减半
  
  - 扫描两次，需要移动对象，效率偏低
  
  - ![](C:\Users\自来也\AppData\Roaming\marktext\images\2023-07-29-15-43-12-image.png)

## 7. GC Roots

- 线程栈变量

- 静态变量

- 常量池

- JNI指针

## 8. JVM内存分代模型

1. 部分垃圾回收器使用的模型
   
   > 除Epsilon, ZGC 之外的GC都是使用逻辑分代模型
   > 
   > G1是逻辑分代，物理部分代
   > 
   > 除此之外不仅逻辑分代，而且物理分代

2. 堆内逻辑分代： Eden + 2S + Tenured
   
   1. 新生代(使用Copying(复制算法))
      
      1. eden
      
      2. survivor
      
      3. survivor
   
   2. 老年代：标记整理 或者 标记清除
      
      1. 对象何时进入老年代：XX:MaxTenuringThreshold指定次数
         
         1. Parallel Scaavenge 15
         
         2. CMS 6
         
         3. G1 15
      
      2. 动态年龄
         
         1. s1 -> s2超过50%
         
         2. 把年龄最大的放入Old区域
      
      3. 分配担保
         
         1. YGC期间，Survivor区域空间不够，通过空间担保直接进入老年代

## 9. 对象创建过程

- 栈上分配
  
  - 线程私有小对象
  
  - 无逃逸
  
  - 支持标量替换
  
  - 无需调整

- 线程本地分配TLAB
  
  - 占用eden, 默认1%
  
  - 多线程的时候不用竞争eden就可以申请空间，提高效率
  
  - 小对象
  
  - 无需调整

- Eden区域分配

- 老年代分配

## 10. 常见垃圾回收器

- 新生代
  
  - Serial - 单线程, 常与Serial Old配合使用
  
  - ParNew - 常与CMS配合使用
    
    - 响应时间优先
  
  - Parallel Scavenge - 常与Parallel Old一起使用
    
    - 吞吐量优先
  
  - 回收过程
    
    - YGC回收之后，大多数对象被回收，或者的进入s0
    
    - 再次YGC，则活着的eden + s0 复制到s1
    
    - 再次YGC，活着的eden + s1 复制到s2
    
    - 当对象年龄足够(15, CMS 6)
    
    - 当新生代对象不足时，则直接发到老年带

- 老年代
  
  - CMS
    
    - 垃圾回收的时候，有四个阶段
      
      - 初始标记(STW)
        
        - 找到根对象，即（GC ROOTS）中的对象
      
      - 并发标记
        
        - 标记过程和业务处理线程同时执行，同时也是多线程标记垃圾
      
      - 重新标记(STW)
        
        - 对新产生的垃圾进行标记
      
      - 并发清理
        
        - 这个阶段会产生新的垃圾，这个时候被称为浮动垃圾
    
    - CMS存在的问题
      
      - 内存碎片：在碎片化整理的时候，通过Serial Old进行实现
        
        - -XX:+UseCMSCompactAtFullCollection
        
        - -XX:CMSFullGCsBeforeCompaction, 默认为0，值的是经过多少次FGC才进行压缩
      
      - 浮动垃圾
        
        - 当新生代对象分配到老年代，而老年代没有足够空间，则需要使用Serial Old进行碎片整理
          
          - 主要通过降低CMS的触发阈值：
            
            - <mark>-XX:CMSInitialtingOccupancyFraction 92%</mark>: 即92%的时候就会产生FGC, 我们可以设置较小的值，保持足够的空间。
          
          - <mark>PromotionFailed</mark>
            
            - 保持老年代足够的空间
    
    - CMS标记算法
      
      - 采用的是三色标记（白，灰，黑）
      
      - ![](C:\Users\自来也\AppData\Roaming\marktext\images\2023-07-29-16-52-51-image.png)
      
      - 在并发标记时，引用可能发生变化，白色对象可能被错误回收
    
    - 解决方案：
      
      - SATB
        
        - 在开始的时候生成快照
        
        - 当B->D消失时，要把这个引用推到GC堆栈，保证D还能被GC扫描到
      
      - Incremental Update
        
        - 当一个base对象被一个黑色对象引用，将黑色对象重新标记为灰色，让collector重新扫描
  
  - Serial Old
  
  - Parallel Old

## 11. JVM调优的一些方式

### 常见垃圾回收器组合参数设定

- -XX:+UseSeralGC = Serial New +Serial Old
  
  - 小型程序，默认情况下不会是这种选项，HotSpot会根据计算及配置和JDK版本自动选择搜集器

- -XX:+UseParNewGC=ParNew+SerialOld
  
  - 这个版本很少见

- UseConcMarSweepGC=ParNew + CMS + Serial Old

- UseParallelGC=Parallel Scavenge + Parallel Old(1.8默认)

- UseParallelOldGC=Parallel Scavenge + Parallel Old

- UseG1GC=G1

- Linux中没找到默认GC的查看方法，而windows中会打印UseParallelGC
  
  - java +XX:+PrintCommandLineFlags -version
  
  - 通过GC的日志来分辨

- Linux下1.8版本默认的垃圾回收器到底是什么
  
  - 1.8.0_181 默认(Copy MarkCompact)
  
  - 1.8.0_222默认PS + PO

### PS日志记录信息

### 什么是调优？

1. 根据需求进行JVM规划和预调优

2. 优化运行JVM运行环境

3. 解决JVM运行过程中出现的各种问题

### 调优前的基础概念

1. 吞吐量：用户代码时间/(用户代码执行时间+垃圾回收时间)

2. 响应时间：STW越短，响应时间越好

所谓调优，首先确定，

- 吞吐量优先还是响应时间优先，

- 还是在满足一定的响应时间的情况下，要求达到多大的吞吐量
  
  - 吞吐量优先：PS + PO
  
  - 响应时间优先：网站GUI, API, 
    
    - 1.8选择G1 或者PN + CMS

### 调优，从规划开始

- 调优，从业务场景开始，没有业务场景的调优都是耍流氓

- 压测

- 无监控，不调优

- 步骤
  
  - 熟悉业务场景(没有最好的垃圾回收器，只有最适合的垃圾回收器)
    
    - 1. 响应时间，停顿时间[CMS, G1, ZGC] (需要给用户做响应)
      
      2. 吞吐量 = 用户时间 / (用户时间 + GC时间) [PS]
  
  - 选择回收器组合
  
  - 计算内存需求（1.5G, 16G)
  
  - 设定年代大小，升级年龄
  
  - 设定日志参数
    
    - -Xloggc:/opt/xx/logs/t.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=20M -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCCause
    
    - 或者每天产生一个日志文件
  
  - 观察日志情况

### 优化运行环境

1. 有一个50万PV的资料类网站，原服务器32,1.5G的堆，用户反馈比较慢，因此公司决定升级，新的服务器为64位，16G的堆内存，结果用户反馈卡顿十分严重，
   
   1. 为什么比较慢？
      
      1. 很多用户浏览数据，很多数据load到内存，内存不足，频繁GC，STW长，响应时间变慢
   
   2. 为什么卡顿
      
      1. 内存越大,FGC时间越长
   
   3. 如何调优：
      
      1. PS -> PN + CMS
      
      2. PS -> G1

2. 系统CPU经常100%， 如何调优?
   
   1. CPU100%一定有现成占用系统资源
      
      1. 找出哪个进程cpu飙高
      
      2. 该进程中的哪个现成cpu高
      
      3. 导出该现成的堆栈
      
      4. 查找哪个方法(栈帧)，消耗时间比较高

3. 系统内存飙高，如何查找问题？
   
   1. 导出堆内存，(jmap)
   
   2. 分析(jhat jvisual mat jprofile)

4. 如何监控JVM
   
   1. jstat jvisualvm jprofiler arthas top

### 一些案例

- jstack定位现成状态：重点关注WAITING BLOCKED
  
  - waiting on <ox00000>(a java.lang.Object)
  
  - 加入有一个进程中100个线程，很多线程都在waiting on ..., 一定要找到是那个线程持有这把锁
  
  - 搜索jstack dump信息，找打<xxx>, 看哪个线程持有这把锁RUNABLE

- 怎么定位oom问题
  
  - 已经上线的系统，不用图形界面在用什么？cmdline arthas
    
    - 线上运行项目，配置在发生OOM时将内存dump到文件，并保存
    
    - 使用jmap -histo pid | head 20
      
      - 线上系统内存特别带，jamp执行期间对现成产生很大影响，甚至卡顿
      
      - 设置了参数：-XX:+HeapDumpOnOutOfMemoryError, 会自动转储文件
      
      - <mark style="color: red">很多服务器备份（高可用），停掉这台机器对其他服务器不影响</mark>
      
      - 在线定位：arthas, 在线排查工具
    
    - 然后通过MAT对内存dump文件进行分析
  
  - 图形界面用在什么地方？测试，测试的时候进行监控

- jstat -gc 4655 500: 每500毫秒打印一次

- arthas线上问题排查
  
  - jad反编译
    
    - 动态代理生成类的问题定位
    
    - 第三方的类
    
    - 版本问题(确定自己最新提交的版本是不是被使用)
  
  - redefine热替换
    
    - 目前有些限制：只能该方法实现，不能改方法名，不能改属性

### 案例汇总

OOM产生原因多种多样，有些程序未必产生OOM, 不断FBC(CPU飙高，但内存回收特别少)

- 硬件升级系统反而卡顿严重

- 线程池不当运用产生OOM问题
  
  - 不断往List加对象

- simle jira问题

- tomcat http-header-size过大问题

- lambda表达式导致方法区溢出问题、

- 重写finalize引发频发GC

## 12. G1垃圾搜集器

- 目标是在多核、大内存的机器上，它在大多数情况下可以实现指定的GC暂停事件，同时还能保持较高的吞吐量

- Region分区，从逻辑上进行分区
  
  - Eden
  
  - Survivor
  
  - 大对象区域 - 超过单region的50%

- 特点
  
  - 并发搜集
  
  - 压缩空闲空间不会延长GC的暂停时间
  
  - 更易预测的GC暂停时间
  
  - 使用不需要实现很高的吞吐量的场景
  
  - CSet
    
    - 记录了那些对象可以被回收，可以来自E，S， O区
  
  - RSet
    
    - 记录了其他Region中的对象到本Region的引用
    
    - RSet价值在于，使得垃圾搜集器不需要扫描整个堆，找到谁引用了当前分区的对象，只需要扫描RSet即可
  
  - 新老年代比例：
    
    - G1会自动预测和调整
  
  - 如果G1产生FGC, 应该做什么
    
    - 扩内存
    
    - 提高CPU性能
    
    - 降低MixedGC触发阈值，让MixedGC尽早发生
      
      - -XX:InitiatingHeapOccupacyPercent 默认为45%, 如果O区超过了这个只，则启用MixedGC, 根CMS搜集方式一样
      
      - java10之前FullGC是串行的，之后是并行的

- 算法基础概念
  
  - CardTable
    
    - 由于YGC时，需要扫描整个OLD区，效率很低，所以JVM设计了CardTable, 如果一个CardTable中有对象指向了Young区，九江他设为Dirty, 下次扫描时，只需要扫描Dirty Card Table, 在结构上，CardTable使用BitMap实现.
  
  - 并发标记算法
    
    - 三色标记算法
      
      - 黑色：完成标记
      
      - 灰色：自己被标记，成员未标记
      
      - 白色：未标记
    
    - 漏标的情况
      
      - remark过程中，黑色对象指向了白色对象，如果不对黑色标记重新扫描，则会漏标
      
      - 在并发标记过程中，Mutator删除了所有从灰色到白色的引用，会产生漏标, 此时，白色对象应该被回收
    
    - 解决漏标算法
      
      - Incremental update：增量更新，关注引用的增加，把黑色重新标记为灰色，下次重新扫描属性
      
      - SATB: snapshot at the beginning：关注引用的删除，当B -> D消失时，要把这个引用推到GC堆栈，保证D还能被GC扫描到

## 13 常用的GC参数

- -XX:PrintTLAB
  
  - 打印TLAB的使用情况

- -XX:TLABSize
  
  - 指定TLAB大小

- -XX:+DisableExplictGC
  
  - 禁用System.gc()

- -XX:+PrintGC

- -XX:+PrintGCDetails

- -XX:+PrintHeapAtGC

- -XX:+PrintGCTimeStamps

- -XX:+PrintGCApplicationConcurrentTime:答应应用程序时间

- -XX:+PrintGCApplicationStoppedTime 打印暂停时间

- -XX:+PrintReferenceGC 记录回收了多少种不同引用类型的引用

- -verbose:class 类加载详细过程

- -XX:+PrintVMOptions

- -XX:+PrintFlagsFinal

## 14. Parallel常用参数

- -XX:SurvivorRatio S区的比例

- -XX:PreTenureSizeThreshold 大对象尺寸

- -XX:MaxTenuringThreshold

- -XX:+ParallelGCThreads 
  
  - 并行搜集器的线程数，同样适用于CMS, 一般设为和CPU核数相同

- -XX:+UseAdaptiveSizePolicy
  
  - 自动选择各区大小比例

## 15. CMS常用参数

- -XX:+UseConcMarkSweepGC

- -XX:+ParallelCMSThreads
  
  - CMS线程数量

- -XX:+CMSInitiatingOccupancyFraction
  
  - 使用多少比例的老年代后开始CMS搜集，默认是68%, 如果频发发生Serial Old卡顿，应该调小

- -XX:+UseCMSCompactAtFullCollection
  
  - 在FGC时进行压缩

- -XX:+CMSFullGCsBeforeCompaction
  
  - 在多少次FGC后进行压缩

- -XX:+CMSClassUnloadingEnabled

- -XX:+CMSInitiatingPermOccupancyFraction
  
  - 达到什么比例进行Perm回收

- -XX:+GCTimeRatio
  
  - 设置GC时间占用程序运行时间的百分比

- -XX:MaxGCPauseMillis
  
  - 停顿时间，是一个建议时间，GC尝试各种手段达到这个时间，比如，减小年轻代

## 16 G1常用参数

- -XX:+UseG1GC

- -XX:+MaxGCPauseMillis
  
  - 建议值，G1会尝试调整Young区的块数来达到这个值

- -XX:+GCPauseIntervalMillis

- 

- -XX:+G1HeapRegionSize
  
  - 分区大小，建议组件增大该值：1,2,3,8,16, 32
  
  - 死者size增加，垃圾的存活时间更长，GC间隔更长，但每次GC的时间也会更长

- G1NewSizePercent
  
  - 新生代的比例，默认为5%

- G1MaxNewSizePercent
  
  - 新生代最大比例，默认为60%

- GCTimeRatio
  
  - GC时间建议比例，G1会根据这个值调整堆空间

- ConcGCThreads
  
  - 线程数量

- InitiatingHeapOccupancyPercent
  
  - 启动G1的对空间占用比例
