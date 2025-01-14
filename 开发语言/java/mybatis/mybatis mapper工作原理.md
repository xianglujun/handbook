# mybatis mapper生成原理

在前面的章节中我们探讨了configuration类型的加载过程，过程执行还是很清晰的，今天这篇文章我们主要从源码的角度探讨mapper的工作原理，更深入一次的了解mybatis框架，也为后面我们深入了解在mybatis上扩展的框架打下基础。

## SqlSessionFactory

这里又再一次回到了这个类上面，在正式使用Mybatis时，这个类也是非常重要的。在前面初始化的文章中，该类中主要包含了`Configuration`类的依赖，因此我们再次回顾一下该类是如何使用，代码片段如下：

```java
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
```

从上面的使用中可以看出，在`SqlSessionFactory`使用的时候，主要使用该类创建`SqlSession`类，而`SqlSession`类维持了操作数据库，事务管理等事项，因此我们看看`openSession()`做了哪些事情。

### openSession()

该方法主要是获取SqlSession对象，我们具体查看一下如何创建SqlSession对象：

```java
private SqlSession openSessionFromDataSource(ExecutorType execType, TransactionIsolationLevel level, boolean autoCommit) {
    Transaction tx = null;
    try {
      // 获取环境信息，环境信息里面就包含了事务工厂以及连接池对象
      final Environment environment = configuration.getEnvironment();
      // 从环境中获取事务工厂类
      final TransactionFactory transactionFactory = getTransactionFactoryFromEnvironment(environment);
      // 创建事务对象
      tx = transactionFactory.newTransaction(environment.getDataSource(), level, autoCommit);
      // 创建执行器
      final Executor executor = configuration.newExecutor(tx, execType);
      // 创建SqlSession对象
      return new DefaultSqlSession(configuration, executor, autoCommit);
    } catch (Exception e) {
      closeTransaction(tx); // may have fetched a connection so lets call close()
      throw ExceptionFactory.wrapException("Error opening session.  Cause: " + e, e);
    } finally {
      ErrorContext.instance().reset();
    }
  }
```

源码的代码是比较简单，主要包含了一下步骤：

- 创建事务工厂(`TransactionFactory`)：事务工厂的主要作用在于创建事务管理对象`Trasaction`。在Mybatis中，`TrasactionFactory`默认有两种类型：
  
  - `JDBC`: 该类型对应的`JdbcTransactionFactory`，该类型的事务对应着`JdbcTrasaction`事务管理对象
  
  - `MANAGED`: 该类型对应的`ManagedTransactionFactory`，同时创建的事务管理对象为`ManagedTrasaction`

- 创建`Executor`: `Executor`对象主要负责操作数据库的具体实现，包含执行查询、缓存管理、事务提交、回滚等。`Excecutor`类型也分为很多类，可以根据需要使用。
  
  - `BATCH`: 对应着`BatchExecutor`
  
  - `REUSE`: 对应着`ReuseExecutor`
  
  - `SIMPLE`: 对应着`SimpleExecutor`, 该类型也是mybatis中的默认实现
  
  - 另外一种类型为`CacheExecutor`, 该类型主要为在开启缓存的时候使用

- 创建`SqlSession`, 在创建时默认使用`DefaultSqlSession`来创建，其中关联了`Configuraion`以及`Executor`对象。因此我理解为`SqlSession`是更抽象，真正的操作数据库其实都是通过`Executor`来实现。

## TransactionFactory

事务工厂主要目的在于创建`Trasaction`对象，不同类型创建其实都大同小异，只是在具体的事务管理的时候会存在差别。我们这里主要看`JdbcTrasactionFactory`对象的代码.

```java
public class JdbcTransactionFactory implements TransactionFactory {

  @Override
  public Transaction newTransaction(Connection conn) {
    return new JdbcTransaction(conn);
  }

  @Override
  public Transaction newTransaction(DataSource ds, TransactionIsolationLevel level, boolean autoCommit) {
    return new JdbcTransaction(ds, level, autoCommit);
  }
}
```

这个工厂类提供了非常简单的实现，都是直接创建`JdbcTrasaction`对象即可。

## Executor

Exectur的创建并不是由工厂类完成的，而是由`Configuration#newExecutor`实现，这个类从类的定义看主要定义了操作数据库和事务管理的方法，因此他和事务管理的trasaction本身就是一种组合关系。

