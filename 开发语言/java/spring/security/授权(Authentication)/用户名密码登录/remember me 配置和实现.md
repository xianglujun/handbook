# spring security remeber me 配置和实现

remember-me的功能或者持久化身份认证是指网站能够在会话期间记住主体的身份信息。这通常是通过向浏览器发送cookie来实现的，cookie在未来的会话中被检测到，并且用来实现自动登录。Spring Security为这些操作提供了必要的钩子，并有两个具体的记住我的实现。一种使用哈希来保护基于cookie的令牌的安全性，另一种使用数据库或其他持久存储机制来存储生成的令牌。

> 请注意，这两个实现都需要UserDetailsService。如果您使用的身份验证提供程序不使用UserDetailsService（例如LDAP提供程序），则除非您的应用程序上下文中也有UserDetailsServicebean，否则它将无法工作。

## 基于hash的token实现方法

当用户授权成功之后，将会向浏览器写入cookie信息，其中包含了授权认证信息等。写入的cookie信息中，包含了以下几个部分：

```java
base64(username + ":" + expirationTime + ":" + algorithmName + ":"
algorithmHex(username + ":" + expirationTime + ":" password + ":" + key))

username:          As identifiable to the UserDetailsService
password:          That matches the one in the retrieved UserDetails
expirationTime:    The date and time when the remember-me token expires, expressed in milliseconds
key:               A private key to prevent modification of the remember-me token
algorithmName:     The algorithm used to generate and to verify the remember-me token signature
```

在以上的实现中，会存在安全问题(这在`digest authentication`同样存在),当用户授权之后，向浏览器写出的cookie信息可能会被拦截并使用，这是因为`cookie`中的信息带有了过期时间信息，在过期时间前，可以执行修改密码登操作，最终导致所有的`remember-me`的信息失效。

## 接口和实现

`remember-me`的使用场景主要实在`UsernamePasswordAuthenticationFilter`并且通过`AbstractAuthenticationProcessingFilter`钩子方法进行调用。同时`BasicAuthenticationFilter`也直接使用了`RememberMeServices`实现`remember-me`的功能。

`RememberMeServices`主要主要方法有如下：

```java
Authentication autoLogin(HttpServletRequest request, HttpServletResponse response);

void loginFail(HttpServletRequest request, HttpServletResponse response);

void loginSuccess(HttpServletRequest request, HttpServletResponse response,
	Authentication successfulAuthentication);
```

在现阶段的中，`AbstractAuthenticationProcessingFilter`主要使用了`loginFail()`和`loginSuccess()`两个方法，每当`SecurityContextHolder`不包含授权详情信息时，`RememberMeAuthenticationFilter`就会调用`autoLogin()`方法完成自动登录的操作。在spring security中，主要有两种实现，我们具体看一下。

### TokenBasedRememberMeServices

这个实现类型支持基于hash的token实现，上面谈到，这类hash串种包含了几种类型的信息。`TokenBasedRememberMeServices`会生成`RememberMeAuthenticationToken`对象，然后经由`RememberMeAuthenticationProvider`进行处理。

- 这类对象在创建的时候，需要指定一个`key`值，该值会在`TokenBasedRememberServices`和`RemeberMeAuthenticationProvider`中共享

- 同时该类也需要一个`UserDetailsService`对象，该对象用于维护和获取用户详情数据信息。

- 同时该类也实现了`LogoutHandler`的功能，配合`LogoutFilter`用于用户在登出的时候，清楚`cookie`信息

- 在默认情况下，使用了`SHA-256`进行`token`的签名，在进行算法匹配时，会遍历所有支持的算法，当没有算法匹配的时候，默认就会使用`SHA-256`进行处理，这样当用户执行算法后，在之前的老数据也能够正常得以匹配，不至于造成错误。

- 用户可以自己实现`TokenBasedRemeberMeServices`的创建，用来指定需要的签名算法名称

### PersistentTokenBasedRememberMeServices

该类也是作为`RememberMeServices`实现的一种，只是该类中需要额外的设置`PersistentTokenRepository`实例，用于token的持久化工作。

`PersistentTokenRepository`主要包含了两类的实现：

- `InMemoryTokenRepositoryImpl`该实现主要用于测试用

- `JdbcTokenRepositoryImpl`将token信息持久化到数据库，这样的好处在于，微服务场景下，可以共享token信息

## 程序配置

我们可以通过自定义的方式启用`remember-me`功能，具体配置代码如下:

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

        // 开启basic功能
        http.httpBasic();

        // 开始remember-me功能
        http.rememberMe((config) -> {
            config.key("test-remember-me");
        });
        http.authorizeRequests((registry) -> {
            registry.antMatchers("/**").authenticated();
        });
    }


}
```

> 当我们默认使用`rememberMe()`方法的时候，则使用的是`RememberMeConfigurer`对象进行配置，因此我们可以修改该类中的参数配置，以达到预期的效果。
