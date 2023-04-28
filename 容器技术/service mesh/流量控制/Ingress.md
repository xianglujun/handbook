# Ingress

## 基本概念

- 服务的访问入口，接收外部请求并转发到后端服务
- Istio的Ingress gateway 和 Kubernetes Ingress的区别
  - Kubernetes: 针对L7协议(资源受限)，可定义路由规则
  - Istio: 针对L4-6协议，只定义接入点，复用Virtual Service的L7路由协议