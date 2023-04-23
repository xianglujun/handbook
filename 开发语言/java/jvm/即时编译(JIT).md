# 即时编译(JIT)

在Class初始化完成后，类在调用过程中，执行引擎会把字节码转换为机器码，然后在操作系统中才能执行。`在字节码转换为机器码的过程中，虚拟机中还存在着一道编译， 就是即时编译`

最初，虚拟机中的字节码是由解释器完成编译的，当虚拟机发现方法或者代码块自行频繁时，就会讲代码标记为`热点代码`

为了提高热点代码的执行效率，在运行时，即时编译器(JIT)会把这些代码编译成与本地平台相关的代码，并进行各层次的优化，然后保存在内存中。

## 即时编译类型

在HotSpot虚拟机中，内置了两个JIT, 分别为C1编译器和C2编译器，这两个编译器的编译过程是不一样的

### C1

C1编译器是一个简单快速的编译器，主要的关注点在于局部的优化，适用于执行时间较短或对性能有要求的程序。

### C2

C2编译器是长期运行的服务器应用程序做性能调优的编译器，适用于执行时间长或对巅峰性能有要的程序，根据各自的适配性，这两种即时编译也被称为`Client Compiler`和`Server Compiler`

### Java7分界线

- Java7之前需要根据程序的特性来选择对应的JIT, 虚拟机默认采用解释器和其中一个编译器配合工作。
- Java7引入了分层编译，这种方式综合了C1的启动性能优势和C2的巅峰性能优势，同时也可以通过`-client`, `-server`强制指定虚拟机的即时编译模式。

### 分层编译模型

- 第0层：程序解释执行，默认开启性能监控功能(Profiling), 如果不开启，可触发第二层编译。
- 第1层：可称为C1编译，将字节码编译为本地代码，进行简单、可靠的优化，不开启Profiling
- 第2层：也成为C1编译，开启Profiling，仅执行带方法调用次数和循环回边执行次数profiling的Ci编译
- 第3层：也成为C1编译，执行所有带Profiling的C1编译
- 第4层：可称为C2编译，也是将字节码编译为本地代码，但是会启用一些编译耗时较长的优化，甚至会根据性能监控信息进行一些不可靠的激进优化。

## Java8

在Java8中，`默认开启分层编译0`， `-client`与`-server`的设置已经是无效：

- 如果想开启C2， 需要关闭分层编译(-XX:-TieredCompilation)
- 如果只想用C1, 可以打开分层编译的同时，使用`-XX:TieredStopAtLevel=1`

除了这种会和编译模式，还可以使用:

- `-Xint`参数强制虚拟机只运行与只有解释器的编译模式下
- `-Xcomp`参数强制虚拟机运行于只有JIT的编译模式下

## 热点探测

在 HotSpot虚拟机中的热点探测是JIT的优化条件。热点探测是基于计数器的任店探测，采用这种方法的虚拟机会为每个方法建立计数器统计方法的执行次数，如果执行次数超过一定阈值就认为他是热点方法

虚拟机中为每个方法准备了两类计数器：

- 方法调用计数器(Invocation Counter)
- 回边计数器(Back Edge Counter)

### 方法调用计数器

用于统计方法调用的次数，方法调用计数器的默认值：

- C1模式下是1500次
- C2模式下是10000次
- 通过`-XX:CompileThreshold`来设置

而在分层编译的情况下，`-XX:CompileThreshold`指定的阈值将失效，此时将会根据当前编译的方法以及编译线程数来动态调整。当方法计数器和回边计数器之和超过方法计数器阈值时，就会触发JIT编译器。

### 回边计数器

用于统计一个方法中循环体代码执行的次数。

`回边`是指在字节码中遇到控制流向后跳转的指令

- 在不开启分层编译的情况
  - C1 默认为13995
  - C2 默认是10700
  - 通过`-XX:OnStackReplacePercentage=N`来设置
