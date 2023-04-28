# CMS垃圾搜集器

## 搜集过程

- 初始标记(CMS-initial-mark)
- 并发标记(CMS-concurrent-mark)
- 预清理(CMS-concurrent-preclean)
- 可被终止的预清理(CMS-concurrent-abrotable-preclean)
- 重新标记(CMS-remark)
- 并发清除(CMS-concurrent-sweep)
- 并发重置状态等待下次CMS触发(CMS-concurrent-reset)

![CMS标记阶段](.\CMS标记阶段.png)

### 初始标记(CMS-initial-mark)

该阶段是整个CMS流程中第一个`stop-the-world`的阶段，该阶段主要标记`老年代中存活的对象`

- 标记老年代中所有GC Roots对象
- 标记被年轻代存活对象引用的老年代对象.

![CMS初始标记](.\1.png)

#### GC Roots

在Java中，可作为GC Roots对象包括以下几种:

一个对象可以属于多个roots, GC roots有一下几种:

- Class 由系统类加载器加载的类, 永远不能回收这样的类(自定义的类加载器不是root, 除非响应的实例恰好是其他java.lang.Class的类型的root)
- Thread - 存活的线程
- Stack Local - Java方法局部变量或者参数
- JNI Local - JNI的局部变量或者参数
- JNI Global - 全局JNI引用
- Monitor Used - 用于同步监视器的对象
- Held by JVM - 由JVM为其目的从垃圾搜集器中保存的对象。可能的已知情况是：系统类加载器，JVM知道的一些重要的异常类，一些用于异常处理的预分配对象，以及在加载类的过程中的自定义类加载器。 不幸的是，JVM绝对没有为这些对象提供额外的细节。因此，由分析师决定某个Held by JVM于哪种情况。

> 在该阶段中，为了减少程序停顿的时间，可以采用并行标记的方式，通过`-XX:+CMSParallelInitialMarkEnabled`开启并行标记，同时通过`–XX:ParallelGCThreads=n`设置并发标记的线程数，线程数不要超过cpu核数

### 并发标记(CMS-concurrent-mark)

- 并发标记需要从`初始标记`中找出所有存活的对象
- 并发标记阶段会将引用发生变化的对象所在的`Card`标记为`Dirty`状态。其中对象引用发生变化主要包含:
  - 新生代对象晋升到老年代对象
  - 大对象直接在老年代分配内存
  - 更新老年代对象的引用关系等等
- 此阶段会与`应用程序同事运行`, 因此此阶段不会将所有的老年代对象全部标记，因为应用程序在运行过程中会改变对象的引用关系等。
- 在与应用程序并行运行过程中，可能会导致`concurrent mode failure`

![CMS并发标记](.\2)

### 预清理阶段

因并发标记阶段无法全部标记全部的老年代存活对象，所以该阶段是为了弥补前一个阶段因引用关系改变导致没有标记到的存活对象。

该阶段主要是扫描所有标记为`Dirty的Card`, 并重新标记存活对象

如下：在并发标记阶段，节点3的引用指向了6，则会吧节点3的card标记为Dirty

![CMS预清理](.\3.jpg)

在预清理阶段，将6标记为存活对象.

![CMS预清理](.\4.jpg)

### 可终止的预处理(CMS-concurrent-abrotable-preclean)

这个阶段主要尝试着承担下一个阶段重新标记足够多的工作，这个阶段持续的时间依赖很多因素，这个阶段是重复做相同的事情，直到发生abort条件

- 重复的次数
- 多少量的工作
- 持续时间

只有满足以上之一条件，才会停止。

> 此阶段最大的持续时间为5s, 是因为期望在这段时间内发生一次 young gc.

### 重新标记

这个整个阶段第二次`stop-the-world`，该阶段主要完成标记整个老年代所有的存活对象

- 该阶段标记的内存方式是整个堆，包含`young_gen`, `old_gen`
- 重新标记阶段，会检测年轻代对老年代对象的引用，因此，对此阶段来讲，年轻代会做为老年代的`GC Roots`来使用，即使年轻代对象已经不可达。
  - 因为大部分对象创建时，都是创建在年轻代，并且回收效率也是最高的，为了减少对年轻代扫描对象和`STW`停顿时间，可以在并发标记前，触发一次`Young gc`， 清理掉已经没有引用的对象。
  - 可以通过`-XX:+CMSScavengeBeforeRemark`开启
- 为了提升该阶段的处理效率，可以开启并行搜集`-XX:+CMSParallelRemarkEnabled`

### 并发清理

