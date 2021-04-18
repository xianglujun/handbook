# Envroy 流量五元组

![image-20210214212937630](.\image-20210214212937630.png)

## 调试字段 - RESPONSE_FLAGS

- UH :  upstream cluster 中没有健康的host, 503
- UF: upstream 链接失败, 503
- UO: upstream overflow(熔断)
- NR: 没有路由配置, 404
- URX: 请求被拒绝因为限流或最大链接次数

## 日志配置项

| 配置项                         | 说明                                                         |
| ------------------------------ | ------------------------------------------------------------ |
| gloabal.proxy.accessLogFile    | 日志输出文件，空为关闭输出                                   |
| global.proxy.accessLogEncoding | 日志编码格式：JSON, TEXT                                     |
| global.proxy.accessLogFormat   | 配置显示在日志中的字段，空为默认格式                         |
| global.proxy.logLevel          | 日志级别, 空为warning，可选: trace\|debug\|inf\|warning\|error\|critical\|off |

