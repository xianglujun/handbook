# Hive授权

## Hive 在Hiveserver2中使用标准SQL授权

### 限制

1. 启动当前认证方式之后，`dfs`, `add`, `delete`, `compile`, `reset`等命令被禁用

2. 通过set命令设置`hive configurations`的方式被限制某些用户使用
   
   - 可通过修改配置文件`$HIVE_HOME/conf/hive-site.xml`配置`hive.security.authorization.sqlstd.confwhitelist`

3. 添加/删除函数以及宏的操作，仅为具有admin的用户开放

4. 用户自定义函数(开放支持永久的自定义函数)，可通过具有admin角色的用户创建，其他用户可以使用

5. tranform功能被禁用

### hive-site.xml配置

```xml
<property>
    <name>hive.security.authorization.enabled</name>
    <value>true</value>
</property>
<property>
    <name>hive.server2.enable.doAs</name>
    <value>false</value>
</property>
<property>
    <name>hive.users.in.admin.role</name>
    <value>root</value>
</property>
<property>
    <name>hive.security.authorization.manager</name>
    <value>org.apache.hadoop.hive.ql.security.authorization.plugin.sqlstd.SQLStdHiveAuthorizerFactory</value>
</property>
<property>
    <name>hive.security.authenticator.manager</name>
    <value>org.apache.hadoop.hive.ql.secruity.SessionStateUserAuthenticator</value>
</property>
```

### 角色操作

```sql
create role role_name; -- 创建角色
drop role role_name; -- 删除角色
set role (role_name|all|none); -- 设置角色
show current roles; -- 查看当前具有的角色
show roles; -- 查看所有存在的角色
```

### 授权

#### 角色的授予、移除、查看

```sql
-- 将角色授予某个用户、角色
grant role_name [, role_name]... to principal_specification
[,principal_specification].. [with admin option];

-- 撤销角色
revoke [ADMIN OPTION FOR] role_name [, role_name]..
from principal_specification[, principal_specification]..


pricipal_specification:
: USER user_name
| ROLE role_name


-- 删除角色
 drop role role_name;
```

```sql
-- 创建角色
create role role1;
-- 授权
grant admin to role role1 with admin option;

-- 查看授予某个用户/角色的角色列表
show role grant(user|role) user_role_name;

-- 查看角色被授予的列表
show principals admin;

-- 取消授权
```

#### 权限授予

权限一共分为以下几类：

- `ALL`：给用户所有的权限

- `ALTER`：给用户修改元数据的权限

- `UPDATE`：允许用户修改物理数据的权限

- `CREATE`：给用户创建的权限，包括创建数据库，表。这也有意味着能够创建分区等

- `DROP`：允许用户删除数据资源

- `INDEX`：允许用户创建索引

- `LOCK`：允许用户在并发情况下锁定/解锁表

- `SELECT`：允许用户检索数据库数据

- `SHOW_DATABASE`：允许用户查看可用的数据的列表

##### 权限授予语法

授权的操作和上面的角色授权很相似，

```sql
-- 授权
GRANT priv_type[, priv_type]..
ON table_or_view_name
to principal_specification[, principal_specification]..
[WITH GRANT OPTION];

-- 移除权限
REVOKE [GRANT OPTION FOR]
priv_type[, priv_type...]
ON table_or_view_name
FROM principal_specification[, principal_specification..]

-- 查看某个用户、角色的权限
SHOW GRANT [principal_name] ON (ALL | TABLE table_or_view_name)


pricipal_specification格式如下：
USER user_name
| ROLE role_name
```
