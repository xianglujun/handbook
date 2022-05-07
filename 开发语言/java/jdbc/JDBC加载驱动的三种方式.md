# JDBC加载驱动程序的三种方式
1. 通过`Class.forName`的方式, 加载驱动程序的元数据`Class`
```java
Class.forName("com.mysql.jdbc.Driver");
```

2. 通过`DriverManager`的方式注册
```java
DriverManger.register(new com.mysql.jdbc.Driver());
```

3. 配置全局的系统变量
```java
System.setProperties("java.drivers", "com.mysql.jdbc.Driver");
```
