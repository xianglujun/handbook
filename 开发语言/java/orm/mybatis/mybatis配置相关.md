# mybatis配置相关
该文件主要学习关于mybatis配置相关参数, 以及一些相关参数的说明信息

## xml配置文件的整体结构
```xml
<? xml version="1.0" encoding="UTF-8"?>
<configuration> <!--配置-->
  <properties /> <!--属性-->
  <settings/> <!--设置-->
  <typeAliases /><!--类型别名-->
  <typeHandler/><!--类型处理器-->
  <objectFactory/><!--对象工厂-->
  <plugins/><!--查件-->
  <environments><!--环境配置-->
    <environment> <!--环境变量-->
      <transactionManager/><!--事务管理群-->
      <datasource/> <!--数据源-->
    </environment>
  </environments>
  <databaseIdProvider/><!--数据库厂商标志-->
  <mappers/> <!--映射器-->
</configuration>
```

## properties元素
properties元素中定义的变量，主要用于在下文中直接使用, 因此定义properties有三种方式
1. property定义方式
2. properties配置文件
3. 编程的方式

### property定义方式
```xml
<properties>
  <property name="driver" value="com.mysql.jdbc.Driver" />
  <property name="url" value="jdbc:mysql://localhost:3306/mybatis" />
  <property name="username" value="root" />
  <property name="password" value="gxm123" />
</properties>
<datasource type="POOLED">
  <property name="driver" value="${driver}" />
  <property name="url" value="${url}" />
  <property name="username" value="${usename}" />
  <property name="password" value="${password}" />
</datasource>
```

### properties配置文件方式
```properties
driver=com.mysql.jdbc.Driver
url=jdbc:mysql://localhost:3306/mybatis
username=root
password=gxm123
```

使用:
```xml
<properties resource="jdbc.properties" />
```

### 代码方式实现
代码方式实现，主要是在构建`SqlSessionFactory`的时候, 就需要将`properties`传入, 才能够正常时会用。
```java
InputStream is = Class.getResourceAsStream("mybatis-config.xml");
Properties prop = new Properties();
prop.load(Class.getResourceAsStream("jdbc.properties"));
SqlSessionFactory sqlSessionFactory = new SqlSessionFactoryBuilder().build(is, prop);
```

### 加载优先级
1. 优先加载在`<properties/>`加点中配置的属性
2. 根据`<properties/>`中的`resource`加载配置文件, 或者根据`url`加载配置文件。并覆盖已经读取的同名的配置属性。
3. 读取作为方法参数传递的属性, 并覆盖同名的配置属性。

## 设置
后续更新...

## 别名
1. 在mybatis中别名分为系统级别的别名和自定义别名
2. 在mybatis中别名的定义不区分大小写
3. mybatis的别名是在mybatis启动的时候就别解析，并保存在Configuration中

### 系统别名定义
系统别名定义主要是mybatis自定义了很多的别名以供我们使用, 主要集中在`TypeAliasRegistry`

|别名|映射类型|是否支持数组|
|:----|:-----|:----------:|
|_byte   |byte   | Y  |
|_short   |short   |Y   |
|_long   |long   |Y   |
|_int   | int  | Y  |
|_integer   |  int |Y   |
|_double   |double   |Y   |
|_float   | float  | Y   |
|_boolean   |boolean   |Y   |
|string   |String   |Y   |
|byte   |Byte   | Y  |
|long   |Long   | Y  |
|short   |Short   |Y   |
|int   |Integer   |Y   |
|double   |Double   |Y   |
|float   |Float   |Y   |
|boolean   |Boolean   | Y  |
|date   |Date   | Y  |
|decimal   |BigDecimal   |Y   |
|bigdecimal   |BigDecimal   |Y   |
|object   |Object   |Y   |
|map   |Map   |N   |
|hashmap   |HashMap   |N   |
|list   |List   | N  |
|arraylist   |ArrayList   | N  |
|collection   |Collection   |N   |
|iterator   |Iterator   | N  |
|ResultSet   |ResultSet   |N   |

### 自定义别名
自定义别名是为了弥补系统别名不能够满足业务需求的时候，主要有三种方式进行配置
1. 通过在`mybatis-config`配置文件中, 新增`<typeAlias/>`的配置信息，以简短的名称代替类的全限定名称
2. 扫描的方式, 在`mybatis-config`配置文件中, 在`<typeAliases/>`节点中加入`<package/>`节点，再配合`@Alias`注解使用
3. 扫描方式, 如果扫描的包下面没有使用`@Alias`注解, 这个时候将会使用类名, 并将类名的首字母小写。


## typeHandler类型处理器
mybatis在预处理(PreparedStatement)设置一个参数时, 或者从(ResultSet)中取出一个值的时候, 需要用到typeHandler进行处理

1. 系统级别定义
2. 自定义

typeHandler的常用类型为`Java类型`以及`JDBC类型`, typeHandler的作用就是将Java类型转换为Jdbc类型或者从数据库读出结果时将JDBC类型转换为Java类型。

### 系统定义的typeHandler类型
mybatis 定义的typeHandler，可以通过`TypeHandlerRegistry`进行查看.

