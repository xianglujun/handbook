# GC Roots包含哪些(哪些可以作为gc roots)

> 所谓的GC roots 是垃圾搜集器特有的对象, 垃圾搜集器搜集哪些非GC root的对象并且无法通过GC roots引用直接访问的对象。

一个对象可以属于多个roots, GC roots有一下几种:
- Class 由系统类加载器加载的类, 永远不能回收这样的类(自定义的类加载器不是root, 除非响应的实例恰好是其他java.lang.Class的类型的root)
- Thread - 存活的线程
- Stack Local - Java方法局部变量或者参数
- JNI Local - JNI的局部变量或者参数
- JNI Global - 全局JNI引用
- Monitor Used - 用于同步监视器的对象
- Held by JVM - 由JVM为其目的从垃圾搜集器中保存的对象。可能的已知情况是：系统类加载器，JVM知道的一些重要的异常类，一些用于异常处理的预分配对象，以及在加载类的过程中的自定义类加载器。 不幸的是，JVM绝对没有为这些对象提供额外的细节。因此，由分析师决定某个Held by JVM于哪种情况。

