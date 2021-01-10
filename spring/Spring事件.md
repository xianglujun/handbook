# Spring 事件

## Java事件/监听器编程模型

- 设计模式 - 观察者模式扩展
  - 可观者对象 = Observable
  - 观察者 = Observer
- 标准化接口
  - 事件对象 - EventObject
  - 事件监听器 - EventListener

## 面向接口的事件、监听器设计模式

- 事件/监听器场景距离

  | Java技术规范    | 事件接口                              | 监听接口                                 |
  | --------------- | ------------------------------------- | ---------------------------------------- |
  | JavaBeans       | java.beans.PropertyChangeEvent        | java.beans.PropertyChangeListener        |
  | Java AWT        | java.awt.event.MouseEvent             | java.awt.event.MouseListener             |
  | Java Swing      | javax.swing.event.MenuEvent           | javax.swing.event.MenuListener           |
  | Java Preference | java.util.prefs.PreferenceChangeEvent | java.util.prefs.PreferenceChangeListener |

## 面向注解的事件/监听器设计模式

| Java技术规范 | 事件注解       | 监听器注解  |
| ------------ | -------------- | ----------- |
| Servlet 3.0+ |                | WebListener |
| JPA 1.0+     | @PostPersist   |             |
| Java Common  | @PostConstruct |             |
| EJB 3.0+     | @PrePassive    |             |
| JSF 2.0+     | @ListenerFor   |             |

## Spring标准事件 - ApplicationEvent

- Java标准事件 java.util.EventObject扩展
  - 扩展特性：事件发生时间戳
- Spring应用上下文ApplicationEvent扩展 - ApplicationContextEvent
  - Spring应用上下文(ApplicationContext)作为事件源
  - 具体实现:
    - `org.springframework.context.event.ContextClosedEvent`
    - `org.springframework.context.event.ContextRefreshedEvent`
    - `org.springframework.context.event.ContextStartedEvent`
    - `org.springframework.context.event.ContextStoppedEvent`

## 基于接口的Spring事件监听器

- Java 标准事件监听器 java.util.EventListener扩展
  - 扩展接口 -  `org.springframework.context.ApplicationListener`
  - 设计特定：单一类型事件处理
  - 处理方法：`onApplicationEvent(ApplicationEvent)`
  - 事件类型：``org.springframework.context.ApplicationEvent`

## 基于注解的Spring事件监听器

- Spring注解 - @org.springframework.context.event.EventListener

  | 特性                 | 说明                                     |
  | -------------------- | ---------------------------------------- |
  | 设计特点             | 支持多ApplicationEvent类型，无需接口约束 |
  | 注解目标             | 方法                                     |
  | 是否支持异步执行     | 支持                                     |
  | 是否支持泛型事件类型 | 支持                                     |
  | 是否支持顺序控制     | 支持，配置@Order注解控制                 |

  ## Spring事件发布器

  - 通过ApplicationEventPublisher发布Spring事件
    - 获取ApplicationEventPublisher
      - 依赖注入
  - 通过ApplicationEventMulticaster发布Spring事件
    - 获取ApplicationEventMulticaster
      - 依赖注入
      - 依赖查找

  ## Spring层次性上下文事件传播

  - 发生说明

    当Spring应用出现多层次Spring应用上下文时，如Spring MVC, Spring Boot或Spring Cloud场景下，由子ApplicationContext发起Spring事件可能会传递到其Parent ApplicationContext的过程

  - 如何避免

    - 定位Spring事件源进行过滤处理

## Spring内建事件

- AppplicationContextEvent 派生事件
  - ContextRefreshedEvent: Spring 应用上下文就绪事件
  - ContextStartedEvent
  - ContextStopedEvent
  - ContextClosedEvent

## Spring 4.2 Payload事件

- Spring Payload事件 - PayloadApplicationEvent
  - 使用场景：简化Spring事件发送，关注事件源主题
  - 发送方法
    - ApplicationEventPublisher.publishEvent()

## 依赖查找ApplicationEventMulticaster

- 查找条件
  - Bean名称: `applicationEventMulticaster`
  - Bean类型：`ApplicationEventMulticaster`

## 同步和异步Spring事件广播

- 基于实现类 = SimpleApplicationEventMulticaster
  - 切换模式： setTaskExecutor(Executor)方法
    - 默认模式：同步
    - 异步模式: ThreadPoolExecutor
  - 设计缺陷：
    - 非基于接口契约编程
- 基于注解 - EventListener
  - 模式切换
    - 模式模式：同步
    - 异步标注： @org.springframework.scheduling.annotation.Async
  - 实现限制：无法直接实现同步/异步动态切换

## Spring 4.1 事件异常处理

- Spring 3.0 错误处理接口 - `org.springframework.util.ErrorHandler`
  - 使用场景
    - Spring 事件
      - SimpleApplicationEventMulticaster - Spring 4.1开始支持
    - Spring 本地调度(scheduling)
      - `org.springframework.sheduling.concurrent.ConcurrentTaskScheduler`
      - `org.springframework.sheduling.concurrent.ThreadPoolTaskScheduler`

## Spring 事件/监听器实现原理

- 核心类 - `org.springframework.context.event.SimpleApplicationEventMulticaster`
  - 设计模式：观察模式扩展
  - 执行模式：同步/异步
  - 异常处理：ErrorHandler
  - 泛型处理：ResolvableType