- 通过以上阶段，老年代的对象已经被全部标记并且通过`Garbage Collector`采用清扫的方式回收不可达对象。这个阶段主要清除没有标记的对象，并且回收空间。

- 该阶段与应用线程并行执行，因此会产生新的垃圾，这一部分垃圾出现在标记过程之后，CMS无法在当次搜集中处理，只好留在下一阶段处理，这部分被称为`浮动垃圾`

## CMS 优化

### 减少remark停顿时间

一般CMS 80%的时间都在remark阶段，如果发现remark阶段停顿时间很长。可以通过`-XX:CMSScavengeBeforeRemark`参数，在执行remark阶段之前，执行`Young GC`, 较少年轻代对老年代无用的引用，降低remark时的开销

### 内存碎片问题

CMS采用`标记-清除`算法，CMS只会删除无用对象，不会对内存进行压缩，造成内存碎片。内存碎片化会导致分配连续内存时，可能会导致内存分配失败问题，CMS可以支持内存压缩，可以通过`-XX:CMSFullGCsBeforeCompaction=n`来设置，指代上一次CMS并发GC执行后,  需要n次full gc 后，对内存执行压缩。

### Concurrent Mode Failure

先看下官方对该错误的解释:

> The CMS collector uses one or more garbage collector threads that run simultaneously(同时) with the application threads with the goal of completing the collection of the tenured generation before it becomes full. As described previously, in normal operation, the CMS collector does most of its tracing and sweeping work with the application threads still running, so only brief pauses are seen by the application threads. However, if the CMS collector is unable to finish reclaiming the unreachable objects before the tenured generation fills up, or if an allocation cannot be satisfied with the available free space blocks in the tenured generation, `then the application is paused and the collection is completed with all the application threads stopped`. The inability to complete a collection concurrently is referred to as *concurrent mode failure* and indicates the need to adjust the CMS collector parameters. If a concurrent collection is interrupted by an explicit garbage collection (`System.gc()`) or for a garbage collection needed to provide information for diagnostic tools, then a concurrent mode interruption is reported

该异常发生在cms正在回收内存的时候。由于该阶段与应用线程同时执行。对象分配老年代内存有以下条件:

- 对象经过指定阈值(默认15)次`ygc`后，仍然存在，对象会被提升到老年代
- 创建大对象，导致该对象直接提升到老年代
- 由于年轻代担保机制，年轻代内存不足时，将对象担保到老年代内存

此时发现老年代空间不足，这时CMS还没有机会回收老年代产生的，这时就汇触发`Concurrent Mode Failure`错误。

CMS触发时机有可以通过以下两种方式设置：

- `-XX:+UseCMSInitiatingOccupancyOnly`
- `-XX:CMSInitiatingOccupanyFraction=70`

`-XX:CMSInitiatingOccupanyFraction=70`指代设置CMS在对内存占用率达到70%的时候开始GC

`-XX:+UseCMSInitiatingOccupancyOnly`如果不指定，则只会在第一次使用`-XX:CMSInitiatingOccupanyFraction=70`作为触发GC的条件，后续则会根据监控信息，自动调整参数值，导致对应设置失效。

#### 为什么需要两个参数

由于在垃圾搜集阶段应用线程会与垃圾搜集并行执行，就需要预留足够的内存，保证用户线程的使用。因此CMS搜集器不能像其他搜集器一样，等到老年代机会填满后再进行搜集，需要预留一部分空间提供并发搜集是的程序运作使用。

`-XX:CMSInitiatingOccupanyFraction`需要设置一个合理的值，设置打了，会增加`Concurrent Mode Failure`发生的频率。设置小了，又会增加CMS频率。

### Promotion Failed

在进行Minor GC时，如果`Survivor Space`放不下，对象只能放入老年代，而此时老年代也放不下造成的。在大部分情况下，由于老年代有足够的空间，但是由于碎片太多，导致新生代提升到老年代的对象比较大，无法找到连续内存存放对象导致。

#### 过早提升与提升失败

- 过早提升
  - 过早提升发生在`Survivor Unused`区域无法容纳`Eden`与`另一个Survivor`中存活的对象 , 导致对象过早的提升到老年代
- 提升失败
  - 如果在对象提升时，老年代无空间存放对象，导致触发`Full GC`，`Full GC`会导致整个堆被遍历，这种被称之为提升失败

#### 过早失败原因

- `Survivor`空间太小，容纳不下全部运行时短生命周期的对象。如果是这个原因，可以尝试将`Survivor`空间调大。否则短生命周期的对象过快的提升，导致老年代内存很快占满，从而引起频繁的`Full GC`

