## 通过http的方式暴露env配置
- management.endpoints.web.exposure.include=info,env
- management.security.enabled=false

### 通过这种方式可以查看堆栈使用的情况
- http://172.16.1.170:9021/metrics/heap.*|threads.*|gc.*|mem.*|classes.*
