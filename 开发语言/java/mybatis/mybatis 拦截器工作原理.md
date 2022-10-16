# mybatis拦截器工作原理

在 [mybatis mapper运行原理](./mybatis mapper运行原理.md) 和[mybatis Configuration初始化源码分析](./mybatis Configuration初始化源码分析.md)中，我们学习了在mybatis初始化的过程中以及创建mapper的时候做了些必要的事情，其中作为扩展点主要在于Interceptor拦截器的实现，通过拦截器我们可以对mybatis查件操作扩扩展处理，比如可以通过拦截器实现分页查询信息, 以及其他数据权限相关的配置。今天这篇文章主要介绍拦截器的一些用法，以及拦截器的使用。

## mybatis如何使用拦截器

因为在前面的章节中介绍了拦截器的一些初始化流程，因此这里只做一些代码片段的介绍。

### XmlConfigBuilder

```java
private void pluginElement(XNode parent) throws Exception {
    if (parent != null) {
      for (XNode child : parent.getChildren()) {
        String interceptor = child.getStringAttribute("interceptor");
        Properties properties = child.getChildrenAsProperties();
        Interceptor interceptorInstance = (Interceptor) resolveClass(interceptor).getDeclaredConstructor().newInstance();
        interceptorInstance.setProperties(properties);
        configuration.addInterceptor(interceptorInstance);
      }
    }
  }
```

这个类主要从配置文件中获取拦截器，并将拦截器的对象放到Configuration中

### Configuraion

我们知道Mybatis所有的配置信息都是放置在Configuration中的，因此很多对象的创建也是放在Configuration中实现创建，例如今天我们要介绍的与拦截器有关的四大对象：

`Executor `-> `ParameterHandler `-> `ResultHandler `-> `StatementHandler`

```java
public ParameterHandler newParameterHandler(MappedStatement mappedStatement, Object parameterObject, BoundSql boundSql) {
    ParameterHandler parameterHandler = mappedStatement.getLang().createParameterHandler(mappedStatement, parameterObject, boundSql);
    parameterHandler = (ParameterHandler) interceptorChain.pluginAll(parameterHandler);
    return parameterHandler;
  }

  public ResultSetHandler newResultSetHandler(Executor executor, MappedStatement mappedStatement, RowBounds rowBounds, ParameterHandler parameterHandler,
      ResultHandler resultHandler, BoundSql boundSql) {
    ResultSetHandler resultSetHandler = new DefaultResultSetHandler(executor, mappedStatement, parameterHandler, resultHandler, boundSql, rowBounds);
    resultSetHandler = (ResultSetHandler) interceptorChain.pluginAll(resultSetHandler);
    return resultSetHandler;
  }

  public StatementHandler newStatementHandler(Executor executor, MappedStatement mappedStatement, Object parameterObject, RowBounds rowBounds, ResultHandler resultHandler, BoundSql boundSql) {
    StatementHandler statementHandler = new RoutingStatementHandler(executor, mappedStatement, parameterObject, rowBounds, resultHandler, boundSql);
    statementHandler = (StatementHandler) interceptorChain.pluginAll(statementHandler);
    return statementHandler;
  }
```

```java
public Executor newExecutor(Transaction transaction, ExecutorType executorType) {
    ...
    executor = (Executor) interceptorChain.pluginAll(executor);
    return executor;
  }
```

从上面可以得出，在对Interceptor的使用都是在创建对象时，通过代理的方式与拦截器结合使用的。因此这里可以得出，其实拦截的对象就只有以上四个对象。

### InterceptorChain

这个类就很好理解了，主要是调用链模式，保存所有拦截器列表，并创建代理对象，以便于对执行方法的拦截。

```java
public Object pluginAll(Object target) {
    for (Interceptor interceptor : interceptors) {
      target = interceptor.plugin(target);
    }
    return target;
  }
```

### Plugin

这个对象就是具体代理对象执行的方法，具体的拦截实现也是在该类中实现的，我们查看`invoke`方法

```java
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    try {
      // 获取当前声明对象的所有方法列表
      Set<Method> methods = signatureMap.get(method.getDeclaringClass());
      // 如果声明对象包含了执行的方法，则执行拦截器
      if (methods != null && methods.contains(method)) {
        return interceptor.intercept(new Invocation(target, method, args));
      }
      return method.invoke(target, args);
    } catch (Exception e) {
      throw ExceptionUtil.unwrapThrowable(e);
    }
  }
```

以上的逻辑还是很简单的，因此就介绍到这里。接下来我们具体看下该怎么样使用拦截器.

## 拦截器基本用法

从官网一些介绍中可以看出，拦截器主要是为开发者提供了一些额外的操作，可以让我们管理事务，操作SQL等。在拦截器中主要包含了四种类型的拦截：

- Executor:
  
  - update - 更新操作
  
  - query - 查询操作
  
  -  flushStatements - flush操作
  
  - commit - 提交事务
  
  - rollback - 回滚事务
  
  -  getTransaction - 获取事务管理对象
  
  - close - 关闭
  
  -  isClosed - 链接是否已关闭

- ParameterHandler
  
  - getParameterObject - 获取参数对象
  
  - setParameters - 设置参数

- ResultSetHandler
  
  - handleResultSets - 处理结果集
  
  - handleOutputParameters - 处理输出参数

