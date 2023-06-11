# JVM类加载过程

## 加载

- 启动类加载器(Bootstrap class Loader)
  - 主要负责加载最基础，最重要的类
    - 存在在`JRE/lib`目录下jar中的类
    - 有虚拟机参数`-Xbootclasspath`指定的类
- 扩展类加载器, 其父类加载器为启动类加载器
  - 该类加载器主要负责加载`JRE/ext`目录下的jar包
  - 系统变量`java.ext.dirs`指定的类
  - 在JAVA 9之后，更名为`平台类加载器(platform class loader)`
    - Java SE中除了几个关键模块外，比如`java.base`是由启动类加载器加载之外，其他由平台类加载器加载
- 应用类加载器，父类为扩展类加载器
  - 负责加载应用程序路径下的类
  - 虚拟机指定参数`-cp/-classpath`
  - 系统变量`java.class.path`
  - 环境变量`CLASSPATH`指定的路径
- 自定义类加载器
  - 在类加载器中，是由类加载器实例以及类的全限定名来唯一确定



## 链接

通过验证、准备、解析三个阶段，将加载的类能够在JVM中执行。



### 验证

验证阶段目的在于，保证被加载的类能够满足JVM约束条件，能够在JVM中正常执行。



### 准备

- 在该阶段，会为被加载的类静态字段分配内存。但是在该阶段，分配的值，都是默认值，具体的值，会在`初始化`阶段完成
- 在部分JVM上，还会在此阶段构造其他跟类层次相关的数据结构。例如：为类的每个方法生成符号引用，这个服务号引用能够无歧义地能够定位到具体的目标上。



### 解析

解析的目的，正是将符号引用解析成为实际引用。如果符号引用指向一个没有被加载的类，或者字段、方法，那么都将出发目标类的加载。



## 初始化

初始化阶段，则是为静态字段复制，以及执行静态代码块的过程。JVM通过枷锁来保证类的`<clinit>`方法只会被执行一次。



在Java中，对静态字段的赋值，包含两种方式：

- 直接赋值
- 静态代码块赋值

在直接赋值中，`常量`是静态字段中特殊的一种，如果常量的类型为`基本类型`或者`字符串时`， 会被Java编译器标记成为常量值`ConstantValue`. 其值由JVM完成初始化。



### 初始化条件

- 当虚拟机启动时，初始化用户指定的主类
- 当遇到用以新建目标类实例的`new`指令，初始化`new`指令的目标类
- 当遇到调用静态方法的指令时，初始化该静态方法所在的类
- 当遇到访问静态字段的指令时，初始化该静态字段所在的类
- 子类的初始化会自动触发父类的初始化
- 如果接口定义了`default`方法，那么直接实现或间接实现该接口类的初始化，会触发接口的初始化
- 使用反射API针对某个类进行反射调用时，初始化这个类
- 当初次调用`MethodHandle`实例时，初始化该`MethodHandle`所执行的方法所在的类

```java
package com.jdk.test.demo.java.jvm;

public class Singleton {

    static {
        System.out.println("parent <clint>");
    }

    private static class LazyHolder {
        static final Singleton INSTANCE = new Singleton();

        static {
            System.out.println("<clint>");
        }
    }

    public static Object getInstance(boolean flag) {
        if (flag) {
            // 通过创建数组，只是引用了类对象，并加载类对象，并没有触发类型初始化操作
            return new LazyHolder[2];
        }
        // 触发了类型初始化操作, 因为INSTANCE是引用类型，最终会初始化。
        return LazyHolder.INSTANCE;
    }
    
    public static void main(String[] args) {
        
        Singleton.getInstance(true);
        System.out.println("---");
        Singleton.getInstance(false);
    }
}

```

### 修改字节码

```shell
# 通过asmtools修改字节码为不合规范，查看有什么变化
java -cp d:/projects/asmtools.jar org.openjdk.asmtools.jdis.Main Singleton\$LazyHolder.class > Singleton\$LazyHolder.jasm

# 可以通过编辑器打开jasm文件，并将stack 1 修改为stack 0

# 通过以下命令重新生成class文件
java -cp d:/projects/asmtools.jar org.openjdk.asmtools.jasm.Main Singleton\$LazyHolder.jasm

# 执行程序
java -verbose:class Singleton

```

通过以上操作，可以查看，其实在`getInstance(false)`才出发了`链接中的验证步骤`

```java
[Loaded sun.launcher.LauncherHelper$FXHelper from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]
[Loaded java.lang.Class$MethodArray from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]
[Loaded java.lang.Void from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]
parent <clint>
[Loaded com.jdk.test.demo.java.jvm.Singleton$LazyHolder from file:/D:/projects/spring/jdk-test-demo/src/main/java/]
---
[Loaded java.lang.VerifyError from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]
Exception in thread "main" [Loaded java.lang.Throwable$PrintStreamOrWriter from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]
[Loaded java.lang.Throwable$WrappedPrintStream from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]
[Loaded java.util.IdentityHashMap from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]
[Loaded java.util.IdentityHashMap$KeySet from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]
java.lang.VerifyError: Operand stack overflow
Exception Details:
  Location:
    com/jdk/test/demo/java/jvm/Singleton$LazyHolder.<init>()V @0: aload_0
  Reason:
    Exceeded max stack size.
  Current Frame:
    bci: @0
    flags: { flagThisUninit }
    locals: { uninitializedThis }
    stack: { }
  Bytecode:
    0x0000000: 2ab7 0006 b1

        at com.jdk.test.demo.java.jvm.Singleton.getInstance(Singleton.java:21)
        at com.jdk.test.demo.java.jvm.Singleton.main(Singleton.java:27)
[Loaded java.lang.Shutdown from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]
[Loaded java.lang.Shutdown$Lock from C:\Program Files\Java\jre1.8.0_144\lib\rt.jar]

```

