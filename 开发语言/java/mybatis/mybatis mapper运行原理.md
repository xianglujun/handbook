# mybatis mapper运行原理

在前面的章节中，我们学习了mapper接口代理对象是如何生成的，知道了mapper使用了jdk的动态代理技术生成，这篇文章将探讨mapper是如何运行的，在运行过程中都做了哪些事情。

## MapperProxy

在前面的源码分析中可以知道，这个类是一个`InvocationHandler`的实现，代理对象执行的时候，最终会执行到该类的`invoke()`方法，因此我们直接探讨下该类的方法实现。

### invoke()

```java
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    try {
      if (Object.class.equals(method.getDeclaringClass())) {
        return method.invoke(this, args);
      } else {
        return cachedInvoker(method).invoke(proxy, method, args, sqlSession);
      }
    } catch (Throwable t) {
      throw ExceptionUtil.unwrapThrowable(t);
    }
  }
```

这个方法的实现是比较简单的，可以分为两个部分：

- 判断执行的方法是否为Object的方法，如果是，则直接执行

- 否则执行`cacheInvoker()`方法，该方法返回的是一个MethodInvoker对象，该对象最终实现方法的执行.

### cachedInvoker()

```java
private MapperMethodInvoker cachedInvoker(Method method) throws Throwable {
    try {
      // 返回MapperMethodInvoker对象, 该方法会缓存下来，以防止方法重复调用的时候重复解析
      return MapUtil.computeIfAbsent(methodCache, method, m -> {
        // 这个判断是判断方法是否为默认方法，因为在1.8之后接口能够有默认实现
        // 因此这里做了一个特殊的判断
        if (m.isDefault()) {
          try {
            // 这里主要也是1.8和之后版本的一些差异，在实现上的一些不同
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
          // 如果不止默认方法，则返回PlainMethodInvoker
          return new PlainMethodInvoker(new MapperMethod(mapperInterface, method, sqlSession.getConfiguration()));
        }
      });
    } catch (RuntimeException re) {
      Throwable cause = re.getCause();
      throw cause == null ? re : cause;
    }
  }
```

在以上代码中可以得知，MethodInvoker有两种类型，分别对应不同的方法执行策略：

- 当执行方法是默认的接口方法时，则使用`DefaultMethodInvoker`

- 否则使用`PlainMethodInvoker`实现来执行方法

> 在判断方法为接口default定义方法的时候，做了一个版本的区分，这个是JDK提供的查找类方法的一种实现，主要通过MethodHandles配合Lookup来实现的，在1.9之后发生了一些变化，所以这里在做法上有些差异。

### DefaultMethodInvoker

默认方法执行主要用来处理接口上的默认方法的执行，因此在默认方法执行的时候，其实与数据库操作关系不大，主要还是看具体方法体的实现。

```java
private static class DefaultMethodInvoker implements MapperMethodInvoker {
    private final MethodHandle methodHandle;

    public DefaultMethodInvoker(MethodHandle methodHandle) {
      super();
      this.methodHandle = methodHandle;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args, SqlSession sqlSession) throws Throwable {
      return methodHandle.bindTo(proxy).invokeWithArguments(args);
    }
  }
```

这里其实可以看出，只是调用了MethodHandle执行方法，因此这里就不做过多阐述。

## PlainMethodInvoker

当执行的接口中的方法时，此时该类起到了最终方法执行的承上启下的作用，该类也作为mapper接口方法执行的关键类

```java
private static class PlainMethodInvoker implements MapperMethodInvoker {
    private final MapperMethod mapperMethod;

    public PlainMethodInvoker(MapperMethod mapperMethod) {
      super();
      this.mapperMethod = mapperMethod;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args, SqlSession sqlSession) throws Throwable {
      return mapperMethod.execute(sqlSession, args);
    }
  }
```

MethodInvoker的执行，最终还是通过MapperMethod类来执行，达到预期的效果。

## MapperMethod

该类做了接口方法与xml操作SQL语句的映射关系，同时最终将参数与SQL语句合并的实现，该类也是mapper执行的类型，我们先看该类是如何创建的。

### 构造器

```java
public MapperMethod(Class<?> mapperInterface, Method method, Configuration config) {
    this.command = new SqlCommand(config, mapperInterface, method);
    this.method = new MethodSignature(config, mapperInterface, method);
  }
```

构造器中包含了两个主要类型，分别是SqlCommand一级MethodSignature类型。这两个类型有什么作用呢?

### SqlCommand

```java
public SqlCommand(Configuration configuration, Class<?> mapperInterface, Method method) {
      // 获取执行方法的名称
      final String methodName = method.getName();
      // 获取方法声明类型
      final Class<?> declaringClass = method.getDeclaringClass();
      // 根据声明类型和方法获取方法与sql的映射实体，这个实体对象实在
      // Configuration初始化阶段就已经完成了
      MappedStatement ms = resolveMappedStatement(mapperInterface, methodName, declaringClass,
          configuration);
      // 如果没有包含映射对象
      if (ms == null) {
        // 判断是否包含Flush注解
        if (method.getAnnotation(Flush.class) != null) {
          name = null;
          type = SqlCommandType.FLUSH;
        } else {
          // 抛出异常，没有找到映射实体对象
          throw new BindingException("Invalid bound statement (not found): "
              + mapperInterface.getName() + "." + methodName);
        }
      } else {
        // 映射对象存在，获取id
        name = ms.getId();
        // 获取sql操作类型
        type = ms.getSqlCommandType();
        // 如果sql操作类型无法识别，则抛出异常
        if (type == SqlCommandType.UNKNOWN) {
          throw new BindingException("Unknown execution method for: " + name);
        }
      }
    }
```

这个方法功能主要目的在于：

- 通过执行的方法和声明类型确认方法与SQL的映射对象`MappedStatement`

- 通过`MappedStatement`对象确认SQL的操作类型

#### resolveMappedStatement()

该方法主要是寻找到方法与SQL的映射关系，因为接口可以继承多层次，执行的方法可能会在父接口中，因此这里在解析的时候，需要递归的寻找。

```java
private MappedStatement resolveMappedStatement(Class<?> mapperInterface, String methodName,
        Class<?> declaringClass, Configuration configuration) {
      // 获取statement的唯一id
      String statementId = mapperInterface.getName() + "." + methodName;
      // 判断Configuration中是否包含了Statement映射
      if (configuration.hasStatement(statementId)) {
        // 如果包含，则直接获取
        return configuration.getMappedStatement(statementId);
      } else if (mapperInterface.equals(declaringClass)) {
        // 如果接口对象与方法声明对象是同一个类，就说明该方法已经没有映射,
        // 此时直接返回null即可
        return null;
      }
      // 遍历当前接口的所有继承接口列表
      for (Class<?> superInterface : mapperInterface.getInterfaces()) {
        // 判断当前接口是否为方法声明接口的派生，如果是，则递归解析并获取SQL映射实体
        if (declaringClass.isAssignableFrom(superInterface)) {
          MappedStatement ms = resolveMappedStatement(superInterface, methodName,
              declaringClass, configuration);
          if (ms != null) {
            return ms;
          }
        }
      }
      return null;
    }
```

