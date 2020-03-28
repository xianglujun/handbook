# Spring IoC依赖注入

## 依赖注入的模式和类型

- 手动模式 - 配置或者变成的方式，提前安排注入规则
  - XML资源配置元数据
  - Java注解配置元信息
  - API配置元信息
- 自动模式 - 实现提供依赖自动关联的防护四，按照内建的注入规则
  - Autowiring(自动绑定)

### 依赖注入类型

| 依赖注入类型 | 配置元数据距离                                 |
| ------------ | ---------------------------------------------- |
| Setter方法   | <property name="user" ref="iserBean" />        |
| 构造器       | <constructor name="user" ref="useBean" />      |
| 字段         | @Autowire User user;                           |
| 方法         | @Autowired public void user(User user) {}      |
| 接口回调     | class MyBean implements BeanFactoryAware {...} |

## 自动绑定(Autowiring)模式

- Autowiring modes

  | 模式          | 说明                                                         |
  | ------------- | ------------------------------------------------------------ |
  | `no`          | 默认值，未激活Autowiring, 需要手动指定依赖注入对象           |
  | `byName`      | 根据被注入属性的名称作为Bean名称进行依赖查找，并将对象设置到该属性 |
  | `byType`      | 根据被注入属性的类型作为依赖类型进行查找，并将对象设置到该属性 |
  | `constructor` | 特殊`byType`类型，用于构造器参数                             |

  

### 自动绑定(Autowiring)的限制与不足

- 不能绑定`基本类型`, `String类型`, 以及`Classes`
- Spring 无法猜测模糊的结果，否则可能会导致不可预期的结果
- 在集合注入的时候，可能会导致模糊的注入。如果有多个bean 存在的时候，可能会抛出异常



### Setter方法注入

- 实现方法
  - 手动模式
    - XML 资源配置元信息
    - JAVA注解配置元信息
    - API配置元信息
  - 自动模式
    - byName
    - byType

## 构造器注入

- 实现方法
  - 手动模式
    - XML 资源配置元数据
    - Java注解配置元数据
    - API配置元数据
  - 自动模式
    - constructor

## 字段注入

- 实现方法
  - 手动模式
    - Java注解配置元信息
    - `@Autowired`(这种注入方式，会忽略掉静态字段)
    - `@Resource`
    - `@Inject`

## 方法注入

- 实现方法
  - 手动模式
    - Java注解配置元信息
      - @Autowired
      - @Resource
      - @Inject
      - @Bean(通过新的方式生成bean对象)

## 接口回调注入

| 内建接口                     | 说明                                                 |
| ---------------------------- | ---------------------------------------------------- |
| BeanFactoryAware             | 获取IoC容器 - BeanFactory                            |
| ApplicationContextAware      | 获取Spring应用上下文 - Application对象               |
| EnvironmentAware             | 获取Environment对象                                  |
| ResourceLoaderAware          | 获取资源加载对象- ResourceLoader                     |
| BeanClassLoaderAware         | 获取加载当前Bean Class 的ClassLoader                 |
| BeanNameAware                | 获取当前Bean的名称                                   |
| MessageResourceAware         | 获取MessageSource对象，用于Spring国际化              |
| ApplicationEventPublishAware | 获取ApplicationEventPublishAware对象，用于Spring事件 |
| EmbeddedValueResolverAware   | 获取StringValueResolver对象，用于占位符处理          |

## 依赖注入类型选择

- 注入选型
  - 低依赖: 构造器注入
  - 多依赖: Setter方法注入
  - 便利性: 字段注入
  - 声明类: 方法注入

## 基础类型注入

- 基础类型
  - `原生类型(Primitive)`: boolean, byte, char, short, int, float, long, double
  - `标量类型(Scalar)`: Number, Character, Boolean, Enum, Locale, Charset, Currency, Properties, UUID
  - `常规类型(General)`: Object, String, Timezone, Calendar, Optional 等
  - `Spring 类型`: Resource, InputSouce, Formatter等等

## 集合类型注入

- 集合类型
  - 数组类型(Array): 原生类型， 标量类型， 常规类型， Spring类型
  - 集合类型(Collection)
    - Collection: List, Set(SortedSet, NavigableSet, EnumSet)
    - Map: Properties