# Spring Bean声明周期

[toc]

## Spring Bean元信息配置阶段

- BeanDefinition配置
  - 面向资源
    - XML 配置
    - Properties资源配置
  - 面向注解
  - 面向API

## Spring Bean 元信息解析阶段

- 面向资源BeanDefinition解析
  - BeanDefinitionReader
  - XML解析器 - BeanDefinitionParser
- 面向注解BeanDefinition解析
  - AnnotatedBeanDefinitionReader

## Spring Bean 注册阶段

- BeanDefinition注册接口
  - BeanDefinitionRegistry 接口

## Spring BeanDefinition合并阶段

- BeanDefinition合并
  - 父子BeanDefinition合并
    - 当前BeanFactory查找
    - 层次性BeanFactory查找

## Spring Bean Class 加载阶段

- ClassLoader类加载
- Java Security 安全控制
- ConfiguragbleBeanFactory临时ClassLoader

## Spring Bean 实例化前阶段

- 非主流生命周期- Bean实例化前阶段
  - InstantiationAwareBeanPostProcessor#postProcessBeforeInstantiation

## Spring Bean实例化阶段

- 实例化方式
  - 传统实例化方式
    - 实例化策略 - InstantiationStrategy
  - 构造器依赖注入

## Spring Bean实例化后阶段

- Bean属性赋值(Poplulate)判断
  - InstantiationAwareBeanPostProcessor#postProcessAfterInstantiation

## Spring Bean 属性赋值前阶段

- Bean属性元信息
  - PropertyValues
- Bean属性赋值前回调
  - Spring 1.2 - 5.0: InstantiationAwareBeanPostProcessor#postProcessPropertyValues
  - Spring 5.1 - InstantiationAwareBeanPostProcess#postProcessorProperties

## Spring Bean Aware 接口回调阶段

- Spring Aware接口
  - BeanNameAware
  - BeanClassLoaderAware
  - BeanFactoryAware
  - `EnvironmentAware`
  - `EmbeddedValueResolverAware`
  - `ResourceLoaderAware`
  - `ApplicationEventPublisherAware`
  - `MessageSourceAware`
  - `ApplicationContextAware`

> 其中前三个为BeanFactory提供的Aware方法，后面为ApplicationContext提供的Aware

## Spring Bean初始化前阶段

- 方法回调
  - BeanPostProcessor#postProcessBeforeInitialization

## Spring Bean 初始化阶段

- Bean初始化(Initialization)
  - @PostConstruct 标注方法
  - 实现InitializingBean 接口afterProperties方法
  - 自定义初始化方法

## Spring Bean 初始化阶段

- 回调方法
  - BeanPostProcessor#postProcessAfterInitialization

## Spring Bean初始化完成阶段

- 方法回调
  - spring 4.1+: SmartInitializingSingleton#afterSingletonesInstantiated

## Spring Bean 销毁前阶段

- 方法回调
  - DestructionAwareBeanPostProcessor#postProcessBeaforeDestruction

## Spring Bean 销毁阶段

- Bean销毁
  - @PreDestroy标注方法
  - 实现DisposableBean接口的destroy()方法
  - 自定义销毁方法

## Spring Bean垃圾搜集

- Bean垃圾回收
  - 关闭Spring容器
  - 执行GC
  - Spring Bean覆盖的finalize()方法被回调