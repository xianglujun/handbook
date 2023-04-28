# AOP的相关概念

## Advice 通知
Advice作为通知, 定义了在切入点应该做什么,  为切面提供织入的功能。
- BeforeAdvice
- AfterAdvice
- ThrowAdvice

通知, 用于处理增强的函数回调, 在每个类中都定义了回调的函数, 在对PointCut的进行增强的时候, 会调用对应的通知回调函数进行相应的处理.

## Pointcut 切入点

切入点是指: 决定了那些对那些方法进行增强


## Advisor 通知器

通知器是堆通知和切入点的整合

## ProxyFactoryBean
在Spring中, AOP代理对象成生成都是使用`ProxyFactoryBean`作为入口, 通过`getObject`方法来生成AOP的代理对象

### AopProxy
![AopProxy创建序列图](../../img/spring/create_aop_proxy.png)

在Spring中, AOP一共有两个实现方式
- JdkDynamicAopProxy : 当被代理的对象是一个接口的时候, 采用这种方式
- Cglib2AopProxy: Cglib的方式, 除开接口意外的代理方式(会通过加载`net.sf.cglib.proxy.Enhancer`判断是否在CLASSPATH中引入了对应的包)
- 关于AOP的所有的配置, 都是存放在`AdvisedSupport`的类中

#### JdkDynamicAopProxy
- 本身是一个InvocationHandler的实现, 因此`JdkDynamicAopProxy`封装了所有的AOP的实现过程
- 通过`getProxy`创建代理对象

#### Cglib2AopProxy
- 通过CGLIB实现代理模式
- 通过设置Callbacks实现AOP的增强功能和回调
- 在`Cglib2AopProxy`中, 使用了`DynamicAdvisedInterceptor`实现对`Advice`的回调


## AOP 的实现原理
在AOP Proxy被创建的时候, 相关的拦截器(Advisor/Interceptor)已经被设置到了代理对象中去了, 拦截器在代理对象起作用是通过对拦截器对象的方法调用来实现的。

- JDK Proxy 的代理对象, 主要通过`InvocationHandler`来实现拦截器的回调
- CGLIB Proxy 使用第三方的代理实现, 需要遵循CGLIB的规范, 通过`DynamicAdvisedInterceptor`实现回调

### AdvisedSupport
`AdvisedSupport`实现了对`Advice`的配置信息, 以及`Advisor`进行管理

### DefaultAdvisorChainFactory
该类会根据`target`以及`method`从`AdvisedSupport`匹配能够使用的`Interceptor`列表, 并方便回调`Interceptor`

### DefaultAdvisorAdapterRegistry
该类主要做了一下三个事情
- 维护`BeforeAdvice`,`AfterAdvice`,`ThrowAdvice`的对应的`Adapter`的类
- 通过`wrap`方法将`Advice`包装成为`Advisor`对象
- 通过`Advisor`提供对应的`Interceptor`

### 实现
在Spring AOP中， 通过`MethodBeforeAdviceInterceptor`,`AfterReturningAdviceInterceptor`,`ThrowsAdviceInterceptor`来做具体的`Interceptor`的实现, 具体可以查看对应的源码

### 调用Interceptor
在`Spring AOP`中, 主要通过`MethodInvocation`完成对拦截器以及目标方法的调用，在`JdkDynamicAopProxy`和`Cglib2AopProxy`中, 都是通过`ReflectiveMethodInvocation`的`process()`方法完成对应拦截器链的调用。

> NOTE: 如何完成对拦截器链的调用? 1. 如果没有匹配到对应的方法拦截器, 则递归调用  2. 通过Interceptor的invoke方法, 在完成对应的Advice方法的时候, 则会继续调用MethodInvocation的process方法, 完成递归。


# ProxyFactory 方式实现AOP
ProxyFactory的实现方式, 与`ProxyFactoryBean`的实现方式很类似, 都是·`ProxyCreatorSupport`的子类, 都是以`getProxy`作为入口, 因此具体的调用和实现方式都类似, 都是`getAopProxyFactory().createAopProxy(AdvisedSupport)`来进行创建`AopProxy`