> 通过以上分析可以得知，在获取MappedStatement对象的时候，**statementId的生成规则为当前接口全限定+".方法名"**
> 
> - 在没有找到MappedStatement时，如果方法有@Flush接口，则按照Flush操作执行
> 
> - 如果没有@Flush接口，这是就会抛出异常
> 
> 在mybatis中每个方法都需要与sql有映射关系，如果没有这层映射关系，此时的错误并不会在初始化时抛出，而是在执行时抛出异常。

### MethodSignature

该类主要记录方法的签名信息，包含了方法的参数，返回值等信息。

```java
public MethodSignature(Configuration configuration, Class<?> mapperInterface, Method method) {
      // 这里是解析泛型化参数，获取返回值的具体类型
      Type resolvedReturnType = TypeParameterResolver.resolveReturnType(method, mapperInterface);
      // 判断类型是否为class对象
      if (resolvedReturnType instanceof Class<?>) {
        this.returnType = (Class<?>) resolvedReturnType;
      } else if (resolvedReturnType instanceof ParameterizedType) {
        // 判断是否参数化类型
        this.returnType = (Class<?>) ((ParameterizedType) resolvedReturnType).getRawType();
      } else {
        // 获取返回类型
        this.returnType = method.getReturnType();
      }
      // 是否不需要返回值
      this.returnsVoid = void.class.equals(this.returnType);
      // 判断返回的类型是否为集合或者数组
      this.returnsMany = configuration.getObjectFactory().isCollection(this.returnType) || this.returnType.isArray();
      // 判断返回的类型是否为指针
      this.returnsCursor = Cursor.class.equals(this.returnType);
      // 判断返回的类型是否为Optional
      this.returnsOptional = Optional.class.equals(this.returnType);
      // 如果返回值为map, 则判断是否包含了MapKey注解，如果包含则返回
      this.mapKey = getMapKey(method);
      // 是否返回值为Map
      this.returnsMap = this.mapKey != null;
      // 判断参数是否为RowBounds, 如果是，则返回index信息
      this.rowBoundsIndex = getUniqueParamIndex(method, RowBounds.class);
      // 判断参数中是否包含ResultHandler, 如果包含怎返回参数所在的位置
      this.resultHandlerIndex = getUniqueParamIndex(method, ResultHandler.class);
      // 参数名称解析器
      this.paramNameResolver = new ParamNameResolver(configuration, method);
    }
```

通过源码可以得知，主要是对方法参数一些特别的类型。例如`RowBounds`、`ResultHandler`一些特殊处理，同时也对`MapKey`注解的解释，这里面比较复杂的是`ParamNameResolver`的实现，这个是对参数名称的解释，主要看下这个类的实现.

### ParamNameResolver

这个类主要是方法参数名称的解析，这里名称主要是在xml配置中能够使用`#{}`表达式获取参数的一个别名，具体源码如下:

```java
public ParamNameResolver(Configuration config, Method method) {
    // 是否使用实际的参数名称，默认值为true
    this.useActualParamName = config.isUseActualParamName();
    // 参数类型列表
    final Class<?>[] paramTypes = method.getParameterTypes();
    // 获取方法参数列表
    final Annotation[][] paramAnnotations = method.getParameterAnnotations();
    final SortedMap<Integer, String> map = new TreeMap<>();
    // 参数的数量
    int paramCount = paramAnnotations.length;
    // get names from @Param annotations
    for (int paramIndex = 0; paramIndex < paramCount; paramIndex++) {
      // 这里判断是否为特殊的参数，主要判断参数类型是否为
      // RowBounds和ResultHandler实现的类，如果是特殊的类，则直接跳过
      if (isSpecialParameter(paramTypes[paramIndex])) {
        // skip special parameters
        continue;
      }
      String name = null;
      // 判断当前参数是否被@Param修饰，如果是，择取@Param的value的值
      // 作为参数名称
      for (Annotation annotation : paramAnnotations[paramIndex]) {
        if (annotation instanceof Param) {
          hasParamAnnotation = true;
          name = ((Param) annotation).value();
          break;
        }
      }
      // 如果没有被@Param修饰
      if (name == null) {
        // @Param was not specified.
        // 如果使用实际的参数名称
        if (useActualParamName) {
          // 获取实际的参数名称
          name = getActualParamName(method, paramIndex);
        }
        // 如果名称还是为空，则获取参数的索引
        if (name == null) {
          // use the parameter index as the name ("0", "1", ...)
          // gcode issue #71
          name = String.valueOf(map.size());
        }
      }
      // 将参数加入到map中
      map.put(paramIndex, name);
    }
    // 将名称封装称为不可修改
    names = Collections.unmodifiableSortedMap(map);
  }
```

## 执行方法execute()

通过前面分析中，可以知道SqlCommand中包含了SqlCommand和MethodSignature的实例化过程，当这两个类实例化完成后，就来到了execute()方法的执行。

```java
public Object execute(SqlSession sqlSession, Object[] args) {
    Object result;        
    // 操作类型    
    switch (command.getType()) {
      case INSERT: {
        // 插入操作
        Object param = method.convertArgsToSqlCommandParam(args);
        result = rowCountResult(sqlSession.insert(command.getName(), param));
        break;
      }
      case UPDATE: {
        // 更新操作
        Object param = method.convertArgsToSqlCommandParam(args);
        result = rowCountResult(sqlSession.update(command.getName(), param));
        break;
      }
      case DELETE: {
        // 删除操作
        Object param = method.convertArgsToSqlCommandParam(args);
        result = rowCountResult(sqlSession.delete(command.getName(), param));
        break;
      }
      case SELECT:
        // 查询操作
        if (method.returnsVoid() && method.hasResultHandler()) {
          // 这里判断方法没有返回值，并且包含了ResultHandler时执行
          executeWithResultHandler(sqlSession, args);
          result = null;
        } else if (method.returnsMany()) {
          // 返回结合或者数组的时候执行
          result = executeForMany(sqlSession, args);
        } else if (method.returnsMap()) {
          // 返回map时候执行
          result = executeForMap(sqlSession, args);
        } else if (method.returnsCursor()) {
          // 返回指针的时候执行
          result = executeForCursor(sqlSession, args);
        } else {
          // 其他情况
          Object param = method.convertArgsToSqlCommandParam(args);
          result = sqlSession.selectOne(command.getName(), param);
          if (method.returnsOptional()
              && (result == null || !method.getReturnType().equals(result.getClass()))) {
            result = Optional.ofNullable(result);
          }
        }
        break;
      case FLUSH:
        // flush操作
        result = sqlSession.flushStatements();
        break;
      default:
        throw new BindingException("Unknown execution method for: " + command.getName());
    }
    if (result == null && method.getReturnType().isPrimitive() && !method.returnsVoid()) {
      throw new BindingException("Mapper method '" + command.getName()
          + " attempted to return null from a method with a primitive return type (" + method.getReturnType() + ").");
    }
    return result;
  }


```