|类型处理器|Java类型|JDBC类型|
|:--------|:-------|:-------|
|BooleanTypeHandler   |Boolean, boolean   | 数据库兼容的BOOLEAN   |
|ByteTypeHandler   | Byte, byte  | 数据库兼容的NUMERIC或者BYTE类型   |
|ShortTypeHandler   |Short,short   | 数据库兼容的NUMERIC或者SHORT INTEGER   |
|IntegerHandler   |Integer,int   | 数据库兼容的NUMERIC或者INTEGER  |
|LongTypeHandler   |Long, long   | 数据库兼容的NUMERIC或者LONG INTEGER   |
|FloatTypeHandler   |Float,float   | 数据库兼容的NUMERIC或者FLOAT   |
|DoubleTypeHandler   |Double,double   | 数据库兼容的NUMERIC或者DOUBLE   |
|BigDecimalTypeHandler   |BigDecimal   | 数据库兼容的NUMERIC或者DECIMAL  |
|StringTypeHandler   |String   | CHAR,VARCHAR  |
|ClobTypeHandler   |String   |CLOB, LONGVARCHAR   |
|NStringTypeHandler   |String   |NVARCHAR,NCHAR   |
|NClobTypeHandler   |String   |NCLOB   |
|ByteArrayTypeHandler   |byte[]   | 数据库兼容的字节流类型   |
|BlobTypeHandler   |byte[]   | BLOB, LONGVARBINARY  |
|DateTypeHandler   |Date   | TIMESTAMP  |
|DateOnlyTypeHandler   |Date   | DATE  |
|TimeOnlyTypeHandler   |Date   | TIME  |
|SqlTimestampTypeHandler   |Timestamp   |TIMESTAMP   |
|SqlDateTypeHandler   |java.sql.Date   |DATE   |
|SqlTimeTypeHandler   |java.sql.Time   |TIME   |
|ObjectTypeHandler   | Any  |OTHER或者未指定   |
|EnumTypeHandler   |Enummeration Type   | VARCHAR 或者任何兼容的字符串类型, 存储枚举的值   |
|EnumOrdinalTypeHandler   | Enummeration Type  | 任何兼容NUMERIC或者DOUBLE类型, 存储枚举值的索引  |

### 自定义typeHandler
一般情况下, 系统的typeHandler基本已经可以满足需求, 同时我们也可以自定义typeHandler来实现不同的需求。

实现方式:
1. 实现`TypeHandler`接口或者继承`BaseTypeHandler`
2. 通过`@MappedTypes`以及`@MappedJdbcTypes`用来实现JAVA类型以及JDBC类型映射关系
3. 在`Mapper`的配置文件中, 指定使用自定义`typeHandler`

## objectFactory
当Mybatis返回一个结果的时候，都会使用ObjectHandler来构建POJO对象。

## 插件
后面补充说明....

## environments 配置信息
```xml
<environments default="development">
  <environment id="development">
    <!--采用JDBC事务管理-->
    <transactionManager type="JDBC" />
    <!--配置数据库连接信息-->
    <datasource type="POOLED">
      <property name="driver" value="com.mysql.jdbc.Driver" />
      <property name="url" value="jdbc:mysql://localhost:3306/mybatis" />
      <property name="username" value="root" />
      <property name="password" value="password" />
    </datasource>
  </environment>
</environments>
```
1. `<environments/>`的default属性，表明了在缺省的情况下，默认使用哪一个数据源
2. `<environment/>` 是配置一个数据源的开始,id 设置了这个数据源的标志。
3. `<transactionManager/>` 设置了事务管理器, 包含了三个类型:
  - JDBC, 采用JDBC方式管理事务，在独立编码中常常用到
  - MANAGED, 采用容器的方式管理事务, 在JNDI模式中常常用到
  - 自定义, 由使用者自定义事务的管理方式, 特殊场景使用
  - property节点，主要用来设置属性, 比方说`autoCommit`为false
4. `<datasource/>`标签, 用来设置数据源信息。其中`type`属性提供我们链接数据库的方式,mybatis提供了一下的几种方式：
  - UNPOOLED, 非链接池方式(UnpooledDataSource)
  - POOLED, 数据库连接池(PooledDataSource)
  - JNDI, JNDI数据源(JNDIDataSource)
  - 自定义数据源

### 数据库事务
在mybatis中, 事务全部都是通过`SqlSession`进行控制，通过`SqlSession`进行事务的提交(commit)或者回滚(rollback)

### 数据源
mybatis内部提供了三种创建数据源的方式,
1. UNPOOLED, 非链接池, 使用mybatis的`org.apache.ibatis.datasource.unpooled.UnpooledDataSource`
2. POOLED, 连接池方式创建, 使用mybatis的`org.apache.ibatis.datasource.pooled.PooledDataSource`
3. JNDI, 使用JNDI连接池方式, 使用mybatis的`org.apache.ibatis.datasource.jndi.JndiDataSourceFactory`
4. 自定义, 可以通过制定`type`为自定你的DataSource来完成自定义的数据源定义。

## databaseIdProvider


## mapper映射器
mapper映射器主要用来定意思SQL语句以及对应Mapper接口的对应关系, 可以通过以下四种方式指定:
1. `<mapper resource='../../Mapper.xml'/>`
2. `<package name='com.learn.mybatis.mapper'/>`
3. `<mapper class='com.learn.mybatis.mapper.RoleMapper'/>`
4. `<mapper url=''/>`