- 对象太大，`Survivor`与`Eden`没有足够大的空间来存放这些大对象

#### 提升失败原因

- 老年代空闲空间不够使用
- 老年代虽然空间足够，但是由于碎片化严重，导致没有连续的空间存放该对象

##### 解决办法

- 如果是因为内存碎片导致的大对象提升失败，`CMS`需要进行空间压缩
- 如果因为对象提升过快导致，可以尝试调大`Survivor`区域
- 如果因为老年代内存空间不够导致，可以尝试调低`CMS`触发阈值

## CMS相关参数及说明

| 参数                                   | 类型      | 默认值                                          | 说明                                                                                                                                                                                                 |
| ------------------------------------ | ------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| -XX:+UseConcMarkSweepGC              | boolean | false                                        | 老年代采用CMS搜集器                                                                                                                                                                                        |
| -XX:+CMSScavengeBeforeRemark         | boolean | false                                        | The CMSScavengeBeforeRemark forces scavenge invocation from the CMS-remark phase (from within the VM thread as the CMS-remark operation is executed in the foreground collector). 是否在执行重新标记时，执行YGC |
| -XX:UseCMSCompactAtFullCollection    | boolean | false                                        | 对老年代进行压缩，可以消除碎片化，但是可能会带来性能的消耗                                                                                                                                                                      |
| -XX:CMSFullGCsBeforeCompaction=n     | uintx   | 0                                            | CMS进行n次 full gc 后进行一次压缩，如果`n=0`每次full gc后都会进行碎片压缩，                                                                                                                                                 |
| –XX:+CMSIncrementalMode              | boolean | false                                        | 编发搜集递增进行，周期性把cpu资源让给正在运行应用(`在javase8后标记为过期`)                                                                                                                                                       |
| –XX:+CMSIncrementalPacing            | boolean | false                                        | 根据应用程序的行为自动调整每次执行的垃圾回收任务的数量(`在javase8后标记为过期`)                                                                                                                                                      |
| –XX:ParallelGCThreads=n              | uintx   | (ncpus <= 8) ? ncpus : 3 + ((ncpus * 5) / 8) | 并发回收线程数量                                                                                                                                                                                           |
| -XX:CMSIncrementalDutyCycleMin=n     | uintx   | 0                                            | 每次增量回收垃圾的占总垃圾回收任务的最小比例                                                                                                                                                                             |
| -XX:CMSIncrementalDutyCycle=n        | uintx   | 10                                           | 每次增量回收垃圾的占总垃圾回收任务的比例                                                                                                                                                                               |
| -XX:CMSInitiatingOccupancyFraction=n | uintx   | dk5 默认是68% jdk6默认92%                         | 当老年代内存使用达到n%,开始回收。`CMSInitiatingOccupancyFraction = (100 - MinHeapFreeRatio) + (CMSTriggerRatio * MinHeapFreeRatio / 100)`                                                                         |
| -XX:CMSMaxAbortablePrecleanTime=n    | uintx   | 5000                                         | 在CMS的preclean阶段开始前，等待minor gc的最大时间。                                                                                                                                                                |

对于CMS默认的参数设置，可以通过一下命令查看:

```shell
java -XX:+PrintFlagsInitial | grep CMS
```

```txt

```