在上面的执行源码中，有比较多相同方法的调用，例如: `convertArgsToSqlCommandParam()`、`rowCountResult()`方法的调用, 这里就优先查看这些公共方法所做的事情，然后再单独看每个操作的个性。

### MethodSignature#convertArgsToSqlCommandParam()

这个方法根据名称可以看出，是将方法参数转换为SQL命令参数信息，该方法在`MethodSignature`中, 我们具体看下是怎么样执行的。

```java
public Object convertArgsToSqlCommandParam(Object[] args) {
      return paramNameResolver.getNamedParams(args);
    }
```

该方法的执行最终是由ParamNameResolver来实现的，具体源码如下：

```java
public Object getNamedParams(Object[] args) {
    // 这里获取参数的数量，这里的参数是去除了特殊的参数类型的, 即
    // RowBounds, ResultHandler
    final int paramCount = names.size();
    // 方法没有入参，直接返回null
    if (args == null || paramCount == 0) {
      return null;
    } else if (!hasParamAnnotation && paramCount == 1) {
      // 这里条件是没有@Param注解，并且参数的长度为1
      Object value = args[names.firstKey()];
      // 这里判断value的值是否为集合，如果是集合的话，则参数列表中需要特殊处理
      // 如果value的类型是collection, 则新增collection的key
      // 如果value的类型是List, 则新增List的key
      // 如果value的值为Array, 则新增array的key
      return wrapToMapIfCollection(value, useActualParamName ? names.get(0) : null);
    } else {
      // 当包含@Param或者有多个参数时
      final Map<String, Object> param = new ParamMap<>();
      int i = 0;
      for (Map.Entry<Integer, String> entry : names.entrySet()) {
        // 设置参数值到map中
        param.put(entry.getValue(), args[entry.getKey()]);
        // add generic param names (param1, param2, ...)
        // 生成通用的参数名称，则是param+索引位置
        // 这里其实要注意，这里的参数中的索引其实是没有算上特殊参数索引的
        // 因此这里回事一个特殊性
        final String genericParamName = GENERIC_NAME_PREFIX + (i + 1);
        // ensure not to overwrite parameter named with @Param
        // 如果没有包含paramName, 则加入到参数map中
        if (!names.containsValue(genericParamName)) {
          param.put(genericParamName, args[entry.getKey()]);
        }
        i++;
      }
      return param;
    }
  }
```

通过上面的源码分析，我们可出一下结论：

- 当参数只有一个并且没有被@Param注解修饰，这是如果参数为集合类型或者数组类型，则可以根据collection、list或者array来获取参数值

- 无论参数是否被@Param注解修饰，都会按照参数索引位置生成`param(index)`名称的参数，但是当参数中包含了RowBounds或者ResultHandler时，这个时候参数索引会发生变化，需要排除这两个特殊参数的索引位。

### rowCountResult()

该函数是对SQL执行结果的处理，主要是匹配返回值问题，具体源码如下：

```java
private Object rowCountResult(int rowCount) {
    // 结果
    final Object result;
    // 方法没有返回值
    if (method.returnsVoid()) {
      result = null;
    } else if (Integer.class.equals(method.getReturnType()) || Integer.TYPE.equals(method.getReturnType())) {
      // 返回值为Integer, 则返回影响行的数量
      result = rowCount;
    } else if (Long.class.equals(method.getReturnType()) || Long.TYPE.equals(method.getReturnType())) {
      // 如果是Long型，返回影响行的数量
      result = (long) rowCount;
    } else if (Boolean.class.equals(method.getReturnType()) || Boolean.TYPE.equals(method.getReturnType())) {
       // 如果是布尔类型，则判断是否影响行数量大于0
       result = rowCount > 0;
    } else {
      // 否则抛出异常
      throw new BindingException("Mapper method '" + command.getName() + "' has an unsupported return type: " + method.getReturnType());
    }
    return result;
  }
```

这个函数通过源码可以知道，这是针对`insert`、`delete`、`update`操作而言，因为这些操作不会返回具体的行数据，而是返回收到影响行的数量，因此都可以通过这种方式处理.

### 更新数据(INSERT/UPDATE/DELETE)

插入操作顾名思义，就是向数据库中插入数据，`insert`操作是通过`SqlSession`来完成的，具体源码如下:

```java
@Override
  public int insert(String statement, Object parameter) {
    return update(statement, parameter);
  }
```

```java
public int update(String statement, Object parameter) {
    try {
      dirty = true;
      // 获取sql映射语句
      MappedStatement ms = configuration.getMappedStatement(statement);
      return executor.update(ms, wrapCollection(parameter));
    } catch (Exception e) {
      throw ExceptionFactory.wrapException("Error updating database.  Cause: " + e, e);
    } finally {
      ErrorContext.instance().reset();
    }
  }
```

插入操作也是通过`update()`方法来完成操作，这里的`statement`其实是传入的是具体的sql操作的`Id`的属性，这个值在`Configuration`中包含了映射关系，因此可以通过id直接从`Configuration`中获取接口，其次真正执行`update`操作的是`Executor`来完成。

> 在前面的源码中得知，Executor如果我们设定了Interceptor是针对Executor拦截的时候，这个时候Executor其实是一个代理类，这个代理类最终会通过Plugin这个类来完成拦截的处理操作，这里就不做介绍，后面介绍拦截器在介绍拦截器的作用。

#### Executor#update()

前面在分析Mapper对象创建的时候谈到了`Executor`的几种类型，大家有兴趣可以去看看之前的文章，这里就以`CachingExecutor`来作为具体。因为这个类相对于其他功能来说可以联通缓存部分简单介绍。

```java
public int update(MappedStatement ms, Object parameterObject) throws SQLException {
    // 判断是否刷新缓存
    flushCacheIfRequired(ms);
    // 调用update方法
    return delegate.update(ms, parameterObject);
  }
```

#### BaseExecutor

因为CachingExecutor是一个代理对象，只负责一级缓存的管理，因此最终还是要最终的BaseExectuor来执行，update方法都是通过父类来进行定义，具体源码如下:

```java
@Override
  public int update(MappedStatement ms, Object parameter) throws SQLException {
    ErrorContext.instance().resource(ms.getResource()).activity("executing an update").object(ms.getId());
    if (closed) {
      throw new ExecutorException("Executor was closed.");
    }
    // 清楚本地缓存
    clearLocalCache();
    // 执行更新
    return doUpdate(ms, parameter);
  }
```

