# mybatis基础用法

mybatis在日常开发中是很常用的功能，mybatis整体在使用上属于半自动的工具，我们可以通过自定义sql的方式满足日常开发需要，同时自定义sql也让我们对sql优化有了更好的把控。今天这篇文章主要记录mybatis的基础使用，为以后对mybatis的原理实现做一个基础铺垫，便于由浅入深。

## mybatis-config.xml

xml主要作为mybatis所有配置文件信息，其中包含了很多的配置信息，包括了数据库连接、自定义sql、以及环境变量等信息。具体的配置信息可以参考官方网站。[MyBatis中文网](https://mybatis.net.cn/configuration.html)

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>
<!--    变量配置-->
    <properties>
        <property name="driver" value="com.mysql.cj.jdbc.Driver"/>
        <property name="url" value="jdbc:mysql://192.168.3.37:3306/learn"/>
        <property name="username" value="root"/>
        <property name="password" value="mysql"/>
    </properties>
    <environments default="development">
        <environment id="development">
            <transactionManager type="JDBC"/>
            <!--            数据库配置-->
            <dataSource type="POOLED">
                <property name="driver" value="${driver}"/>
                <property name="url" value="${url}"/>
                <property name="username" value="${username}"/>
                <property name="password" value="${password}"/>
            </dataSource>
        </environment>
    </environments>
    <mappers>
        <!--        mapper配置信息-->
        <mapper resource="com/mybatis/mapper/UserMapper.xml"/>
    </mappers>
</configuration>
```

## SqlSessionFactory

在配置文件已经配置完成的时候，此时我们需要根据xml创建`SqlSessionFactory`对象，该对象使用工厂模式，主要用于创建`SqlSession`对象

```java
/**
 * 该类用于构建{@link org.apache.ibatis.session.SqlSessionFactory}对象
 */
public class XmlSqlSessionFactoryBuilder {

    /**
     * 获取SqlSessionFactory对象
     *
     * @return SqlSessionFactory对象
     */
    public static SqlSessionFactory getSqlSessionFactory() {
        InputStream configIs = XmlSqlSessionFactoryBuilder.class.getResourceAsStream("/mybatis-config.xml");
        return new SqlSessionFactoryBuilder().build(configIs);
    }
}
```

## UserMapper.xml

因为我们在**mybatis-config.xml**配置文件中配置了mapper的路径，此时我们需要在对应的路径下创建**UserMapper.xml**文件，用于后面对mapper的使用。具体配置如下：

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
        PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.mybatis.mapper.UserMapper">

    <resultMap id="user" type="com.mybatis.entity.User">
        <id property="id" column="id" javaType="long"/>
        <result property="userName" column="user_name" javaType="String"/>
        <result property="email" column="email" javaType="String"/>
        <result property="createTime" column="create_time" jdbcType="TIMESTAMP"/>
        <result property="updateTime" column="update_time" jdbcType="TIMESTAMP"/>
    </resultMap>

    <insert id="add" useGeneratedKeys="true" keyColumn="id" keyProperty="id">
        insert into user(user_name, email) value (#{userName}, #{email})
    </insert>
    <select id="get" resultMap="user">
        select *
        from user
        where id = #{userId}
    </select>
</mapper>
```

通过xml我们可以看出，在mapper配置文件中主要包含了基本操作，以及自定义sql, 在该配置文件中主要包含常用的节点：

- `insert`: 插入数据

- `update`: 更新数据

- `delete`: 删除数据

- `select`: 查询数据

- `sql`: 定义sql片段

- `resultMap`: 结果集映射

- 条件判断：
  
  - `if `: 条件判断
  
  - `foreach`: 集合遍历

- Sql拼接
  
  - `trim`: 去除指定字符
  
  - `where`: where语句

> 其他一些语句的使用，可以查看官方网站

## UserMapper

在mybatis中，mapper的类都是接口，因此需要定义UserMapper的接口，需要与UserMapper.xml中 namespace 定义限定名保持一致，因此定义对应接口类型:

```java
package com.mybatis.mapper;

import com.mybatis.entity.User;

public interface UserMapper {

    void add(User user);

    User get(Long userId);
}
```

## 使用UserMapper

在上面的配置完成后，我们基本上就可以使用`UserMapper`完成对数据库的操作了，`UserMapper`对象的创建，主要是通过`SqlSession`完成，因此查看具体使用代码：

```java
package com.mybatis.service;

import com.mybatis.entity.User;
import com.mybatis.factory.XmlSqlSessionFactoryBuilder;
import com.mybatis.mapper.UserMapper;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;

@Slf4j
public class UserService {

    private SqlSessionFactory sqlSessionFactory;

    public UserService() {
        this.sqlSessionFactory = XmlSqlSessionFactoryBuilder.getSqlSessionFactory();
    }

    public void add(User user) {
        if (user == null) {
            return;
        }

        try (SqlSession sqlSession = sqlSessionFactory.openSession();) {
            UserMapper userMapper = sqlSession.getMapper(UserMapper.class);
            userMapper.add(user);
            sqlSession.commit();
        } catch (Exception e) {
            log.error(e.getMessage(), e);
        }
    }

    public User get(Long userId) {
        if (userId == null) {
            return null;
        }

        try (SqlSession sqlSession = sqlSessionFactory.openSession()) {
            UserMapper userMapper = sqlSession.getMapper(UserMapper.class);
            return userMapper.get(userId);
        } catch (Exception e) {
            log.error(e.getMessage(), e);
        }

        return null;
    }

}
```

`UserMapper`的创建，主要是通过`SqlSession.getMapper`方法实现，通过上面的实现我们就可以通过mybatis实现对数据库的操作。

## 客户端实现

我们写一个简单的客户端，查看是否操作数据库成功。

```java
package com.mybatis.client;

import com.mybatis.entity.User;
import com.mybatis.service.UserService;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class UserClient {

    public static void main(String[] args) {
        UserService userService = new UserService();

        User user = new User();
        user.setUserName("xx");
        user.setEmail("xianglj1991@163.com");
        userService.add(user);

        Long userId = user.getId();
        log.info("获取到用户编号: {}", userId);

        User qu = userService.get(userId);
        log.info("获取到用户信息: {}", qu);
    }
}
```

### 输出结果

```log
2022-10-03 17:46:56.996 [main] INFO  com.mybatis.client.UserClient - 获取到用户编号: 17
2022-10-03 17:46:57.043 [main] INFO  com.mybatis.client.UserClient - 获取到用户信息: User(id=17, userName=xx, email=xianglj1991@163.com, createTime=Mon Oct 03 17:46:58 GMT+08:00 2022, updateTime=Mon Oct 03 17:46:58 GMT+08:00 2022)
```

以上就是mybatis的简单demo实现，希望可以帮助到你!
