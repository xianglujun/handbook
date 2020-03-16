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