在这段源码中就看到了对于二级缓存的使用，在执行更新操作的时候，都会先清空本地的二级缓存信息，这里的doUpdate()方法是一个抽象方法，需要具体的Executor实现的时候执行，前面我们介绍过，如果没有特别指定类型，默认为`SimpleExecutor`类，因此这里只关心这个类，其他类型作用，大家可以自行查看。

#### SimpleExecutor

```java
public int doUpdate(MappedStatement ms, Object parameter) throws SQLException {
    Statement stmt = null;
    try {
      // 获取Configuration对象
      Configuration configuration = ms.getConfiguration();
      // 获取StatementHandler对象
      StatementHandler handler = configuration.newStatementHandler(this, ms, parameter, RowBounds.DEFAULT, null, null);
      // 预编译Statment
      stmt = prepareStatement(handler, ms.getStatementLog());
      // 执行update
      return handler.update(stmt);
    } finally {
      // 关闭statement
      closeStatement(stmt);
    }
  }
```

这个方法封装了sql与参数之间的解析环节，并最终获取Statement对象并最终执行update操作，这里主要类型为StatementHandler对象，我们来看看改着如何处理。

#### Configuration#newStatementHandler()

```java
public StatementHandler newStatementHandler(Executor executor, MappedStatement mappedStatement, Object parameterObject, RowBounds rowBounds, ResultHandler resultHandler, BoundSql boundSql) {
    StatementHandler statementHandler = new RoutingStatementHandler(executor, mappedStatement, parameterObject, rowBounds, resultHandler, boundSql);
    statementHandler = (StatementHandler) interceptorChain.pluginAll(statementHandler);
    return statementHandler;
  }
```

这段代码主要有两个重点：

- 使用RoutingStatementHandler来做statement的处理

- 调用Interceptor对StatementHandler进行处理，这里可能会改变StatementHandler的类型以及内部的一些处理逻辑。

> 这里对于拦截器相关原理这里不做解析，后面会有专门的章节介绍拦截器的工作原理

#### prepareStatement()

这个方法就是获取Statement对象的地方，这个就不用多介绍了，JDK的标准API, 大家应该都很熟悉。

```java
 private Statement prepareStatement(StatementHandler handler, Log statementLog) throws SQLException {
    Statement stmt;
    // 获取数据库连接
    Connection connection = getConnection(statementLog);
    // 预编译statement
    stmt = handler.prepare(connection, transaction.getTimeout());
    // 对stamt进行参数化
    handler.parameterize(stmt);
    return stmt;
  }
```

首先是获取数据库连接，然后就是对sql的处理，这个时候需要将SQL中的参数占位符替换为`?`站位符，具体代码如下;

#### RoutingStatementHandler#handle()

上面介绍了使用了改了作为SQL的处理方式，这里暂不考虑拦截器带来的影响，我们先看下`RoutingStatementHandler`初始化的构造方法，里面包含了一些特别的信息。

```java
public RoutingStatementHandler(Executor executor, MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler, BoundSql boundSql) {

    switch (ms.getStatementType()) {
      // 参数类型为STATEMENT
      case STATEMENT:
        delegate = new SimpleStatementHandler(executor, ms, parameter, rowBounds, resultHandler, boundSql);
        break;
      // PREPARED: 预编译SQL
      case PREPARED:
        delegate = new PreparedStatementHandler(executor, ms, parameter, rowBounds, resultHandler, boundSql);
        break;
      // CALLABLE:调用存储过程
      case CALLABLE:
        delegate = new CallableStatementHandler(executor, ms, parameter, rowBounds, resultHandler, boundSql);
        break;
      default:
        throw new ExecutorException("Unknown statement type: " + ms.getStatementType());
    }

  }
```

哈哈哈，到这里就应该明白这个Routing的含义了，其实就是根据操作类型做一些分发操作，那我们主要关注`PreparedStatementHandler`对象，因为我们大部分情况下为了避免SQL注入带来的问题，都会采用预编译的模式.

#### PreparedStatementHandler

##### prepare()

这个方法其实是定义在BaseStatementHandler类中，作为统一处理的模板方法，具体源码如下：

```java
public Statement prepare(Connection connection, Integer transactionTimeout) throws SQLException {
    ErrorContext.instance().sql(boundSql.getSql());
    Statement statement = null;
    try {
      // 实例化statement
      statement = instantiateStatement(connection);
      // 设置超时时间
      setStatementTimeout(statement, transactionTimeout);
      // 设置fetchsize
      setFetchSize(statement);
      return statement;
    } catch (SQLException e) {
      // 关闭statment
      closeStatement(statement);
      throw e;
    } catch (Exception e) {
      // 关闭statement
      closeStatement(statement);
      throw new ExecutorException("Error preparing statement.  Cause: " + e, e);
    }
  }
```

##### instantiateStatement()

实例化Statement方法是一个抽象方法，需要具体的子类来实现的，查看具体源码:

```java
@Override
  protected Statement instantiateStatement(Connection connection) throws SQLException {
    // 获取sql
    String sql = boundSql.getSql();
    // 调用parepareStatement方法预编译sql
    if (mappedStatement.getKeyGenerator() instanceof Jdbc3KeyGenerator) {
      String[] keyColumnNames = mappedStatement.getKeyColumns();
      if (keyColumnNames == null) {
        return connection.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
      } else {
        return connection.prepareStatement(sql, keyColumnNames);
      }
    } else if (mappedStatement.getResultSetType() == ResultSetType.DEFAULT) {
      return connection.prepareStatement(sql);
    } else {
      return connection.prepareStatement(sql, mappedStatement.getResultSetType().getValue(), ResultSet.CONCUR_READ_ONLY);
    }
  }
```

这里的实例化sql则是直接调用Connection#prepareStatment()方法，执行预编译操作。

##### parameterize()

前面已经生成预编译SQL，当我们真正执行的时候，就需要传入参数信息，该方法作用就在于对参数进行设置。