bool CMSAbortSemantics                         = false                               {product}
    uintx CMSAbortablePrecleanMinWorkPerIteration   = 100                                 {product}
     intx CMSAbortablePrecleanWaitMillis            = 100                                 {manageable}
    uintx CMSBitMapYieldQuantum                     = 10485760                            {product}
    uintx CMSBootstrapOccupancy                     = 50                                  {product}
     bool CMSClassUnloadingEnabled                  = true                                {product}
    uintx CMSClassUnloadingMaxInterval              = 0                                   {product}
     bool CMSCleanOnEnter                           = true                                {product}
     bool CMSCompactWhenClearAllSoftRefs            = true                                {product}
    uintx CMSConcMarkMultiple                       = 32                                  {product}
     bool CMSConcurrentMTEnabled                    = true                                {product}
    uintx CMSCoordinatorYieldSleepCount             = 10                                  {product}
     bool CMSDumpAtPromotionFailure                 = false                               {product}
     bool CMSEdenChunksRecordAlways                 = true                                {product}
    uintx CMSExpAvgFactor                           = 50                                  {product}
     bool CMSExtrapolateSweep                       = false                               {product}
    uintx CMSFullGCsBeforeCompaction                = 0                                   {product}
    uintx CMSIncrementalDutyCycle                   = 10                                  {product}
    uintx CMSIncrementalDutyCycleMin                = 0                                   {product}
     bool CMSIncrementalMode                        = false                               {product}
    uintx CMSIncrementalOffset                      = 0                                   {product}
     bool CMSIncrementalPacing                      = true                                {product}
    uintx CMSIncrementalSafetyFactor                = 10                                  {product}
    uintx CMSIndexedFreeListReplenish               = 4                                   {product}
     intx CMSInitiatingOccupancyFraction            = -1                                  {product}
    uintx CMSIsTooFullPercentage                    = 98                                  {product}
   double CMSLargeCoalSurplusPercent                = 0.950000                            {product}
   double CMSLargeSplitSurplusPercent               = 1.000000                            {product}
     bool CMSLoopWarn                               = false                               {product}
    uintx CMSMaxAbortablePrecleanLoops              = 0                                   {product}
     intx CMSMaxAbortablePrecleanTime               = 5000                                {product}
    uintx CMSOldPLABMax                             = 1024                                {product}
    uintx CMSOldPLABMin                             = 16                                  {product}
    uintx CMSOldPLABNumRefills                      = 4                                   {product}
    uintx CMSOldPLABReactivityFactor                = 2                                   {product}
     bool CMSOldPLABResizeQuicker                   = false                               {product}
    uintx CMSOldPLABToleranceFactor                 = 4                                   {product}
     bool CMSPLABRecordAlways                       = true                                {product}
    uintx CMSParPromoteBlocksToClaim                = 16                                  {product}
     bool CMSParallelInitialMarkEnabled             = true                                {product}
     bool CMSParallelRemarkEnabled                  = true                                {product}
     bool CMSParallelSurvivorRemarkEnabled          = true                                {product}
    uintx CMSPrecleanDenominator                    = 3                                   {product}
    uintx CMSPrecleanIter                           = 3                                   {product}
    uintx CMSPrecleanNumerator                      = 2                                   {product}
     bool CMSPrecleanRefLists1                      = true                                {product}
     bool CMSPrecleanRefLists2                      = false                               {product}
     bool CMSPrecleanSurvivors1                     = false                               {product}
     bool CMSPrecleanSurvivors2                     = true                                {product}
    uintx CMSPrecleanThreshold                      = 1000                                {product}
     bool CMSPrecleaningEnabled                     = true                                {product}
     bool CMSPrintChunksInDump                      = false                               {product}
     bool CMSPrintEdenSurvivorChunks                = false                               {product}
     bool CMSPrintObjectsInDump                     = false                               {product}
    uintx CMSRemarkVerifyVariant                    = 1                                   {product}
     bool CMSReplenishIntermediate                  = true                                {product}
    uintx CMSRescanMultiple                         = 32                                  {product}
    uintx CMSSamplingGrain                          = 16384                               {product}
     bool CMSScavengeBeforeRemark                   = false                               {product}
    uintx CMSScheduleRemarkEdenPenetration          = 50                                  {product}
    uintx CMSScheduleRemarkEdenSizeThreshold        = 2097152                             {product}
    uintx CMSScheduleRemarkSamplingRatio            = 5                                   {product}
   double CMSSmallCoalSurplusPercent                = 1.050000                            {product}
   double CMSSmallSplitSurplusPercent               = 1.100000                            {product}
     bool CMSSplitIndexedFreeListBlocks             = true                                {product}
     intx CMSTriggerInterval                        = -1                                  {manageable}
    uintx CMSTriggerRatio                           = 80                                  {product}
     intx CMSWaitDuration                           = 2000                                {manageable}
    uintx CMSWorkQueueDrainThreshold                = 10                                  {product}
     bool CMSYield                                  = true                                {product}
    uintx CMSYieldSleepCount                        = 0                                   {product}
    uintx CMSYoungGenPerWorker                      = 67108864                            {pd product}
    uintx CMS_FLSPadding                            = 1                                   {product}
    uintx CMS_FLSWeight                             = 75                                  {product}
    uintx CMS_SweepPadding                          = 1                                   {product}
    uintx CMS_SweepTimerThresholdMillis             = 10                                  {product}
    uintx CMS_SweepWeight                           = 75                                  {product}
     bool PrintCMSInitiationStatistics              = false                               {product}
     intx PrintCMSStatistics                        = 0                                   {product}
     bool UseCMSBestFit                             = true                                {product}
     bool UseCMSCollectionPassing                   = true                                {product}
     bool UseCMSCompactAtFullCollection             = true                                {product}
     bool UseCMSInitiatingOccupancyOnly             = false                               {product}