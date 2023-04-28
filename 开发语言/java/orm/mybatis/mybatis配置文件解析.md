# mybatis XML配置文件解析
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-config.dtd" >
<configuration>
  <!--定义别名-->
  <typeAliases>
    <typeAlias alias="role" type="com.learn.chapter2.po.Role" />
  </typeAliases>
  <!--定义数据库信息, 默认使用development数据库构建环境-->
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
  <!--定义映射器-->
  <mappers>
    <mapper resource="com/learn/mybatis/Chapter2.xml" />
  </mappers>
</configuration>
```

## 定义别名
在以上的配置中, 定义了一个别名`role`, 它代表了`com.learn.chapter2.po.Role`这个类, 这样就可以在mybatis的上下文中引用这个别名

## 配置环境类容
我们配置了环境内容，默认使用了id为development的环境配置, 包含了以下两项内容:
1. 采用`JDBC`事务管理模式
2. 数据库的链接信息
3. 配置映射器

##
