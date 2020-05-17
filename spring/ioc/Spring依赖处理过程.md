# 依赖处理过程

- 基础知识
  - 入口 - `DefaultListableBeanFactory#resolveDependency`
  - 依赖描述符 - `DepencencyDescriptor`
  - 自动绑定候选对象处理器 - `AutowireCandidateResolver`

## @Autowired 注入

- `@Autowired`注入过程
  - 元信息解析
  - 依赖查找
  - 依赖注入(`字段`, `方法`)

## @Inject 注入

- @Inject注入过程
  - 如果`JSR-330`存在于`ClassPath`中，复用`AutowiredAnnotationBeanPostProcessor`实现



## Java通用注解注入原理

- CommonAnnotationBeanPostProcessor
  - 注入注解
    - java.xml.ws.WebServiceRef
    - javax.ejb.EJB
    - javax.annotation.Resource
  - 声明周期注解
    - javax.annotation.PostConstruct
    - java.annotation.PreDestroy

## 自定义依赖注入注解

- 基于`AutowiredAnnotationBeanPostProcessor`实现
- 自定义实现
  - 声明周期处理
    - InstantiationAwareBeanPostProcessor
    - MergedBeanDefinitionPostProcessor
  - 元数据
    - InjectedElement
    - InjectionMetadata