```java
public void setParameters(PreparedStatement ps) {
    ErrorContext.instance().activity("setting parameters").object(mappedStatement.getParameterMap().getId());
    // 获取参数映射列表
    List<ParameterMapping> parameterMappings = boundSql.getParameterMappings();
    if (parameterMappings != null) {
      // 遍历参数映射
      for (int i = 0; i < parameterMappings.size(); i++) {
        ParameterMapping parameterMapping = parameterMappings.get(i);
        // 判断参数是否输出，如果为输出，则跳过
        if (parameterMapping.getMode() != ParameterMode.OUT) {
          Object value;
          // 获取属性名称
          String propertyName = parameterMapping.getProperty();
          // 判断是否有属性名称???
          if (boundSql.hasAdditionalParameter(propertyName)) { // issue #448 ask first for additional params
            value = boundSql.getAdditionalParameter(propertyName);
          } else if (parameterObject == null) {
            // 参数为null, 则不需要解析
            value = null;
          } else if (typeHandlerRegistry.hasTypeHandler(parameterObject.getClass())) {
            // 判断对于当前参数类型，是否能够处理
            value = parameterObject;
          } else {
            // 将参数解析为MetaObject
            MetaObject metaObject = configuration.newMetaObject(parameterObject);
            value = metaObject.getValue(propertyName);
          }
          // 获取当前参数映射的类型处理器
          TypeHandler typeHandler = parameterMapping.getTypeHandler();
          // 获取目标jdbc类型
          JdbcType jdbcType = parameterMapping.getJdbcType();
          if (value == null && jdbcType == null) {
            jdbcType = configuration.getJdbcTypeForNull();
          }
          try {
            // 这里根据类型处理器执行设置参数的操作，具体类型是根据jdbc类型来定的
            // 因此这里暂不做过多解释
            typeHandler.setParameter(ps, i + 1, value, jdbcType);
          } catch (TypeException | SQLException e) {
            throw new TypeException("Could not set parameters for mapping: " + parameterMapping + ". Cause: " + e, e);
          }
        }
      }
    }
  }
```

##### update()

执行更新操作, 当sql参数设置完成后，就可以执行更新了，具体逻辑如下：

```java
public int update(Statement statement) throws SQLException {
    PreparedStatement ps = (PreparedStatement) statement;
    // 执行更新
    ps.execute();
    // 更新记录条数
    int rows = ps.getUpdateCount();
    // 获取参数对象
    Object parameterObject = boundSql.getParameterObject();
    // 获取key生成器
    KeyGenerator keyGenerator = mappedStatement.getKeyGenerator();
    // 将生成key放置到参数对象中
    keyGenerator.processAfter(executor, mappedStatement, ps, parameterObject);
    return rows;
  }
```

上面只是针对INSERT做了个解析，其他UPDATE/DELETE都是调用更新方法实现的，因此基本类似，这里就不做过多的阐述.

### 查询数据(SELECT)

查询数据相对于其他操作而言，最困难的在于对结果的解析，以及返回期望的对象，在查询的时候，代码片段为：

```java
case SELECT:
        if (method.returnsVoid() && method.hasResultHandler()) {
          executeWithResultHandler(sqlSession, args);
          result = null;
        } else if (method.returnsMany()) {
          result = executeForMany(sqlSession, args);
        } else if (method.returnsMap()) {
          result = executeForMap(sqlSession, args);
        } else if (method.returnsCursor()) {
          result = executeForCursor(sqlSession, args);
        } else {
          Object param = method.convertArgsToSqlCommandParam(args);
          result = sqlSession.selectOne(command.getName(), param);
          if (method.returnsOptional()
              && (result == null || !method.getReturnType().equals(result.getClass()))) {
            result = Optional.ofNullable(result);
          }
        }
        break;
```

#### executeWithResultHandler()无参返回

对于查询而言，当方法放回void的时候，这时候在方法参数中可能会有ResultHandler实现，通过ResultHandler实现对结果的解析，具体代码如下：

```java
  private void executeWithResultHandler(SqlSession sqlSession, Object[] args) {
    // 获取sql映射对象
    MappedStatement ms = sqlSession.getConfiguration().getMappedStatement(command.getName());
    // 判断当前的执行并不是callable操作, 并且返回值为void是，这时就会抛出异常
    if (!StatementType.CALLABLE.equals(ms.getStatementType())
        && void.class.equals(ms.getResultMaps().get(0).getType())) {
      throw new BindingException("method " + command.getName()
          + " needs either a @ResultMap annotation, a @ResultType annotation,"
          + " or a resultType attribute in XML so a ResultHandler can be used as a parameter.");
    }
    // 设置sql参数映射
    Object param = method.convertArgsToSqlCommandParam(args);
    // 判断方法是否包含了RowBounds的实现
    if (method.hasRowBounds()) {
      // 获取RowBounds
      RowBounds rowBounds = method.extractRowBounds(args);
      // 调用select方法
      sqlSession.select(command.getName(), param, rowBounds, method.extractResultHandler(args));
    } else {
      // 调用select方法
      sqlSession.select(command.getName(), param, method.extractResultHandler(args));
    }
  }
```

#### executeForMany()

处理查询结果为结合的操作，具体源码如下:

```java
private <E> Object executeForMany(SqlSession sqlSession, Object[] args) {
    List<E> result;
      
    // 获取参数对象
    Object param = method.convertArgsToSqlCommandParam(args);
    // 判断参数是否包含RowBounds
    if (method.hasRowBounds()) {
      // 获取RowBounds
      RowBounds rowBounds = method.extractRowBounds(args);
      // 调用selectList接口
      result = sqlSession.selectList(command.getName(), param, rowBounds);
    } else {
      result = sqlSession.selectList(command.getName(), param);
    }
    // issue #510 Collections & arrays support
    // 判断返回类型是否为方法类型的派生类，如果不是，则判断是否为数组
    if (!method.getReturnType().isAssignableFrom(result.getClass())) {
      if (method.getReturnType().isArray()) {
        return convertToArray(result);
      } else {
        // 将结果转换为集合并返回
        return convertToDeclaredCollection(sqlSession.getConfiguration(), result);
      }
    }
    return result;
  }
```

#### executeForMap()

该方法用于处理返回结果为Map的方法，具体实现如下：

```java
private <K, V> Map<K, V> executeForMap(SqlSession sqlSession, Object[] args) {
    Map<K, V> result;
     
    // 获取参数
    Object param = method.convertArgsToSqlCommandParam(args);
    // 是否包含了RowBounds
    if (method.hasRowBounds()) {
      // 获取参数中的RowBounds
      RowBounds rowBounds = method.extractRowBounds(args);
      // 调用SelectMap
      result = sqlSession.selectMap(command.getName(), param, method.getMapKey(), rowBounds);
    } else {
      result = sqlSession.selectMap(command.getName(), param, method.getMapKey());
    }
    return result;
  }
```

#### executeForCursor()

该方法主要用于返回类型为指针时，具体处理源码如下：

```java
private <T> Cursor<T> executeForCursor(SqlSession sqlSession, Object[] args) {
    Cursor<T> result;
    Object param = method.convertArgsToSqlCommandParam(args);
    if (method.hasRowBounds()) {
      RowBounds rowBounds = method.extractRowBounds(args);
      result = sqlSession.selectCursor(command.getName(), param, rowBounds);
    } else {
      result = sqlSession.selectCursor(command.getName(), param);
    }
    return result;
  }
```

