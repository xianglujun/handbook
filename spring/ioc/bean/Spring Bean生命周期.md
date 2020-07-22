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