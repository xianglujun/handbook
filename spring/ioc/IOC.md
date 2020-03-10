# IOC

## 主要实现策略

- 使用服务定位模式
- 通过依赖注入
  - 构造器注入
  - 参数注入
  - 属性注入
  - 接口注入
- Using a contextualized lookup
- Using template method design pattern
- Using strategy design pattern
- `Dependency Lookup`
- `Dependency Injection`

## 职责

- To decouple the execution of a task from implemetation
- To focus a module on the task it is designed for
- To free modules from assumptions about how other systems do what they do and instead rely on contracts
- To prevent side effects when replacing a module

### 总结

- 通用处理
- 依赖处理
  - 依赖查找
  - 依赖注入
- 生命周期管理
  - 容器
  - 托管的资源(Java Beans或其他资源)
- 配置
  - 容器
  - 外部化配置
  - 托管的资源(Java Beans或其他资源)

## 主要实现

- Java SE
  - Java Beans
  - Java ServiceLoader SPI
  - JNDI(Java Naming and Directory Interface)
- Java EE
  - EJB
  - Servlet
- 开源
  - Apache Avalon
  - PicoContainer
  - Google Guice
  - Spring Framework

### JavaBeans 作为Ioc容器

- 特性
  - 依赖查找
  - 生命周期管理
  - 配置元信息
  - 事件
  - 自定义
  - 资源管理
  - 持久化
- 规范
  - JavaBeans
  - BeanContext

## 轻量级IoC容器

- 管理应用代码
- 能够快速的启动
- 容器不需要特殊的部署步骤
- 容器能够占用较小的内存以及依赖
- 容器能够提供可管理的渠道。

## 依赖查找 VS. 依赖注入



| 类型     | 依赖处理 | 实现便利性 | 代码侵入性   | API依赖性     | 可读性 |
| -------- | -------- | ---------- | ------------ | ------------- | ------ |
| 依赖查找 | 主动获取 | 相对繁琐   | 侵入业务逻辑 | 依赖容器API   | 良好   |
| 依赖注入 | 被动提供 | 相对便利   | 低侵入性     | 不依赖容器API | 一般   |

## 依赖查找

- 根据Bean名称查找
  - 实时查找
  - 延迟查找（ObjectFactory）
- 根据Bean类型查找
  - 单个Bean对象
  - 集合Bean对象
- 根据Bean名称 + 类型查找
- 根据Java注解查找
  - 单个Bean对象
  - 多个Bean对象

## 依赖注入

- 根据Bean名称注入
- 根据Bean类型注入
  - 单个Bean对象
  - 集合Bean对象
- 注入容器内容Bean对象
- 注入非Bean对象
- 注入类型
  - 实时注入
  - 延迟注入