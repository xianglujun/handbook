# sentinel限流规则

sentinel在系统启动的时候，会根据当前使用的web类型设置对应不同的限流机制触发后的处理方式。我们需要搞明白如何配置，然后才能实现自己的限流处理方式。

## 1. 限流默认处理配置

首先我们查看在Servlet环境下针对默认限流处理配置信息：

```java
@Configuration(proxyBeanMethods = false)
@ConditionalOnWebApplication(type = Type.SERVLET)
@ConditionalOnProperty(name = "spring.cloud.sentinel.enabled", matchIfMissing = true)
@ConditionalOnClass(SentinelWebInterceptor.class)
@EnableConfigurationProperties(SentinelProperties.class)
public class SentinelWebAutoConfiguration implements WebMvcConfigurer {

    private static final Logger log = LoggerFactory
            .getLogger(SentinelWebAutoConfiguration.class);

    // sentinel配置对象
    @Autowired
    private SentinelProperties properties;

    // UrlCleaner对象
    @Autowired
    private Optional<UrlCleaner> urlCleanerOptional;

    // BlockExceptionHandler对象
    @Autowired
    private Optional<BlockExceptionHandler> blockExceptionHandlerOptional;

    // RequestOriginParser对象
    @Autowired
    private Optional<RequestOriginParser> requestOriginParserOptional;

    @Bean
    @ConditionalOnProperty(name = "spring.cloud.sentinel.filter.enabled",
            matchIfMissing = true)
    public SentinelWebInterceptor sentinelWebInterceptor(
            SentinelWebMvcConfig sentinelWebMvcConfig) {
        // 创建SentinelWebInterceptor对象
        return new SentinelWebInterceptor(sentinelWebMvcConfig);
    }

    @Bean
    @ConditionalOnProperty(name = "spring.cloud.sentinel.filter.enabled",
            matchIfMissing = true)
    public SentinelWebMvcConfig sentinelWebMvcConfig() {
        // 创建SentinelWebMvcConfig对象
        SentinelWebMvcConfig sentinelWebMvcConfig = new SentinelWebMvcConfig();
        // 设置http 指定method,
        sentinelWebMvcConfig.setHttpMethodSpecify(properties.getHttpMethodSpecify());
        sentinelWebMvcConfig.setWebContextUnify(properties.getWebContextUnify());

        // 如果系统中已经存在了BlockExceptionHandler对象，则以系统中的为准
        if (blockExceptionHandlerOptional.isPresent()) {
            blockExceptionHandlerOptional
                    .ifPresent(sentinelWebMvcConfig::setBlockExceptionHandler);
        }
        else {
            // 判断是否发生了限流时，是否跳转到指定界面，如果是，则使用跳转配置
            if (StringUtils.hasText(properties.getBlockPage())) {
                sentinelWebMvcConfig.setBlockExceptionHandler(((request, response,
                        e) -> response.sendRedirect(properties.getBlockPage())));
            }
            else {
                // 如果没有配置跳转界面，设输出指定的文字即可。
                sentinelWebMvcConfig
                        .setBlockExceptionHandler(new DefaultBlockExceptionHandler());
            }
        }

        urlCleanerOptional.ifPresent(sentinelWebMvcConfig::setUrlCleaner);
        requestOriginParserOptional.ifPresent(sentinelWebMvcConfig::setOriginParser);
        return sentinelWebMvcConfig;
    }

    @Bean
    @ConditionalOnProperty(name = "spring.cloud.sentinel.filter.enabled",
            matchIfMissing = true)
    public SentinelWebMvcConfigurer sentinelWebMvcConfigurer() {
        return new SentinelWebMvcConfigurer();
    }

}
```

从默认限流处理逻辑来看，如果我们想覆盖默认限流异常处理逻辑时，则直接实现`BlockExceptionHandler`接口即可。则对应的实现如下：

```java
package org.spring.cloud.alibaba.learn.sentinel.config;

/**
 * @author xianglujun
 * @date 2023/5/9 15:20
 */
@Service
public class CustomBlockExceptionHandler implements BlockExceptionHandler {

    private SentinelProperties sentinelProperties;

    public CustomBlockExceptionHandler(SentinelProperties sentinelProperties) {
        this.sentinelProperties = sentinelProperties;
    }

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, BlockException e) throws Exception {
        if (isAjax(request)) {
            response.setHeader("Content-Type", "application/json;charset=utf-8");
            PrintWriter writer = response.getWriter();
            writer.println(R.fail("Oops, 被限流了"));
        } else {
            response.sendRedirect(this.sentinelProperties.getBlockPage());
        }
    }

    private boolean isAjax(HttpServletRequest request) {
        String header = request.getHeader("X-Requested-With");
        if (Objects.nonNull(header) && header.indexOf("XMLHttpRequest") > -1) {
            return true;
        }

        header = request.getHeader("accept");
        return Objects.nonNull(header)
                && header.indexOf("application/json") > -1;
    }
}
```

以此就实现了限流信息处理。

以上的实现有两个操作逻辑：

- 如果是ajax请求，则返回的是一个json格式的响应信息

- 如果非ajax请求，则跳转到指定的界面

## 2. 限流规则配置

### 2.1 通过程序代码创建

```java
        System.out.println("加载sentinel流控制");
        FlowRule flowRule = new FlowRule();
        flowRule.setClusterMode(false);
        // 设置qps的值为3
        flowRule.setCount(3);
        // 设置qps
        flowRule.setGrade(RuleConstant.FLOW_GRADE_QPS);
        // 限制app, 可以指定某个app限流，对所有生效可以设置为default
        flowRule.setLimitApp("default");
        flowRule.setClusterConfig(new ClusterFlowConfig());
        // 设置需要限流的资源名称
        flowRule.setResource("sayHello");
        flowRule.setRefResource(resourceName);

        FlowRuleManager.loadRules(Arrays.asList(flowRule));
```

> FlowRuleManager类中loadRules的方法会覆盖已有的策略，需要注意这点。