- 在分层编译的情况下, `-XX:OnStackReplacePercentage=N`的设置同样会失效，此时需要根据当前编译方法数以及编译线程来动态调整。

建立回边计数器的主要目的是为了触发OSR(On StackReplacement)编译，即栈上编译。在一些编译周期比较长的代码段中，当需要达到回边计数器阈值时，JVM认为这段代码是热点代码, JIT编译器就汇将这段代码编译成为机器语言并缓存，在该循环时间段内，会直接将执行代码替换，执行缓存的机器语言。

## 编译优化技术

### 方法内联

调用一个方法需要经历压栈和出栈。调用方法是将程序执行顺序转义到存储该方法的内存地址，将方法的内容执行完后，再返回到执行该方法前的位置。

这种执行操作要求在执行前保护现场并记忆执行的地址，执行后要求回复现场，并按原来保存的地址继续执行。因此调用会产生一定的时间和空间方面的开销。

对于一些方法体代码不是很大，又频繁调用的方法来说，这个时间和空间的消耗会很大。`方法内联`的优化行为就是把目标方法的代码赋值到发起调用的方法中，避免发生真实的方法调用。

```java
private int add(int x1, int x2, int x3, int x4) {
    return add2(x1, x2) + add2(x3, x4);
}

private int add2(int x1, int x2) {
    return x1 + x2;
}
```

被优化后的代码为:

```java
private int add2(int x1, int x2, int x3, int x4) {
    return x1 + x2 + x3 + x4;
}
```

JVM会自动识别热点方法，对他们使用方法内联优化。可以通过`-XX:CompileThreshold`来设置热点方法的阈值。

> 但是如果本身方法体的很大，方法体的调用就算到达热点调用的阈值，也不会做内联优化。

我们可以通过参数设置来控制方法体大小:

- 经常执行的方法，默认情况下，方法体大小`小于325字节`的都会进行内联，可以通过`-XX:MaxFreqInlineSize=N`来设置大小
- 不是经常执行的方法，默认情况下，方法`大小小于35`字节才会进行内联，我们也可以通过`-XX:MaxInlineSize=N`来重置大小值

### 查看方法被内联情况

```java
-XX:+PrintCompilation // 在控制台输出编译过程信息
-XX:+UnlockDiagnosticVMOptions // 解锁对JVM进行的诊断的选项参数，开启后支持一些特定参数对JVM进行诊断
-XX:+PrintInlining // 打印内联方法
```

```java
package com.jdk.test.demo.java.jvm;

/**
 * 该类用来测试热点代码，并通过jvm参数设置的方式，打印出内联方法信息
 */
public class FreqCode {

    /**
     * 在执行该方法时，需要在vm options中加入一下参数:
     * -XX:+PrintCompilation
     * -XX:+UnlockDiagnosticVMOptions
     * -XX:+PrintInlining
     * @param args
     */
    public static void main(String[] args) {
        // 根据默认设置，c1热点方法是1500次， c2编译的热点方法是10000次
        long total = 0;
        for (int i =0; i < 1000000; i++ ){
            total += add(i, i + 1);
        }
        System.out.println(total);
    }

    private static int add(int p, int n) {
        return p + n;
    }
}
```

#### 输出结果

```text
                              @ 15   com.jdk.test.demo.java.jvm.FreqCode::add (4 bytes)
                              @ 31  java/io/PrintStream::println (not loaded)   not inlineable
    211   37       3       com.jdk.test.demo.java.jvm.FreqCode::main (35 bytes)
                              @ 15   com.jdk.test.demo.java.jvm.FreqCode::add (4 bytes)
                              @ 31  java/io/PrintStream::println (not loaded)   not inlineable
    211   38 %     4       com.jdk.test.demo.java.jvm.FreqCode::main @ 4 (35 bytes)
                              @ 15   com.jdk.test.demo.java.jvm.FreqCode::add (4 bytes)   inline (hot)
    214   36 %     3       com.jdk.test.demo.java.jvm.FreqCode::main @ -2 (35 bytes)   made not entrant
    214   38 %     4       com.jdk.test.demo.java.jvm.FreqCode::main @ -2 (35 bytes)   made not entrant
    214   39       3       java.util.concurrent.ConcurrentHashMap::tabAt (21 bytes)
    214   40     n 0       sun.misc.Unsafe::getObjectVolatile (native)   
                              @ 14   sun.misc.Unsafe::getObjectVolatile (0 bytes)   intrinsic
```