对于这种情况，只是返回的方法不一样的而已，因此这里就不做过多介绍。

#### 处理返回单个值

```java
          // 包装参数对象
          Object param = method.convertArgsToSqlCommandParam(args);
          // 返回一个值
          result = sqlSession.selectOne(command.getName(), param);
          // 判断返回值是否为Optional, 如果是则用Optional包装
          if (method.returnsOptional()
              && (result == null || !method.getReturnType().equals(result.getClass()))) {
            result = Optional.ofNullable(result);
          }
```

对于以上代码中可以得知，其实一共就集中情况：

- 返回单个值或者`Optional`

- 返回`Map`结果集

- 返回`Collection`

- 返回`Cursor`结果集

这些在SqlSession中都有对应的包装类，因此我们查看对应的方法就行。

#### SqlSession

通过对于源码分析，在查询中一共可以分为三类，分别为`selectList`, `selectCursor`, `selectMap`三种，因此我们只对这三个公共方法做介绍。

##### selectList

```java
private <E> List<E> selectList(String statement, Object parameter, RowBounds rowBounds, ResultHandler handler) {
    try {
      // 获取sql映射对象
      MappedStatement ms = configuration.getMappedStatement(statement);
      // 通过executor执行查询插座
      return executor.query(ms, wrapCollection(parameter), rowBounds, handler);
    } catch (Exception e) {
      throw ExceptionFactory.wrapException("Error querying database.  Cause: " + e, e);
    } finally {
      ErrorContext.instance().reset();
    }
  }
```

这里最终的查询还是交予了Executor完成，如更新操作一样，我们这里还是以CachingExecutor和SimpleExecutor来看源码，其他类型的实现，可以自己查看源码。

#### CachingExecutor

```java
public <E> List<E> query(MappedStatement ms, Object parameterObject, RowBounds rowBounds, ResultHandler resultHandler) throws SQLException {
    // 根据参数生成动态SQL
    BoundSql boundSql = ms.getBoundSql(parameterObject);
    // 生成缓存key
    CacheKey key = createCacheKey(ms, parameterObject, rowBounds, boundSql);
    // 执行查询
    return query(ms, parameterObject, rowBounds, resultHandler, key, boundSql);
  }
```

##### query()

```java
public <E> List<E> query(MappedStatement ms, Object parameterObject, RowBounds rowBounds, ResultHandler resultHandler, CacheKey key, BoundSql boundSql)
      throws SQLException {
    // 获取映射文件中的cache对象
    Cache cache = ms.getCache();
    if (cache != null) {
      // 判断是否需要刷新缓存，如果需要，则刷新
      flushCacheIfRequired(ms);
      // 如果使用缓存，则从缓存中虎丘
      if (ms.isUseCache() && resultHandler == null) {
        // 确定没有输出参数
        ensureNoOutParams(ms, boundSql);
        @SuppressWarnings("unchecked")
        // 根据缓存key获取缓存列表
        List<E> list = (List<E>) tcm.getObject(cache, key);
        if (list == null) {
          // 如果缓存数据为空，则重新查询数据库，并将数据重新放回到缓存
          list = delegate.query(ms, parameterObject, rowBounds, resultHandler, key, boundSql);
          tcm.putObject(cache, key, list); // issue #578 and #116
        }
        return list;
      }
    }
    // 如果没有启用缓存，则直接查询数据库
    return delegate.query(ms, parameterObject, rowBounds, resultHandler, key, boundSql);
  }
```

这里我们知道，CachingExecutor是使用了代理模式，因此这里真正执行查询的是SimpleExecutor对象，因此我们查看SimpleExecutor对象的查询代码。

#### SimpleExecutor

这里查询最终还是会走BaseExecutor的模板方法，具体代码如下：

```java
public <E> List<E> query(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler, CacheKey key, BoundSql boundSql) throws SQLException {
    ErrorContext.instance().resource(ms.getResource()).activity("executing a query").object(ms.getId());
    if (closed) {
      throw new ExecutorException("Executor was closed.");
    }
    // 判断在同一个session下，查询被调用的次数，如果为0，并且需要清空缓存，则清空本地缓存
    if (queryStack == 0 && ms.isFlushCacheRequired()) {
      clearLocalCache();
    }
    List<E> list;
    try {
      // 查询栈递增
      queryStack++;
      // 如果ResultHandler为空，则从缓存中获取，否则为null
      list = resultHandler == null ? (List<E>) localCache.getObject(key) : null;
      if (list != null) {
        // 从缓存中获取数据成功，则处理缓存的输出参数
        handleLocallyCachedOutputParameters(ms, key, parameter, boundSql);
      } else {
        // 从缓存中获取失败，则从数据库查询数据
        list = queryFromDatabase(ms, parameter, rowBounds, resultHandler, key, boundSql);
      }
    } finally {
      queryStack--;
    }
    if (queryStack == 0) {
      // 递归加载，主要用来处理夸namespace的关联查询逻辑
      for (DeferredLoad deferredLoad : deferredLoads) {
        deferredLoad.load();
      }
      // issue #601
      deferredLoads.clear();
      // 如果本地缓存类型为STATEMENT级别，则在执行完成后，清空缓存。默认为SESSION
      if (configuration.getLocalCacheScope() == LocalCacheScope.STATEMENT) {
        // issue #482
        clearLocalCache();
      }
    }
    return list;
  }
```

##### queryFromDatabase()

现在主要看下从数据查询数据结果的处理方式，

```java
private <E> List<E> queryFromDatabase(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler, CacheKey key, BoundSql boundSql) throws SQLException {
    List<E> list;
    localCache.putObject(key, EXECUTION_PLACEHOLDER);
    try {
      // 执行查询
      list = doQuery(ms, parameter, rowBounds, resultHandler, boundSql);
    } finally {
      localCache.removeObject(key);
    }
    // 加入结果缓存
    localCache.putObject(key, list);
    // 如果执行类型为Callable, 则加入输出参数缓存
    if (ms.getStatementType() == StatementType.CALLABLE) {
      localOutputParameterCache.putObject(key, parameter);
    }
    return list;
  }
```

这里的doQuery()操作会调用到子类的实现方法上，我们查看doQuery()方法的逻辑实现：

```java
public <E> List<E> doQuery(MappedStatement ms, Object parameter, RowBounds rowBounds, ResultHandler resultHandler, BoundSql boundSql) throws SQLException {
    Statement stmt = null;
    try {
      Configuration configuration = ms.getConfiguration();
      // 处理器创建
      StatementHandler handler = configuration.newStatementHandler(wrapper, ms, parameter, rowBounds, resultHandler, boundSql);
      // 参数设置
      stmt = prepareStatement(handler, ms.getStatementLog());
      // 执行查询
      return handler.query(stmt, resultHandler);
    } finally {
      closeStatement(stmt);
    }
  }
```

