# SpringJDBC
## JdbcTemplate

## Jdbc RDBMS
RDBMS指代的是关系性数据库管理系统, 在Spring JDBC中, 主要通过 `RdbmsOperations`的类进行实现, 具体的类结构如下:
![RdbmsOperation的类继承结构](../../img/spring/rdbms_operations.png)

### SqlQuery的实现
![数据转换调用时序图](../../img/spring/rdbms_operation_time_line.png)