### 输出格式字段说明

```txt
timestamp compilation-id flags tiered-compilation-level class:method <@ osr_bci> code-size <deoptimization>
```

- `timestamp`: 指代从JVM启动到执行的时间
- `compilation-id`: 是一个内部引用编号
- `flags`: 可能是一下几个值
  - `%`: is_osr_method(@ sign indecates bytecode index for OSR methods)
  - `s`: is_synchronized
  - `!`: has_exception_handler
  - `b`: is_blocking
  - `n`: is_native
- `tiered-compilation`:  当开启分层编译时，该值标识编译的层级
- `Method`: 标识编译的方法名称，一般采用`Classname:method`展示
- `@osr_bci`: 代表了OSR发生时，对应字节码所在索引
- `code-size`: 总的字节码大小
- `deoptimization`:  indicated if a method was de-optimized and made `not entrant` or `zombie` (More on this in section titled ‘Dynamic De-optimization’).

热点方法的优化可以有效提高系统性能，一般我们可以通过以下几种方式来提高方法内联：

- 通过设置JVM参数来减少热点阈值或增加方法体阈值，以便更多的方法可以进行内联，但这种方法以为着占用更多的内存
- 在编程中，避免在一个方法中写大量代码，习惯使用小方法体
- 尽量使用final, private, static 关键字修饰方法，编码方法因为继承，会需要额外的类型检查。

### 逃逸分析

逃逸洗是判断一个对象是否被外部方法引用或外部线程访问的分析技术，编译器会根据逃逸分析的结果进行代码优化

### 栈上分配

在Java中默认创建了一个对象在堆中分配内存，而当堆内内存中的对象不再使用时，则需要通过垃圾回收机制回收，这个过程相对分配在栈中的对象的创建和销毁来说，更消耗时间和性能。逃逸分析是指当发现一个对象只在方法中使用，就会将对象分配在栈上。

### 锁消除

在非线程安全的情况下，尽量不要使用线程安全容器。在实际中，当我们使用StringBuffer和StringBuilder的性能基本上没有区别，这是因为局部方法中创建的对象只能被当前线程访问，无法被其他线程访问，这个变量不会有锁竞争，这时候JIT编译会对这个对象的方法进行锁消除。

### 变量替换

逃逸洗证明一个对象不会被外部访问，如果这个对象可以被拆分的话，但程序真正执行的时候可能不会创建这个对象，而是直接创建它的成员变量来代替。对象拆分后，可以分配对象的成员变量在栈或寄存器上，原本的对象就无须分配内存空间了，这种编译优化叫做标量替换。

```java
-XX:+DoEscapeAnalysis 开启逃逸分析(jdk1.8默认开启)
-XX:-DoEscapeAnalysis

-XX:+EliminateLocks 开启锁消除(jdk1.8默认开启)
-XX:-EliminateLocks 关闭锁消除

-XX:+EliminateAllocations 开启标量替换(jdk1.8默认开启)
-XX:-EliminateAllocations 关闭标量替换
```

## 反优化（Dynamic De-optimization)

当之前优化的方法不在被关联时， JVM将会执行反优化操作， 会将当前方法的编辑等级回滚到先前或者新的编译等级。

```txt
573  704 2 org.h2.table.Table::fireAfterRow (17 bytes)
7963 2223 4 org.h2.table.Table::fireAfterRow (17 bytes)
7964  704 2 org.h2.table.Table::fireAfterRow (17 bytes) made not entrant
33547 704 2 org.h2.table.Table::fireAfterRow (17 bytes) made zombie
```
