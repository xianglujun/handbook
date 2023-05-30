# Spring Security Basic登录

在未登录的情况下，当我们访问需要授权的资源的时候，basic会返回`WWW-Authenticate`的header信息，具体的流程图如下：

![](../../../../../assets/2023-05-29-14-29-51-basicauthenticationentrypoint.png)

具体步骤解释如下：

1. 发送需要授权的请求`/private`到后端

2. `AuthenticationFilter`拦截请求并拒绝，抛出`AcessDeniedException`异常

3. 当用户没有授权时，`AcessDeniedException`异常被`ExceptionTranslationFilter`所拦截，然后此时`AuthenticationEntryPoint`实例为`BasicAuthenticationEntryPoint`, 该实例会向`response`中写入`WWW-Authenticate`header信息。在`RequestCache`中为`NullRequestCache`以代表当前的请求信息。

当客户端收到了带有`WWW-Authenticate`响应头信息时，将会带有用户名和密码信息的请求再次发送到服务端，则具体的逻辑如下:

![](../../../../../assets/2023-05-29-15-06-29-basicauthenticationfilter.png)

则对应的spring security的处理流程如下：

- 当用户提交用户名和密码数据的时候，首先`BasicAuthenticationFilter`会拦截请求并创建`UsernamePasswordAuthenticationToken`对象，该对象是`Authentication`的实例，filter从header `Authentication`中获取用户名和密码信息。

- `UsernamePasswordAuthenticationToken`被发送到`AuthenticationManager`执行授权操作

- 当用户授权失败后，将执行一下行为：
  
  - `SecurityContextHolder`负责清空上下文对象信息
  
  - 将执行`RememberMeServices.loginFail`方法，如果没有配置`rememberme`，则不会执行任何操作
  
  - `AuthenticationFailureHandler`被执行

- 当用户授权执行成功，将执行以下行为：
  
  - `SessionAuthenticationStrategy`将被通知有一个新的登录
  
  - 接着Authentication对象将被设置到SecurityContextHolder中，`SecurityContextRepository#saveContext`方法必须被明确的调用。并且在未来请求中，将会自动绑定到`SecurityContext`中
  
  - `RememberMeServices.loginSuccess`方法被执行，如果没有设置rememberme，则不会执行任何操作
  
  - `ApplicationEventPublisher`发送一个`InteractiveAuthenticationSuccessEvent`事件
  
  - `AuthenticationSuccessHandler`类被执行

> basic模式下，请求用户名和密码信息都是放在`Authentication`中，具体的使用规则如下：
> 
> - 将用户名和密码信息进行拼接. `username:password`
> 
> - 将拼接信息进行base64加码
> 
> - 将base64加码信息设置到请求header`Authentication`中

> 在spring security中，默认是开启了basic的功能，只是在自定义配置的情况下，需要手动开启。

## 程序配置

```java
@EnableWebSecurity(debug = true)
@Configuration
public class CustomWebSecurityConfiguration extends WebSecurityConfigurerAdapter {

    @Override
    public void configure(WebSecurity web) throws Exception {
        super.configure(web);
        web
                .ignoring() // 配置不需要鉴权的地址
                .antMatchers("/static/**"); // 过滤所有静态地址配置
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth
                .eraseCredentials(false) // 是否在鉴权成功之后, 将密码清楚
                .inMemoryAuthentication() // 使用内存用户设置
                .passwordEncoder(NoOpPasswordEncoder.getInstance())
                .withUser("admin") // 设置用户名
                .password("8888") // 设置密码
                .roles("USER", "ADMIN"); // 设置角色列表
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.formLogin((form) -> form.loginPage("/login") // 登录的请求地址
                .permitAll(true)
                .passwordParameter("pwd") // 设置密码参数名称
                .usernameParameter("um") // 设置用户名称参数名称
                .defaultSuccessUrl("/index") // 成功之后跳转地址
                .failureUrl("/login?error")); // 开启表单登录;
        http.httpBasic();
        http.authorizeRequests((registry) -> {
            registry.antMatchers("/**").authenticated();
        });
    }


}
```

> 开启basic主要通过`http.httpBasic()`方法进行配置和实现
