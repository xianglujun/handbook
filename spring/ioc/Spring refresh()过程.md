[toc]
# refresh()过程
记录在`AbstractApplicationContext`中对于`refresh()`方法的执行过程, 该方法使用了`模板方法模式`, 通过`hook`的方式完成刷新过程

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
