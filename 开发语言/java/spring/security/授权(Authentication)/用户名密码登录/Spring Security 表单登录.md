# 用户名密码表单登录

![](../../../../../assets/2023-05-26-10-29-14-loginurlauthenticationentrypoint.png)

spring security支持通过html表单的方式实现登录。上图则是表单登录的一个流程，则每个步骤解释如下：

- 用户发送未授权请求，`/private`请求用于请求资源

- Spring Security 中的`AuthenticationFilter`拦截请求并发现请求未授权，则抛出`AccessDeniedException`异常

- 用户没有授权时，ExceptionTranslationFilter初始化一个Authentication并发送重定向链接到登录界面，并且在跳转到登录界面之前，会通过`AuthenticationEntryPoint`类记性必要的配置，大多数情况下都是`LoginUrlAuthenticationEntryPoint`

- 浏览器请求重定向的登录地址

- 渲染登录界面，并执行后续登录操作。

## 用户名密码登录流程

![](../../../../../assets/2023-05-26-14-40-02-usernamepasswordauthenticationfilter.png)

则对应的spring security的处理流程如下：

- 当用户提交用户名和密码数据的时候，首先`UsernamePasswordAuthenticationFilter`会拦截请求并创建`UsernamePasswordAuthenticationToken`对象，该对象是`Authentication`的实例，并且用户名和密码是从表单请求参数中获取的。

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

## 程序配置

```java
/**
 * 自定义spring security 配置信息
 *
 * @author xianglujun
 * @date 2023/5/26 15:04
 */
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

在以上配置中，主要配置了几种资源信息：

- 资源授权情况：其中就包括了静态资源不需要授权，登录地址无需授权

- 表单登录配置情况：其中包含了表单字段的名称，登录界面, 成功后的跳转界面，失败后的跳转界面等。

- 用户资源情况：用户资源就是登录的时候需要的用户名和密码信息，以上配置主要是内存中存储，其他情况可能是数据库，也可能是远程服务提供登录用户信息。
