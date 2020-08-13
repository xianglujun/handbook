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

  

