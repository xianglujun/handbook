# Spring IoC依赖查找

## 依赖查找的今世前生

- 单一类型依赖查找
  - JNDI - javax.naming.Context#lookup
  - JavaBeans - BeanContext
- 集合类型依赖查找
  - java.beans.beancontext.BeanContext
- 层次依赖查找
  - java.beans.beancontext.BeanContext

## 单一类型查找

- 单一类型依赖查找接口 - BeanFactory
  - 根据Bean名称查找
    - getBean(String)
    - Spring 2.5默认覆盖参数： getBean(String, Object)
  - 根据Bean类型查找
    - Bean实时查找
      - Spring 3.0 getBean(Class)
      - Spring 4.1覆盖默认参数: getBean(Clas, Object..)
    - Spring 5.1 Bean延时查找
      - getBeanProvider(Class)
      - getBeanProvider(ResolvableType)
  - 根据Bean名称 + 类型查找: getBean(String, Class)

## 集合类型依赖查找

- 集合类型依赖查找接口 - `ListableBeanFactory`
  - 根据Bean类型查找
    - 获取同类型Bean名称列表
      - getBeanNamesForType(Class)
      - Spring 4.2 getBeanNamesForType(ResolvableType)
    - 获取同类型Bean实例列表
      - getBeansOfType(Class)以及重载方法
  - 通过注解类型查找
    - Spring 3.0 获取标注类型Bean名称列表
      - getBeanNamesForAnnotation(Class<? extends Annotation>)
    - Spring 3.0 获取标注类型Bean实例列表
      - getBeanWithAnnotation(Class<? extends Annotation>)
    - Spring 3.0 获取指定名称 + 指定类型Bean实例
      - findAnnotationOnBean(String, Class<? extends Annotation>)

## 层次依赖查找

- 层次性依赖查找接口 - `HierarchicalBeanFactory`
  - 双亲`BeanFactory`: `getParentBeanFactory`
  - 层次性查找
    - 根据Bean名称查找
      - 基于`containsLocalBean`方法实现
    - 根据Bean类型查找实例列表
      - 单一类型: `BeanFactoryUtils#beanOfType`
      - 集合类型:`BeanFactoryUtils#beansOfTypeIncludingAncestors`
  - 根据Java注解查找名称列表
    - `BeanFactoryUtils#beanNamesForTypeIncludingAncestors`

## 延迟依赖查找

- Bean延迟依赖查找接口
  - `org.springframework.beans.factory.ObjectFactory`
  - `org.springframework.beans.factory.ObjectProvider`
    - `spring5` 对Java8特性扩展
      - 函数式接口
        - `getIfAvailable(Supplier)`
        - `ifAvailable(Consumer)`
      - String 扩展 - `stream()`;

## 安全依赖查找

- 依赖性查找安全性对比

| 依赖查找类型 | 代表实现                           | 是否安全 |
| ------------ | ---------------------------------- | -------- |
| 单一类型查找 | BeanFactory#getBean                | 否       |
|              | ObjectFactory#getObject            | 否       |
|              | ObjectProvider#getIfAvailable      | 是       |
| 集合类型查找 | ListableBeanFactory#getBeansOfType | 是       |
|              | ObjectProvider#stream              | 是       |

> 注意: 层次依赖查找的安全性取决于其扩展的单一或集合类型的`BeanFactory`接口

## 内建可查找的依赖

| Bean名称                    | Bean实例                        | 使用场景               |
| --------------------------- | ------------------------------- | ---------------------- |
| environment                 | Environment对象                 | 外部化配置以及Profiles |
| systemPropertites           | java.util.Properties对象        | Java系统属性           |
| systemEnvironment           | java.util.Map对象               | 操作系统环境变量       |
| messageSource               | MessageSource对象               | 国际化文案             |
| lifecycleProcessor          | LifecycleProcessor对象          | Lifecycle Bean处理器   |
| applicationEventMulticaster | ApplicationEventMulticaster对象 | Spring事件广播器       |

- 注解驱动Spring应用上下文内建可查找的依赖(`部分`)

| Bean名称                                                     | Bean实例                                    | 使用场景                                                |
| ------------------------------------------------------------ | ------------------------------------------- | ------------------------------------------------------- |
| org.springframework.context.annotation.internalConfigurationAnnotationProcessor | ConfigurationClassPostProcessor对象         | 处理Spring配置类                                        |
| org.springframework.context.annotation.internalAutowiredAnnotationProcessor | AutowiredAnnotationBeanPostProcessor对象    | 处理`@Autowired`以及`@Value`注解                        |
| org.springframeword.context.annotation.internalCommonAnnotationProcessor | CommonAnnotationBeanPostProcessor对象       | (条件激活)处理`JSR-250`注解，如`@PostConstruct`         |
| org.springframework.context.event.internalEventListenerProcessor | EventListenerMethodProcessor对象            | 处理标注`@EventListener`的Spring事件监听方法            |
| org.springframework.context.event.internalEventListenerFactory | DefaultEventListenerFactory对象             | `@EventListener`事件监听方法适配为`ApplicationListener` |
| org.spring.framework.context.annotation.internalPersistenceAnnotationProcessor | PersistenceAnnotationBeanPostProcessor对象` | "条件激活"处理JPA注解场景                               |

