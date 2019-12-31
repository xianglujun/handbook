<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [refresh()过程](#refresh过程)
	- [总结](#总结)
		- [预置系统的实例对象](#预置系统的实例对象)
	- [prepareRefresh](#preparerefresh)
	- [obtainFreshBeanFactory](#obtainfreshbeanfactory)
	- [prepareBeanFactory](#preparebeanfactory)
	- [postProcessBeanFactory(BeanFactory beanFactory)](#postprocessbeanfactorybeanfactory-beanfactory)
	- [invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory beanFactory)](#invokebeanfactorypostprocessorsconfigurablelistablebeanfactory-beanfactory)
	- [registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory)](#registerbeanpostprocessorsconfigurablelistablebeanfactory-beanfactory)
	- [initMessageSource()](#initmessagesource)
	- [initApplicationEventMulticaster()](#initapplicationeventmulticaster)
	- [onrefresh()](#onrefresh)
	- [registerListeners()](#registerlisteners)
	- [finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory)](#finishbeanfactoryinitializationconfigurablelistablebeanfactory-beanfactory)
	- [finishRefresh()](#finishrefresh)

<!-- /TOC -->
# refresh()过程
记录在`AbstractApplicationContext`中对于`refresh()`方法的执行过程, 该方法使用了`模板方法模式`, 通过`hook`的方式完成刷新过程

## 总结
需要在容器启动过程中, 自动化做一下事情
### 预置系统的实例对象
  - systemProperties
  - systemEnvironment
  - loadTimeWeaver
  - messageSource
  - applicationEventMulticaster
  - conversionService(会提前初始化)

## prepareRefresh
该方法主要是在做刷新前的准备, 主要做了两件事情
  - 记录容器启动时间 startDate
  - 标记当前的容器状态为 active=true

## obtainFreshBeanFactory
  获取`BeanFactory`对象, 这个对象包括了加载所有的`BeanDefinition`的对象
  - 通过refreshBeanFactory() 创建`BeanFactory`并加载`BeanDefinition`的定义
  - [loadBeanDefinitions加载过程](./FileSystemXmlApplicationContext的loadBeanDefinitions加载.md)

## prepareBeanFactory
对BeanFactory的准备工作, 包括设置BeanFactory的特性, 例如: 设置`ClassLoader`已经设置必要的`post-processors`. 在该方法中, 需要设置必要的`post-processors`, 并且定义需要忽略依赖的实例, 以及不需要定义，预先实例化的实例, 和与系统配置相关的实例信息。
  - 设置类加载器: 已设置 > 线程ClassLoader > 当前`ClassUtils`的加载器
  - 设置`setExpressionResolver`为`StandardBeanExpressionResolver`
  - 添加`addPropertyEditorRegistrar`为`ResourceEditorRegistrar(ResourceLoader this)`
  - 配置容器的回调函数
    - `addBeanPostProcessor()`为`ApplicationContextAwareProcessor(ConfigurableApplicationContext context)`
    - `ignoreDependencyInterface(Class clazz)`用于向`BeanFactory`中注入在`Autowiring`时需要忽略的类型, 在默认情况下只有`BeanFactoryAware`会被忽略, 在`AbstractApplicationContext`中, 新增了`ResourceLoaderAware`, `ApplicationEventPublisherAware`, `MessageSourceAware`, `ApplicationContextAware`
  - 配置必要的实例到当前的BeanFactory之中`registerResolvableDependency(Class key, Object value)`
    - BeanFactory.class: objectFactory(当前容器)
    - ResourceLoader: 当前对象(`AbstractApplicationContext` 子类)
    - ApplicationEventPublisher: 当前对象(`AbstractApplicationContext` 子类)
    - ApplicationContext: 当前对象(`AbstractApplicationContext` 子类)
  - 判断是否包含了`loadTimeWeaver`的定义,
    - 如果包含了，则添加`LoadTimeWeaverAwareProcessor(BeanFactory beanFactory)`到`addBeanPostProcessor`列表之中, 该`BeanPostProcessor`主要目的是在`Bean`初始化之前, 在`Bean`中设置进入`LoadTimeWeaver`对象
    - `setTempClassLoader()`为`ContextTypeMatchClassLoader()`类加载器
  - 判断`BeanFactory`中是否包含了`systemProperties`的`Bean`
    - 如果不包含, 则获取`System.getProperties`并通过`registerSingleton(String name, Object value)`注册到单例的集合之中
  - 判断是否包含了`systemEnvironment`实例
    - 如果没有包含, 则通过`System.getenv`方法获取所有的系统环境的变量, 并将当前获取到的`Map<String, String>`配置信息注入到`DefaulSingletonBeanRegistry`的单例列表之中.

## postProcessBeanFactory(BeanFactory beanFactory)
  这是对BeanFactory的一些后置处理, 该方法是一个`hook`方法, 用于对在BeanFactory的一些后置处理信息. 根据文档注释, 该方法能够加载一部分`bean definitions`并且在某些 `Application context`中, 设置`BeanPostProcessors`
  > Modify the application context's internal bean factory after its standard
	 initialization. All bean definitions will have been loaded, but no beans
	 will have been instantiated yet. This allows for registering special
	 BeanPostProcessors etc in certain ApplicationContext implementations.

## invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory beanFactory)
  该方法主要是初始化并执行所有的`BeanFactoryPostProcessor`的`beans`, 该执行顺序是按照给定的顺序执行.
  `该方法必须在单例实例化之前执行`, 这里的执行有一部分会按照`ordered`获得`priorityordered`进行排序, 已完成对不同权重的要求.
  - 判断当前的`ConfigurableListableBeanFactory`是`BeanDefinitionRegistry`的实例, 如果集成了这个实例 ,就需要我们去注册的`Bean`实例中, 根据类型获取到所有的`BeanFactoryPostProcessor`
    - 获取当前`ApplicationContext`的所有注册的`getBeanFactoryPostProcessors`
    - 遍历当前配置的所有的`BeanFactoryPostProcessor`, 如果当前的类型为`BeanDefinitionRegistryPostProcessor`的实例, 执行`postProcessBeanDefinitionRegistry`方法, 并加入`registryPostProcessors`的列表
    - 如果实例为`BeanFactoryPostProcessor`, 则加入`regularPostProcessors`列表之中
    - 从容器中获取`BeanDefinitionRegistryPostProcessor`注册的实例, 并实例和返回.
    - 将`BeanDefinitionRegistryPostProcessor`按照`priorityordered`或者`Ordered`进行顺序排列, 配置的值越小, 则优先级越高, 最终会导致没有配置优先级的类最后执行
    - 执行所有的`BeanFactoryPostProcessor`列表, 执行的顺序为: 当前`ApplicationContext`的`BeanDefinitionRegistryPostProcessor` > `BeanFactory`的`BeanDefinitionRegistryPostProcessor` > 当前`ApplicationContext`的`BeanFactoryPostProcessor`
  - 如果当前的`ConfigurableListableBeanFactory`没有不是`BeanDefinitionRegistry`的实例的时候, 这时就直接执行当前的`ApplicationContext`注册的`BeanFactoryPostProcessor`
  - 获取`ConfigurableListableBeanFactory`中所有的`BeanFactoryPostProcessor`, 并遍历列表
    - 这里的遍历, 则需要过滤掉已经执行过的`BeanFactoryPostProcessor`, 并忽略
    - 将没有执行到的`BeanFactoryPostProcessor`加入到列表
    - 如果获取到的定义`BeanFactoryPostProcessor`, 并判断是否包含了`Ordered`或者`PriortyOrdered`的定义, 如果有，则加入`orderedBeanFactoryPostProcessors`; 如果没有则加入`nonOrderedBeanFactoryPostProcessors`的列表
    - 将`orderedBeanFactoryPostProcessors`按照`priority`进行排序
    - 优先执行`orderedBeanFactoryPostProcessors`中的`BeanFactoryPostProcessor`的`postProcessBeanFactory`方法
    - 然后执行`nonOrderedBeanFactoryPostProcessors`中的`BeanFactoryPostProcessor`的`postProcessBeanFactory`方法
## registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory)
发方法用于初始化和执行所有的`BeanPostProcessor`
的对象, 期望是按照明确的顺序执行
  - 从当前的`BeanFactory`中加载所有的`BeanPostProcessor`的`beanName`列表
  - 向当前的`BeanFactory`中加入一个`BeanPostProcessor`, 用于对当前的`BeanPostProcessor`的数量进行检查,`BeanPostProcessorChecker`
  - 根据`beanName`获取对应的`bean`的`class`, 并判断是否为`Ordered`或者`PriorityOrdered`的子类, 如果是, 则放入`orderedBeanPostProcessor`列表中.
  - 如果没有定义顺序, `Ordered`或者`PriorityOrdered`, 则放入`nonOrderedBeanPostProcessors`
  - 如果`bean`的`class`为`MergedBeanDefinitionPostProcessor`的实例, 则放入`internalPostProcessor`列表之中
  - 排序`BeanPostProcessor`的顺序, 优先执行继承了`PriorityOrderd`的`Bean` > `Ordered`的`Bean` > 执行没有优先级的`Bean`(这个过程中会初始化所有的bean实例)
  - 然后将`BeanPostProcessor`的实例放入到`BeanFactory`中的`addBeanPostProcessor`之中，顺序为`priority order bean` > `ordered bean` > `beanpostprocessor bean` > `internal bean(MergedBeanDefinitionPostProcessor)`
  - 新增一个`ApplicationListenerDetector`的`BeanPostProcessor`, 该类主要用来自动探测`ApplicationListener`对象, 并加入到当前的`ApplicationContext`的容器之中

## initMessageSource()
对上下问中的消息源进行处理,
  - 通过`constainLocalName(String beanName)`判断`messageSource`是否已经包含对应的`bean`
    - 该判断不会去`parent`容器中去获取bean
    - 该`beanName`可以是`singletonBean`或者是在`BeanFactory`中已经加载的`BeanDefintion`
    - 并且满足`不能是factoryBean名称(以&开头)`或者是可以`FactoryBean`对象
    - 从当前`BeanFactory`中获取并初始化`messageSource`的`MessageSource`的实例,
  - 如果当前的`BeanFactory`并不包含`messageSource`的实例或者定义
    - 创建`DelegateMessageResource` 对象用于处理`MessageSource`的所有的请求, 并通过`getInternalParentMessageSource`获取当前上下文的`MessageSource`作为其`parent`
    - 将`DelegateMessageResource`作为`messageSource`作为默认的`MessageSource`进行注册,将当前的实例通过`registerSingleton(String beanName, Object)`注入到单例模式中集合之中

## initApplicationEventMulticaster()
初始化`ApplicationEventMulticaster`实例, 如果`BeanFactory`容器中没有明确的定义, 则使用`SimpleApplicationEventMulticaster`作为默认的广播机制进行实践的发送.<span style='color: red;'>当前初始化的`ApplicationEventMulticaster`实例是与当前的`AbstractApplicationContext`进行绑定的</span>

  - 判断当前`ApplicatinContext`管理的上下文中是否包含了`beanName`为`applicationEventMulticaster`的实例或者`BeanDefinition`的定义。
    - 如果容器包含了`applicationEventMulticaster`的对应的实例或者定义, 通过`BeanFactory`的`getBean`方法对`ApplicationEventMulticaster`的`bean`进行初始化
  - 如果`BeanFactory`中没有定义对应的`ApplicationEventMulticaster`的实例, 则初始化`SimpleApplicationEventMulticaster`实例，并与当前的`ApplicationContext`进行绑定

## onrefresh()
> Template method which can be overridden to add context-specific refresh work.
	 * Called on initialization of special beans, before instantiation of singletons.
	 * This implementation is empty.(模板方法能够被重写, 用于添加容器规范的刷新工作. 在初始化单例的实例之前, 初始化一些特别的bean)

## registerListeners()
> * Add beans that implement ApplicationListener as listeners.
	* Doesn't affect other listeners, which can be added without being beans.(添加一些继承了`ApplicationListener`一些`Bean`信息, 不会影响到其他的一些监听器, 可以添加不是beans的监听器)
- 获取`AbstractApplicationContext`中已经注册的`getApplicationListeners`的信息, 并注册到`ApplicationEventMulticaster`的容器之中
- 并根据`ApplicationListener`类型到`BeanFactory`中寻找已经注册的`beanName`列表, 但是并不会初始化这些bean实例, 通过`ApplicationEventMulticaster`将这些`beanName`注册到`addApplicationListenerBean`实例之中, 以便于使用

## finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory)
当前方法用于结束初始化`BeanFactory`, 并初始化所有的`non-lazy-init`的实例
  - 判断当前是否包含了`conversionService`的`bean`的定义, 如果包含了对应的定义, 则将当前的`ConversionService`进行初始化
  - 停止临时的类加载器, 该类加载器用于类型的匹配。
  - 冻结`BeanFactory`的配置, 主要用于保存`BeanDefinition`的配置信息，并不允许对`BeanDefinition`再次进行修改, 并且不能执行`post-processors`的进一步操作. 但是可以继续添加`BeanDefinition`
  - 预加载`BeanFactory`中的单例模式的定义`non-lazy-init`

## finishRefresh()
该方法用于结束容器的刷新, 主要会执行`LifeCycleProcessor.`的`onFresh`方法以及发布`ContextRefreshedEvent`的通知事件
  - 初始化声明周期处理器, `LifeCycleProcessor`. 在容器中查找`lifecycleProcessor`的对应的`BeanDefinition`定义, 如果找到, 则实例化对应的`LifeCycleProcessor`的实例
  - 如果容器中没有定义`LifeCycleProcessor`的实例, 实例化`DefaultLifeCycleProcessor`的实例, 并将当前的对象与`ApplicationContext`容器进行绑定, 通过`registerSingleton(String beanName, Object value)`的方法将当前的`LifeCycleProcessor`注册到容器之中.
  - 执行`LifeCycleProcessor`的`onFresh()`方法,
  - 发布容器刷新完成的事件通知
