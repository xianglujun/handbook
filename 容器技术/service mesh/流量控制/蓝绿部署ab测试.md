# 蓝绿部署

![image-20210213155345914](.\image-20210213155345914.png)

> 灰度发布又叫做金丝雀发布，金丝雀对瓦斯比较敏感

## A/B测试

用于提供一个功能的不同版本。



## 实现流量的切分操作

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - match:
    - headers:
       User-Agent:
         exact: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.141 Safari/537.36'
    route:
    - destination:
         host: reviews
         subset: v3
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 50
    - destination:
        host: reviews
        subset: v3
      weight: 50
```

