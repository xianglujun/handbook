# Spring 配置元信息

- 配置元信息
  - Spring Bean 配置元信息 - BeanDefinition
  - Spring Bean 属性元信息 - PropertyValues
  - Spring 容器配置元信息
  - Spring 外部化配置元信息=PropertySource
  - Spring Profile元信息 - @Profile

## Spring Bean配置元信息

- Bean配置元信息 - BeanDefinition
  - GenericBeanDefinition ：通用性BeanDefinition
  - RootBeanDefinition: 五Parent的BeanDefinition或者合并后BeanDefinition
  - AnnotatedBeanDefinition: 注解标注的BeanDefinition

## Spring Bean 属性元信息

- Bean 属性元信息 - PropertyValues
  - 可修改实现 - MutablePropertyValues
  - 元素成员 - PropertyValue
- Bean 属性上下文存储 - AttributeAccessor
- Bean 原信息元素 - `BeanMetadataElement`

## Spring 容器配置元信息

| bean元素属性                | 默认值  | 使用场景                                                     |
| --------------------------- | ------- | ------------------------------------------------------------ |
| profile                     | null    | Spring Profiles 配置值                                       |
| default-lazy-init           | default | 当outter beans "default-lazy-init"属性存在时，继承该值，否则为`false` |
| default-merge               | default | 当outter beans "default-merge"属性存在时，继承该值，否则为`false` |
| default-autowire            | default | 当outter beans "default-autowire"属性存在时，继承该值，否则为`no` |
| default-autowire-candidates | null    | 默认Spring Beans 名称`pattern`                               |
| default-init-method         | null    | 默认Spring Beans自定义初始化方法                             |
| default-destroy-method      | null    | 默认Spring Beans自定销毁方法                                 |

- Spring XML 配置元信息 - 应用上下文相关

| XML元素                        | 使用场景                            |
| ------------------------------ | ----------------------------------- |
| <context:annotation-config/>   | 激活spring 注解驱动                 |
| <context:component-scan/>      | Spirng @Component以及自定义注解扫描 |
| <context:load-time-weaver/>    | 激活Spring LoadTimeWeaver           |
| <context:mbean-export/>        | 暴露Spring Beans 作为JMX Beans      |
| <context:mbean-server>         | 将当前平台作为MBeanServer           |
| <context:property-placeholder> | 加载外部配置资源作为Spring配置属性  |
| <context:porperty-override>    | 利用外部化配置资源覆盖Spring属性值  |

## 基于XML资源装载Spring Bean配置元信息

- Spring Bean 配置元信息(`XmlBeanDefinitionReader`)

  | XML元素        | 使用场景                          |
  | -------------- | --------------------------------- |
  | <beans:beans/> | 单XML资源下的多个Spring Beans配置 |
  | <beans:bean/>  | 单个Spring Bean定义配置           |
  | <beans:alias>  | 为Spring Bean定义映射别名         |
  | <beans:import> | 加载外部Spring XML配置资源        |

## 基于Properties 资源装载Spring Bean配置元信息

- Spring Bean 配置元信息(`PropertiesBeanDefintionReader`)

  | properties  | 使用场景                      |
  | ----------- | ----------------------------- |
  | (class)     | Bean类全限定名                |
  | (abstract)  | 是否为抽象的BeanDefinition    |
  | (parent)    | 指定parent BeanDefinition名称 |
  | (lazy-init) | 是否为延迟加载                |
  | (ref)       | 引用其他Bean的名称            |
  | (scope)     | 设置Bean中scope属性           |
  | ${n}        | n表示第n+1个构造器参数        |

  ## 基于Java注解装载Spring Bean配置元信息

  - Spring模式注解

    | Spring注解     | 场景说明          | 其实版本 |
    | -------------- | ----------------- | -------- |
    | @Repository    | 数据仓库模式注解  | 2.0      |
    | @Component     | 通用组件模式注解  | 2.5      |
    | @Service       | 服务模式注解      | 2.5      |
    | @Controller    | Web控制器模式注解 | 2.5      |
    | @Configuration | 配置类模式注解    | 3.0      |
    |                |                   |          |

  - Spring Bean依赖注入注解

    | Spring注解 | 场景说明                           | 起始版本 |
    | ---------- | ---------------------------------- | -------- |
    | @Autowired | Bean依赖注入，支持多种依赖查找方式 | 2.5      |
    | @Qualifier | 细粒度的@Autwoired依赖查找         | 2.5      |

    | Java注解  | 场景说明         | 起始版本 |
    | --------- | ---------------- | -------- |
    | @Resource | 类似于@Autowired | 2.5      |
    | @Inject   | 类似于@Autowired | 2.5      |

  - Spring Bean条件装配注解

    | Sring注解    | 场景说明       | 起始版本 |
    | ------------ | -------------- | -------- |
    | @Profile     | 配置化条件装配 | 3.1      |
    | @Conditional | 编程条件装配   | 4.0      |

  - Spring Bean声明周期回调

    - @PostConstruct
    - @PreDestroy

## 基于Extensible XML authoring 扩展spring xml元素

- Spring XML扩展
  - 编写XML Schema文件： 定义XML结构
  - 自定义`NamespaceHandler`实现： 命名空间绑定
  - 自定义`BeanDefinitionParser`实现：XML元素与BeanDefinition解析
  - 注册XML扩展: 命令空间与XML schema映射

## 基于Properties资源装载外部化配置

- 注解驱动
  - @org.springframework.context.annotation.PropertySource
  - @org.springframework.context.annotation.PropertySources
- API编程
  - org.springframework.core.env.PropertySource
  - org.springframework.core.env.PropertySources