这里跟上面保持一样，我们只关注PreparedStatementHandler对象的实现，其他的类感兴趣可以查看对应的源码。

#### PreparedStatementHandler

##### query()

查询逻辑就是执行具体的查询逻辑实现, 具体代码如下:

```java
public <E> List<E> query(Statement statement, ResultHandler resultHandler) throws SQLException {
    PreparedStatement ps = (PreparedStatement) statement;
    // 执行查询操作
    ps.execute();
    // 处理结果集
    return resultSetHandler.handleResultSets(ps);
  }
```

#### ResultSetHandler

结果集处理是从ResultSet中读取结果，并封装为对应的对象返回即可。

```java
public List<Object> handleResultSets(Statement stmt) throws SQLException {
    ErrorContext.instance().activity("handling results").object(mappedStatement.getId());

    final List<Object> multipleResults = new ArrayList<>();

    int resultSetCount = 0;
    // 获取ResultSet, 并封装到ResultSetWrapper中
    ResultSetWrapper rsw = getFirstResultSet(stmt);

    // 获取映射配置中的结果集
    List<ResultMap> resultMaps = mappedStatement.getResultMaps();
    int resultMapCount = resultMaps.size();
    // 判断结果集以及ResultMap配置是否合法
    validateResultMapsCount(rsw, resultMapCount);
    // 当配置中包含ResultMap时
    while (rsw != null && resultMapCount > resultSetCount) {
      // 获取ResultMap配置
      ResultMap resultMap = resultMaps.get(resultSetCount);
      // 处理ResultSet, 并按照ResultMap封装对象
      handleResultSet(rsw, resultMap, multipleResults, null);
      // 处理下一个结果集
      rsw = getNextResultSet(stmt);
      // 清空正在处理结果集信息
      cleanUpAfterHandlingResultSet();
      // 处理结果集数量+1
      resultSetCount++;
    }

    // 获取结果集信息
    String[] resultSets = mappedStatement.getResultSets();
    // 如果结果集不为空
    if (resultSets != null) {
      // 开始处理结果集
      while (rsw != null && resultSetCount < resultSets.length) {
        // 获取ResultSet中配置的resultMapping信息
        ResultMapping parentMapping = nextResultMaps.get(resultSets[resultSetCount]);
        if (parentMapping != null) {
          // 如果包含Result映射信息,获取嵌套结果集???
          String nestedResultMapId = parentMapping.getNestedResultMapId();
          // 获取结果集映射, 处理结果
          ResultMap resultMap = configuration.getResultMap(nestedResultMapId);
          handleResultSet(rsw, resultMap, null, parentMapping);
        }
        // 处理下一个结果集
        rsw = getNextResultSet(stmt);
        // 清楚正在处理的结果集
        cleanUpAfterHandlingResultSet();
        resultSetCount++;
      }
    }
    // 当集合为1的时候，返回第一个元素，否则返回基本本身
    return collapseSingleResultList(multipleResults);
  }
```

这里对于结果的处理主要使用了handleResultSet()方法处理，并将结果加入到列表中，

##### handleResultSet()

```java
private void handleResultSet(ResultSetWrapper rsw, ResultMap resultMap, List<Object> multipleResults, ResultMapping parentMapping) throws SQLException {
    try {
      // 是否包含父映射
      if (parentMapping != null) {
        handleRowValues(rsw, resultMap, null, RowBounds.DEFAULT, parentMapping);
      } else {
        if (resultHandler == null) {
          // 如果ResultHandler为空，则使用默认结果处理器
          DefaultResultHandler defaultResultHandler = new DefaultResultHandler(objectFactory);
          handleRowValues(rsw, resultMap, defaultResultHandler, rowBounds, null);
          multipleResults.add(defaultResultHandler.getResultList());
        } else {
          // 处理单行数据
          handleRowValues(rsw, resultMap, resultHandler, rowBounds, null);
        }
      }
    } finally {
      // issue #228 (close resultsets)
      closeResultSet(rsw.getResultSet());
    }
  }
```

这里可以知道，单行数据的处理使用了handleRowValues()来实现，因此着了我们具体看下该方法的实现。

##### handleRowValues()

```java
public void handleRowValues(ResultSetWrapper rsw, ResultMap resultMap, ResultHandler<?> resultHandler, RowBounds rowBounds, ResultMapping parentMapping) throws SQLException {
   // 判断结果集是否为前端结果集
   if (resultMap.hasNestedResultMaps()) {
      // 对于嵌套实现而言，不能有RowBounds, 除非将safeRowBoundsEnabled=false
      ensureNoRowBounds();
      // 检查ResultHandler
      checkResultHandler();
      // 处理嵌套结果集
      handleRowValuesForNestedResultMap(rsw, resultMap, resultHandler, rowBounds, parentMapping);
    } else {
      handleRowValuesForSimpleResultMap(rsw, resultMap, resultHandler, rowBounds, parentMapping);
    }
  }
```

##### handleRowValuesForNestedResultMap()

该方法有兴趣的可以自己查看下源码....

##### handleRowValuesForSimpleResultMap()

处理结果继续，具体源码如下:

```java
private void handleRowValuesForSimpleResultMap(ResultSetWrapper rsw, ResultMap resultMap, ResultHandler<?> resultHandler, RowBounds rowBounds, ResultMapping parentMapping)
      throws SQLException {
    // 结果集上下文
    DefaultResultContext<Object> resultContext = new DefaultResultContext<>();
    // 获取结果集
    ResultSet resultSet = rsw.getResultSet();
    // 这里实际上就是内存分页，当包含了rowBounds信息是，需要跳过Offset条记录
    skipRows(resultSet, rowBounds);
    // 这里是个条件，判断ResultSet还有数据，并且没有超过RowBounds限制的记录条数
    while (shouldProcessMoreRows(resultContext, rowBounds) && !resultSet.isClosed() && resultSet.next()) {
      // 获取结果映射集
      ResultMap discriminatedResultMap = resolveDiscriminatedResultMap(resultSet, resultMap, null);
      // 将行数据组装到ResultMap结果中
      Object rowValue = getRowValue(rsw, discriminatedResultMap, null);
      // 保存结果。
      storeObject(resultHandler, resultContext, rowValue, parentMapping, resultSet);
    }
  }
```

##### getRowValue()

