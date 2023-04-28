# Spring Bean作用域

## 作用域

| 来源        | 说明                                                   |
| ----------- | ------------------------------------------------------ |
| prototype   | 原型作用域，每次依赖查找和依赖注入生成新bean对象       |
| singleton   | 默认Spring Bean作用域，一个BeanFactory有且仅有一个实例 |
| request     | 将Spring Bean 存储在ServletRequest上下文中             |
| session     | 将Spring Bean存储在HttpSession中                       |
| application | 将Spring Bean存储在ServletContext中                    |

### singleton Bean作用域



### prototype Bean 作用域

> Spring容器没有办法管理prototype Bean的完整声明周期，也没有办法记录实例的存在。销毁回调方法将不会执行，可以利用BeanPostProcessor进行清扫工作。

### request Bean作用域

- 配置
  - XML - <bean class="" scope="request">
  - Java注解 - @RequestScope 或 @Scope(WebApplicationContext.SCOPE_REQUEST)
- 实现
  - API - RequestScope

> 对于界面的渲染而言，对象都是新的对象，其实返给前端的对象都是变化的，通过代理的方式保证每个对象是新生成的，但是对于内部@Autowired对象而言，使用的CGLIB代理对象，都是一样的。

### session Bean作用域

- 配置
  - XML - <bean class="" scope="session">
  - Java注解-@SessionScope或@Scope(WebApplicationContext.SCOPE_SESSION)
- 实现
  - API-SessionScope

> spring注入的对象始终都是cglib对象，但是根据cookie执行绑定，保证每次获取到的对象都是与session进行绑定的。

### application Bean作用域

- 配置
  - XML - <bean class="" scope="application">
  - Java注解-@ApplicationScope或@Scope(WebApplicationContext.SCOPE_APPLICATION)
- 实现
  - API-ApplicationScope