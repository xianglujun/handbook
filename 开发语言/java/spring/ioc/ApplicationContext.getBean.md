
# getBean的执行流程
该章主要学习`getBean`方法的知识, 主要包括在`getBean`的时候做了哪些事情, 需要做一些什么操作。

其实在学习AbstractApplicationContext的时候, 其实就已经用到了`getBean`的方法，`refresh()`流程可以参考[spring refresh()过程](./spring_refresh过程.md)

在`ApplicationContext`的实例初始化完成之后, 我们就可以通过`ApplicationContext`进行获取`Bean`对象, 其实在`AbstractApplicationContext`中, `getBean`方法最终是交由内部维护的`BeanFactory`的`getBean`方法, 因此我们主要学习`BeanFactory.getBean`方法

## getBean(String beanName)
该方法主要通过`beanName`获取beanName的实例, 该方法不仅会加载当前的`bean`的定义元数据, 同时也会根据元数据进行对象的创建、解决`bean`之间的依赖、维护对象的引用等操作, 因此我们一步一步的查看该方法主要执行了什么样的流程。

### doGetBean(String beanName, final Class<?> requireType, final Object[] args, boolean typeCheckOnly)
  - 参数说明
    - beanName 需要查找的bean的名称, 该名称可以是`alias`获得`id`指定的属性
    - requireType 根据`Class`类型去检索`Bean`的实例
    - args 在创建`prototype`类型的实例时, 需要根据不同的构建参数创建对象
    - typeCheckOnly 获取bean的时候, 是否需要进行类型检查

  - transformedBeanName
  方法实现比较简单, 判断当前的`beanName`是否已`&`开头, 如果以`&`开头, 代表了当前的是一个`FactoryBean`的实例。然后从`SimpleAliasRegistry`判断当前的`beanName`是否为`alias`列表, 然后循环获取其中的`alias`的名称, 并返回.

  - 单例实例创建
    - `DefaultSingletonBeanRegistry.getSingleton(String beanName)`
    该方法主要是通过`DefaultSingletonBeanRegistry`内部管理的单例的实例集合来判断当前的`beanName`是否已经被创建, 如果被创建, 则可以直接返回对应的创建对象。
    - 如果获取到了单例的实例, 则需要判断当前的对象是否已经创建完成, 通过检查`singletonsCurrentlyInCreation`中是否包含了`beanName`来判断是否创建完成
    -