```java
private Object getRowValue(ResultSetWrapper rsw, ResultMap resultMap, String columnPrefix) throws SQLException {
    final ResultLoaderMap lazyLoader = new ResultLoaderMap();
    // 创建ResultObject对象
    Object rowValue = createResultObject(rsw, resultMap, lazyLoader, columnPrefix);
    // 判断类型是否包含了ResultHandler的实现
    if (rowValue != null && !hasTypeHandlerForResultObject(rsw, resultMap.getType())) {
      final MetaObject metaObject = configuration.newMetaObject(rowValue);
      // 是否包含了构造器参数映射
      boolean foundValues = this.useConstructorMappings;
      // 判断是否自动映射，这里根据ResultMap来做判断，
      if (shouldApplyAutomaticMappings(resultMap, false)) {
        // 自动映射，其实就是根据sql中的字段名称去匹配在resultObject中是否包含对应的属性
        // 以及对应的setter方法，因此这里不做过多阐述
        foundValues = applyAutomaticMappings(rsw, resultMap, metaObject, columnPrefix) || foundValues;
      }
      // 这里处理带有prefix的属性，以及嵌套查询的逻辑实现
      foundValues = applyPropertyMappings(rsw, resultMap, metaObject, lazyLoader, columnPrefix) || foundValues;
      foundValues = lazyLoader.size() > 0 || foundValues;
      rowValue = foundValues || configuration.isReturnInstanceForEmptyRow() ? rowValue : null;
    }
    return rowValue;
  }
```

##### createResultObject()

```java
private Object createResultObject(ResultSetWrapper rsw, ResultMap resultMap, ResultLoaderMap lazyLoader, String columnPrefix) throws SQLException {
    this.useConstructorMappings = false; // reset previous mapping result
    final List<Class<?>> constructorArgTypes = new ArrayList<>();
    final List<Object> constructorArgs = new ArrayList<>();
    // 结果对象
    Object resultObject = createResultObject(rsw, resultMap, constructorArgTypes, constructorArgs, columnPrefix);
    // 是否包含ResultHandler, 不包含怎使用set方法设置属性
    if (resultObject != null && !hasTypeHandlerForResultObject(rsw, resultMap.getType())) {
      final List<ResultMapping> propertyMappings = resultMap.getPropertyResultMappings();
      // 设置对象参数属性
      for (ResultMapping propertyMapping : propertyMappings) {
        // issue gcode #109 && issue #149
        if (propertyMapping.getNestedQueryId() != null && propertyMapping.isLazy()) {
          resultObject = configuration.getProxyFactory().createProxy(resultObject, lazyLoader, configuration, objectFactory, constructorArgTypes, constructorArgs);
          break;
        }
      }
    }
    // 当对象创建成功，并且使用了构造器设置参数，则为true
    this.useConstructorMappings = resultObject != null && !constructorArgTypes.isEmpty(); // set current mapping result
    return resultObject;
  }
```

##### createResultObject() 创建ResultObject

创建结果对象最终会执行到该方法，该方法中是对结果集的处理，具体源码如下：

```java
private Object createResultObject(ResultSetWrapper rsw, ResultMap resultMap, List<Class<?>> constructorArgTypes, List<Object> constructorArgs, String columnPrefix)
      throws SQLException {
    // 获取结果对象类型
    final Class<?> resultType = resultMap.getType();
    // 获取对象的元数据信息
    final MetaClass metaType = MetaClass.forClass(resultType, reflectorFactory);
    // 获取结果集的构造器配置信息
    final List<ResultMapping> constructorMappings = resultMap.getConstructorResultMappings();
    // 判断是否对于结果类型，有对应的ResultHandler处理
    if (hasTypeHandlerForResultObject(rsw, resultType)) {
      // 如果有对应的类型处理，则穿件基本类型结果对象
      return createPrimitiveResultObject(rsw, resultMap, columnPrefix);
    } else if (!constructorMappings.isEmpty()) {
      // 判断是否包含了构造器的映射，如果包含，则按照构造器映射创建对象
      return createParameterizedResultObject(rsw, resultType, constructorMappings, constructorArgTypes, constructorArgs, columnPrefix);
    } else if (resultType.isInterface() || metaType.hasDefaultConstructor()) {
      // 如果对象是接口或者包含了默认构造器，则使用ObjecctFactory创建对象
      return objectFactory.create(resultType);
    } else if (shouldApplyAutomaticMappings(resultMap, false)) {
      return createByConstructorSignature(rsw, resultType, constructorArgTypes, constructorArgs);
    }
    throw new ExecutorException("Do not know how to create an instance of " + resultType);
  }
```

#### selectMap

该方法主要是返回结果集为Map对象，因此这里查看下对应源码即可：

> 这里要注意，selectMap并不是按照返回值为map时调用，而是使用了@MapKey注解的时候，才会走这个逻辑。

```java
public <K, V> Map<K, V> selectMap(String statement, Object parameter, String mapKey, RowBounds rowBounds) {
    // 这里和以上的查询类似，就不做过多阐述
    final List<? extends V> list = selectList(statement, parameter, rowBounds);
    final DefaultMapResultHandler<K, V> mapResultHandler = new DefaultMapResultHandler<>(mapKey,
            configuration.getObjectFactory(), configuration.getObjectWrapperFactory(), configuration.getReflectorFactory());
    final DefaultResultContext<V> context = new DefaultResultContext<>();
    for (V o : list) {
      // 遍历每一个元素，并放入到上下文中
      context.nextResultObject(o);
      // 处理单个对象结果
      mapResultHandler.handleResult(context);
    }
    // 返回map的结果
    return mapResultHandler.getMappedResults();
  }


```

##### DefaultMapResultHandler

这里查看下这个是如何将一个对象映射成为map对象的。

```java
public void handleResult(ResultContext<? extends V> context) {
    // 获取结果对象
    final V value = context.getResultObject();
    // 获取结果对象的元数据信息
    final MetaObject mo = MetaObject.forObject(value, objectFactory, objectWrapperFactory, reflectorFactory);
    // TODO is that assignment always true?
    // 这里获取mapKey, 这个mapKey是可能为null的
    final K key = (K) mo.getValue(mapKey);
    // 加入到结果集
    mappedResults.put(key, value);
  }


```

#### selectCursor

查询指针的是由mybatis实现的，在处理查询的逻辑的时候基本保持一致，这里主要看下对结果集的封装情况。

```java
public <E> Cursor<E> handleCursorResultSets(Statement stmt) throws SQLException {
   
    ErrorContext.instance().activity("handling cursor results").object(mappedStatement.getId());

    ResultSetWrapper rsw = getFirstResultSet(stmt);

    List<ResultMap> resultMaps = mappedStatement.getResultMaps();

    int resultMapCount = resultMaps.size();
    validateResultMapsCount(rsw, resultMapCount);
    if (resultMapCount != 1) {
      throw new ExecutorException("Cursor results cannot be mapped to multiple resultMaps");
    }

    ResultMap resultMap = resultMaps.get(0);
    // 创建Cursor对象
    return new DefaultCursor<>(this, resultMap, rsw, rowBounds);
  }
```

这里就不详细介绍cursor的使用，如果有兴趣可以自己查看一下源码。



以上就是Mapper的执行原理，如果对你有帮助，请为文章点赞.
