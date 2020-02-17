# mysql问题小计

1. `Access denied for localhost`
```sql
grant all privileges on *.* to root@localhost identified by '你为root设置好的密码'
```