```java
public interface Executor {

  ResultHandler NO_RESULT_HANDLER = null;

  int update(MappedStatement ms, Object parameter) throws SQLException;

  <E> List<E> query(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler, CacheKey cacheKey, BoundSql boundSql) throws SQLException;

  <E> List<E> query(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler) throws SQLException;

  <E> Cursor<E> queryCursor(MappedStatement ms, Object parameter, RowBounds rowBounds) throws SQLException;

  List<BatchResult> flushStatements() throws SQLException;

  void commit(boolean required) throws SQLException;

  void rollback(boolean required) throws SQLException;

  CacheKey createCacheKey(MappedStatement ms, Object parameterObject, RowBounds rowBounds, BoundSql boundSql);

  boolean isCached(MappedStatement ms, CacheKey key);

  void clearLocalCache();

  void deferLoad(MappedStatement ms, MetaObject resultObject, String property, CacheKey key, Class<?> targetType);

  Transaction getTransaction();

  void close(boolean forceRollback);

  boolean isClosed();

  void setExecutorWrapper(Executor executor);

}
```

在`Executor`中大多都是处于基础功能的实现，包括了数据库的查询、缓存管理、事务提交等，但是可以看到的是，在`Executor`中并没有与业务关联的部分，因此`Executor`更多的是对数据库层面的抽象，更多的业务抽象都放在了`SqlSession`中实现。

### newExecutor()

接下来就直接看一下在`Configuration`中如何创建`Executor`对象。

```java
public Executor newExecutor(Transaction transaction, ExecutorType executorType) {
    // 这里确认执行类型，默认为SIMPLE
    executorType = executorType == null ? defaultExecutorType : executorType;
    executorType = executorType == null ? ExecutorType.SIMPLE : executorType;
    Executor executor;
    // 创建BatchExecutor
    if (ExecutorType.BATCH == executorType) {
      executor = new BatchExecutor(this, transaction);
    } else if (ExecutorType.REUSE == executorType) {
      // 创建ReuseExecutor
      executor = new ReuseExecutor(this, transaction);
    } else {
      // 创建SimpleExecutor
      executor = new SimpleExecutor(this, transaction);
    }
    // 判断是否开启缓存，如果开启，则创建CachingExecutor
    if (cacheEnabled) {
      executor = new CachingExecutor(executor);
    }
    // 设置interceptor内容
    executor = (Executor) interceptorChain.pluginAll(executor);
    return executor;
  }
```

创建这里使用了**简单工厂模式**, 根据不同的类型创建不同的Executor即可。不同的是，当使用缓存的时候，使用`CachingExecutor`来做了一层代理，因此这里可以理解为**代理模式**,只不过是静态代理罢了。在创建时，同时也设计到了`Interceptor`的设置，这里是将`Interceptor`与具体的`Executor`进行关联设置，我们具体看下都做了写什么事情。

### pluginAll

该方法主要是为目标方法设置拦截器，该方法调用通过`InterceptorChain`来完成，这是一个**调用链模式**实现的类，来看下该类主要做了什么事情

```java
public Object pluginAll(Object target) {
    for (Interceptor interceptor : interceptors) {
      target = interceptor.plugin(target);
    }
    return target;
  }
```

因为`InterceptorChain`类维护了mybatis中所有的`Interceptor`的列表，因此这`pluginAll`方法中分别调用`Interceptor`的`plugin`方法。

```java
public interface Interceptor {

  Object intercept(Invocation invocation) throws Throwable;

  default Object plugin(Object target) {
    return Plugin.wrap(target, this);
  }

  default void setProperties(Properties properties) {
    // NOP
  }

}
```

从这里看出，plugin方式是在接口中定义的默认方法，包含了具体的默认实现。都是通过`Plugin.wrap()`方法来实现。

### Plugin.wrap()

这里是设置目标对象target与`Inteceptor`关系的地方，我们看下具体怎么样做的关联:

```java
  public static Object wrap(Object target, Interceptor interceptor) {
    // 该行主要是从Intercetor中获取@Intercepts注解中的所有内容，
    // 并返回一个map关系
    Map<Class<?>, Set<Method>> signatureMap = getSignatureMap(interceptor);

    // 目标对象的类型
    Class<?> type = target.getClass();
    // 获取目标对象target的所有实现的接口
    Class<?>[] interfaces = getAllInterfaces(type, signatureMap);
    // 如果包含了接口, 则使用代理的方式进行代理
    if (interfaces.length > 0) {
      // 创建代理对象
      return Proxy.newProxyInstance(
          type.getClassLoader(),
          interfaces,
          new Plugin(target, interceptor, signatureMap));
    }
    return target;
  }
```

对象target与Interceptor之间的关系主要通过JDK自身的动态代理实现的，不过代理的前提是，**target对象一定需要实现接口**，我们知道，在JDK动态代理中，最终的方法的实现都是通过`InvocationHandler`来实现的，在这里最终的实现都是通过`Plugin`对象实现，我们简单看下`Plugin`的处理逻辑。

```java
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    try {
      // 判断是否定义方法
      Set<Method> methods = signatureMap.get(method.getDeclaringClass());
      // 如果有拦截对应的方法，则执行拦截器
      if (methods != null && methods.contains(method)) {
        return interceptor.intercept(new Invocation(target, method, args));
      }
      // 否则就直接执行方法
      return method.invoke(target, args);
    } catch (Exception e) {
      throw ExceptionUtil.unwrapThrowable(e);
    }
  }
```

