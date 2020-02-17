# mybatis生命周期

## SqlSessionFactoryBuilder
`SqlSessionFactoryBuilder`利用XML方式或者硬编码的方式创建`SqlSessionFactory`对象, 通过它可以构建多个`SqlSessionFactory`. 它的作用就是一个构建器, 一旦我们构建完成`SqlSessionFactory`对象, 它的作用就失去了意义, 我们就应该将该对象进行回收。

所以它的声明周期就只存在于局部变量, 并且只是用来创建`SqlSessionFactory`对象。

## SqlSessionFactory
SqlSessionFactory的主要目的用来创建SqlSession对象, SqlSession用于对数据库连接, 相当于Connection对象。过多的创建SqlSessionFactory对象, 会导致大量的SqlSession对象被创建, 同事对于SqlSessionFactory管理也会变得更加复杂。

因此SqlSessionFactory只保持一个, 保持单例模式。并且贯穿于mybatis整个生命周期，在使用SqlSessionFactory的时候, 应该尽量避免创建过多的SqlSession, 防止资源消耗殆尽。

## SqlSession
`SqlSession`是一个回话，相当于数据库连接的`Connection`, 它的生命周期应该是在请求数据库执行事务期间。对于`SqlSession`有一下两点需要注意:
1. `SqlSession`是线程不安全的，在设计多线程的时候，需要多加注意数据库的事务隔离级别，以及数据库锁的相关高级特性。
2. 每次创建`SqlSession`并使用完成之后应该及时关闭，它的长期存在会使得数据库的活动资源减少，从而影响数据库的执行性能。
3. `SqlSession`能够同时执行多条SQL，来保证事务的一致性。

## Mapper
Mapper是一个接口，没有具体的实现类。它的作用就是发送SQL, 然后返回我们需要的结果，或者执行SQL从而修改数据库中的数据, 是一个方法级别的组件。

它的最大的范围是与SqlSession保持一致。再说会用中我们会发现我们很难的控制Mapper,所以尽量在SqlSession的事务中使用它们。
