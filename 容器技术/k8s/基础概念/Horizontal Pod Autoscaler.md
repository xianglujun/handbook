# Horizontal Pod Autoscaler

HPA与之前的RC, Deployment一样, 也属于一种Kubernetes资源对象。通过追踪分析RC控制的所有目标Pod的负载变化情况, 来确定是否需要针对性地调整目标Pod的副本数。



## HPA的负载度量指标

### CPUUtilizationPercentage

应用程序自定义的度量指标,  _CPUUtilizationPercentage_是个算数平均值, 即目标Pod所有副本自身的CPU利用率的平均值。

- _CPUUtilizationPercentage_计算过程中使用到的Pod的CPU使用量通常是1min内的平均值。
- 如果目标_pod_没有定义_Pod Request_的值, 则无法使用_CPUUtilizationPercentage_来实现Pod横向自动扩容的能力。