**这里的定义其实很简单，因为在解析的时候，会通过Interceptor上的`@Intercets`注解来定义拦截的方法，因此这里只需要判断执行的方法是否在拦截范围内即可。**

## 获取Mapper对象

在上面的流程中，我们知道了`SqlSession`对象是如何被创建的，以及各个重要类之间的关系。当我们拿到`SqlSession`时候，就需要创建`Mapper`对象，然后通过`Mapper`对象来实现对数据库的操作。因此我们主要探讨`Mapper`的生成、使用过程。

### getMapper()

通过源码可以得知，mybatis默认使用的是`DefaultSqlSession`类，因此我们看下`getMapper()`方法的代码.

```java
 @Override
  public <T> T getMapper(Class<T> type) {
    return configuration.getMapper(type, this);
  }
```

获取Mapper对象最终是通过`Configuration`类型来实现的，这是因为我们mapper的所有定义都是放在`Configuration`配置类中，需要从`Configuration`中获取mapper完整的定义。

```java
public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
     // 从MapperRegistry中获取
     return mapperRegistry.getMapper(type, sqlSession);
  }
```

### MapperRegistry#getMapper()

在前面源码分析中，我们知道`MapperRegistry`类型存储了`Mapper`配置的所有内容，包括了类型、sql片段、操作sql等。类型主要来自于两个方面：

- 如果是xml配置，则使用`namespace`作为类型加载并作为映射关系的key

- 如果通过类型载入，则使用当前类型

```java
public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
    // 根据类型获取mapper映射的factory工厂类
    final MapperProxyFactory<T> mapperProxyFactory = (MapperProxyFactory<T>) knownMappers.get(type);
    // 如果没有映射，则跑出异常
    if (mapperProxyFactory == null) {
      throw new BindingException("Type " + type + " is not known to the MapperRegistry.");
    }
    try {
      // 创建mapper对象
      return mapperProxyFactory.newInstance(sqlSession);
    } catch (Exception e) {
      throw new BindingException("Error getting mapper instance. Cause: " + e, e);
    }
  }
```

这里获取mapper首先要找到对应的`mapper`配置类，因此从map中获取定义对象`MapperProxyFactory`即可。创建mapper对象也是通过`MapperProxyFactory#newInstance()`方法完成

### MapperProxyFactory#newInstance()

```java
protected T newInstance(MapperProxy<T> mapperProxy) {
    return (T) Proxy.newProxyInstance(mapperInterface.getClassLoader(), new Class[] { mapperInterface }, mapperProxy);
  }

  public T newInstance(SqlSession sqlSession) {
    // 获取mapper代理对象
    final MapperProxy<T> mapperProxy = new MapperProxy<>(sqlSession, mapperInterface, methodCache);
    // 创建mapper
    return newInstance(mapperProxy);
  }
```

从这里我们知道`mapper`本身也是代理对象，这里也是使用的JDK的动态代理实现。

> 因为我们定义mapper的时候，本身就是接口的定义，因此这种场景本身使用JDK动态代理是最简单的

JDK动态代理本身执行方法的时候是需要`InvocationHandler`来执行具体的方法的，这里的实现类是`MapperProxy`实现的，我们看下`MapperProxy`如何处理具体的方法执行的。

### MapperProxy

代理类执行时，会执行到`invoke()`方法，这里我们看下`MapperProxy#invoke`方法执行逻辑:

```java
@Override
  public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    try {
      // 如果是Object方法，直接执行
      if (Object.class.equals(method.getDeclaringClass())) {
        return method.invoke(this, args);
      } else {
        // 执行方法
        return cachedInvoker(method).invoke(proxy, method, args, sqlSession);
      }
    } catch (Throwable t) {
      throw ExceptionUtil.unwrapThrowable(t);
    }
  }

  private MapperMethodInvoker cachedInvoker(Method method) throws Throwable {
    try {
      return MapUtil.computeIfAbsent(methodCache, method, m -> {
        // 如果是接口默认方法
        if (m.isDefault()) {
          try {
            // 不同版本方法的执行逻辑
            if (privateLookupInMethod == null) {
              return new DefaultMethodInvoker(getMethodHandleJava8(method));
            } else {
              return new DefaultMethodInvoker(getMethodHandleJava9(method));
            }
          } catch (IllegalAccessException | InstantiationException | InvocationTargetException
              | NoSuchMethodException e) {
            throw new RuntimeException(e);
          }
        } else {
          // 否则直接执行方法
          return new PlainMethodInvoker(new MapperMethod(mapperInterface, method, sqlSession.getConfiguration()));
        }
      });
    } catch (RuntimeException re) {
      Throwable cause = re.getCause();
      throw cause == null ? re : cause;
    }
  }
```
