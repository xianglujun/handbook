# Spring 注解

## Spring核心注解场景分了

- Spring模式注解

| Spring注解     | 场景说明          | 起始版本 |
| -------------- | ----------------- | -------- |
| @Repository    | 数据仓储模式注解  | 2.0      |
| @Component     | 通用组件模式注解  | 2.5      |
| @Service       | 服务模式注解      | 2.5      |
| @Controller    | Web控制器模式注解 | 2.5      |
| @Configuration | 配置类模式注解    | 3.0      |

- 装配注解

  | Spring注解      | 场景说明                                | 起始版本 |
  | --------------- | --------------------------------------- | -------- |
  | @Import         | 导入Configuration类                     | 2.5      |
  | @ComponentScan  | 扫描指定package下标注Spring模式注解的类 | 3.1      |
  | @ImportResource | 替换XML元素<import>                     | 2.5      |

- 依赖注入注解

| Spring注解 | 场景说明                           | 起始版本 |
| ---------- | ---------------------------------- | -------- |
| @Autowired | Bean依赖注入，支持多种依赖查找方式 | 2.5      |
| @Qualifier | 细粒度的@Autowired依赖查找         | 2.5      |

## Spring注解编程模型

- 编程模型
  - 元注解（Meta-Annotations）
  - Spring 模式注解(Stereotype Annotations)
  - Spring组合注解 (Composed Annotations)
  - Spring注解属性别名和覆盖 (Attribute Aliases and Overrides)

## Spring 元注解

表示了注解表示注解的一种方式.



## Spring 模式注解

- 理解@Component派生性

  元注解@Component的注解在XML元素<context:component-scan>或注解 @ComponentScan扫描中派生了@Component特性，并且从Spring framwork 4.0开始支持多层次派生性。

- 举例说明

  - @Repository
  - @Service
  - @Controller
  - @Configuration
  - @SpringBootConfiguration

- @Component 派生性原理

  - 核心组件 - ClasspathBeanDefinitionScanner
    - ClassPathScanningCandidateComponentProvider
  - 资源处理 - ResourcePatternResolver
  - 资源 - 类原信息
    - MetadataReaderFactory
  - 类元信息 - ClassMetadata
    - ASM 实现 - ClassMetadataReadingVisitor
    - 反射实现 - StandardAnnotationMetadata
  - 注解元信息 - AnnotationMetadata
    - ASM - AnnotationMetadataReadingVisitor
    - 反射实现 - StandardAnnotationMetadata