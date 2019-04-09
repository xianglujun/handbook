# 原理解析

## mybatis 映射器
映射器包含了三个重要部分:
1. `MappedStatement`: 它保存映射器的一个节点(insert|update|select|delete),包括我们配置的许多SQL, SQL的ID, 缓存信息, resultMap, parameterType, resultType,languageDriver等重要配置
2. `SqlSource`是提供`BoundSql`的地方, 它是`MappedStatement`的一个属性
3. `BoundSql`它是建立SQL和参数的地方。他有三个重要属性: SQL, parameterMappings, parameterObject

## BoundSql
BoundSql会提供三个参数, `parameterObject`, `parameterMappings`,`sql`

- parameterObject代表了参数的本身, 包括`POJO`,`MAP`,`@Param`
  - 传递基本类型参数时(int,float,long等), 会转换为对应的封装类型
  - 如果传递类型为POJO或者MAP, parameterObject就代表了POJO,MAP本身
  - 当传递多个参数时, 如果没有`@Param`注解时，parameterObject则代表了Map<String,Object>对象,按照顺序将参数存入Map中。`{"1":p1,"2":p2,"3":p3}`. 当我们在SQL中引用参数时, 可以使用`#{param1}`或者`#{1}`使用
- `parameterMappings`是一个List,每一个元素都是ParameterMapping对象, 这个对象描绘了我们的参数.(属性,名称, 表达式, javaType,jdbcType,typeHandler等信息)
- `sql`属性就代表了书写的SQL，一般情况下我们不需要修改。除非在插件使用的时候才会考虑修改。

## 
