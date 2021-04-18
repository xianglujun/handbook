# Egress

## 访问外部服务方法

- 配置 `global.outboundTrafficPolicy.mode=ALLOW_ANY`
- 使用服务入口(ServiceEntry)
- 配置sidecar让流量绕过代理
- 配置Egress网关

## Egress概念

- Egress网关
  - 定义了网格的出口点，允许你将监控，路由等功能应用于离开网格的流量
- 应用场景
  - 所有出口流量必须流经一组专用节点(安全因素)
  - 为无法访问公网的内部服务做代理

![image-20210213170851734](.\image-20210213170851734.png)

## 定义egress

```shell
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
     number: 80
     name: http
     protocol: HTTP
    hosts:
     - httpbin.org
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: vs-for-egressgateway
spec:
  hosts:
    - httpbin.org
  gateways:
    - istio-egressgateway # 针对egress网关
    - mesh # 针对内部网格
  http:
  - match:
    - gateways:
      - mesh # 把内部请求路由到网关节点
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: httpbin
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway # 将网关请求路由到外部请求
      port: 80
    route:
    - destination:
        host: httpbin.org
        port:
          number: 80
      weight: 100
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: dr-for-egressgateway
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: httpbin

```

