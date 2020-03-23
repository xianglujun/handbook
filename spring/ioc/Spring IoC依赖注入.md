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