- StatementHandler
  
  - prepare - 预编译
  
  - parameterize - 参数化设置
  
  - batch - 批量操作
  
  - update - 更新
  
  - query - 查询

因此，以上操作范围最广的其实Executor的实现，是能够实现全链路的管理，但是也并不是所有的场景都能够实现。一下我们就以分页拦截实现为例，讲解逻辑的实现。

## 分页拦截DEMO

首先我们定义一个公共的对象, 用于存储分页信息，具体如下：

### Page

```java
package com.mybatis.entity;

import lombok.Data;

import java.util.List;
import java.util.Objects;

@Data
public class Page<T> {

    private Integer current;
    private Integer pageSize;
    private Integer startIndex;
    private Integer endIndex;

    private List<T> records;

    private Integer total;

    public Integer getStartIndex() {
        current = Objects.isNull(current) || current <= 0 ? 1 : current;
        pageSize = Objects.isNull(pageSize) || pageSize <= 0 ? 20 : pageSize;
        return (current - 1) * pageSize;
    }

    public Integer getEndIndex() {
        return getStartIndex() + pageSize;
    }
}

```

这个page对象主要存储分页信息，以及按照SQL查询的信息总量, 和查询结果信息。这个类定义还是很简单，这里就不做过多介绍。

### PageInterceptor

分页拦截器的实现主要是需要改写sql定义，并且新增SQL的统计总数的操作。因此这里就需要有一下步骤：

1. 需要能够拿到Sql语句，并且该语句并没有被预编译过

2. 需要改写SQL, 获取统计结果总数

3. 需要改写SQL， 加上分页信息。这里只是以Mysql为例，如果需要需要兼容其他数据库，可以根据databaseId来判断

4. 封装Page操作

通过在上面基本拦截概念可以知道，我们只能够拦截四个对象，这里因为要获取编译前的SQL信息，这时我们可以拦截`StatementHandler`对象，达到我们想要的效果.

```java
package com.mybatis.interceptor;

import com.mybatis.entity.Page;
import org.apache.ibatis.executor.statement.StatementHandler;
import org.apache.ibatis.mapping.BoundSql;
import org.apache.ibatis.mapping.MappedStatement;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.plugin.Intercepts;
import org.apache.ibatis.plugin.Invocation;
import org.apache.ibatis.plugin.Signature;
import org.apache.ibatis.reflection.DefaultReflectorFactory;
import org.apache.ibatis.reflection.MetaObject;
import org.apache.ibatis.reflection.SystemMetaObject;

import java.sql.Connection;
import java.util.Map;
import java.util.Objects;
import java.util.Properties;

@Intercepts(
        @Signature(type = StatementHandler.class,
                method = "prepare", args = {Connection.class, Integer.class})
)
public class PageInterceptor implements Interceptor {
    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        // 从invocation中获取代理对象, 这里为StatementHandler
        StatementHandler statementHandler = (StatementHandler) invocation.getTarget();
        MetaObject metaObject = MetaObject
                .forObject(statementHandler,
                        SystemMetaObject.DEFAULT_OBJECT_FACTORY,
                        SystemMetaObject.DEFAULT_OBJECT_WRAPPER_FACTORY,
                        new DefaultReflectorFactory());

        // 获取StatementHandler对应的实例对象，该实例对象因为默认使用的RoutingStatementHandler实现
        // 因此这里取具体的属性值的时候，需要从对应的被代理对象中获取, 即delegate属性
        // mappedStatement对象中就包含了对应的sql原始信息
        MappedStatement mappedStatement = (MappedStatement) metaObject.getValue("delegate.mappedStatement");

        // 获取方法调用参数列表, 并判断是否包含了page对象参数
        BoundSql boundSql = statementHandler.getBoundSql();
        // 获取参数列表
        Object paramObject = boundSql.getParameterObject();
        Page<?> page = null;
        // 如果一个参数，需要判断是否page对象
        if (paramObject instanceof Page) {
            page = (Page<?>) paramObject;
        } else if (paramObject instanceof Map) {
            // 当存在多个参数时
            Map<String, Object> params = (Map<String, Object>) boundSql.getParameterObject();
            if (Objects.nonNull(params)) {
                for (Map.Entry<String, Object> entry : params.entrySet()) {
                    Object val = entry.getValue();
                    if (val instanceof Page) {
                        page = (Page<?>) val;
                        break;
                    }
                }
            }
        }

        // 判断page参数对象是否为空
        if (Objects.nonNull(page)) {
            // 此时就表示了需要分页, 这个时候就需要判断结果对象是否为page
            String sql = boundSql.getSql();
            sql = sql + " limit " + page.getStartIndex() + "," + page.getPageSize();
            metaObject.setValue("delegate.boundSql.sql", sql);
        }

        return invocation.proceed();
    }

    @Override
    public void setProperties(Properties properties) {
        Interceptor.super.setProperties(properties);
    }
}

```

这种方式有个明显的缺点，就是我们只能处理sql, 但是不能拿到sql执行的结果，这个时候我们没办法将`Page`中的数据与结果进行组装，只能通过其他的途径来实现。大家可以参考第三方的分页实现逻辑，都是从`Executor`的层面进行拦截，这样对于mybatis理解会有更高的一个要求。后续会做一遍关于`Executor`拦截的文章讲解。
