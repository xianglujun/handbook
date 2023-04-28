# mybatis组件

1. `SqlSessionFactoryBuilder`
该组件用于构建`SqlSessionFactory`对象

2. `SqlSessionFactory`
`SqlSession`创建对象, 其中包含了两个实现类`DefaultSqlSessionFactory`和`SqlSessionManager`

3. `SqlSession`
可以发送SQL 并获取执行结果, 也可以获取Mapper接口

4. `SQL Mapper`
由java接口和XML构成, 形成映射关系。

## SqlSessionFactory的创建方式
1. 通过XML配置的方式创建SqlSessionFactory
2. 通过代码的方式创建SqlSessionFactory

对于代码而言，要尽量避免通过代码的方式创建, 主要是为了便于维护, 以及后期对相关配置的修改。


## SqlSession的作用
1. 通过命名空间以及方法名称定为需要执行的SQL语句, 发送给数据执行SQL并获取返回结果。
2. 在SqlSession中可以通过update, insert, delete, select 的方式, 带上XML中配置好的SQL的id信息, 执行SQL并获取返回结果; 同时本身也会支持事务, 通过`commit`或者`rollback`来操作事务。

## SQL Mapper映射器
映射器是java接口和XML文件的映射关系共同组成的,
1. 定义参数类型
2. 描述缓存
3. 描述SQL语句
4. 定义查询结果与POJO的映射关系
