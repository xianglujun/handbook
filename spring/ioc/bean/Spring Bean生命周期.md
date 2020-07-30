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

