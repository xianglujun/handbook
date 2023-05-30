# spring security 登出功能

在应用中，一般提供登录功能，也会提供登出接口。在spring security中，默认通过`GET /logout`接口完成登出操作，无序额外的代码实现。

## 理解登出结构

当在项目中引入了`spring-boot-starter-security`包后，并在配置上使用`@EnableWebSecurity`注解，则spring security默认会创建登出的处理逻辑，并且能够处理`GET /logout`和`POST /logout`请求。

这两种请求虽然都是可以，但是还是存在一定的小小区别:

- 当使用`GET /logout`地址时，能够为用户提供二次确认机制，展示是否确认登出的界面。

- 当`POST /logout`时，如果应用启用了`csrf`的功能，则需要提供可以使用的`CSFR token`信息，以完成`csrf`的验证。同时通过POST请求的方式，会有一下默认的行为：
  
  - 使`HTTP SESSION`无效，(`SecurityContextLogoutHandler`)
  
  - 清理`SecurityContextHolderStrategry`，(`SecurityContextLoutoutHandler`)
  
  - 清理`SecurityContextRepository`(`SecurityContextLoutoutHandler`)
  
  - 请求所有`remember-me authentication`信息(`TokenRememberMeServices` / `PersistentTokenRememberMeServices`)
  
  - 清理所有的`CSRF token`信息(`CsrfLogoutHandler`)
  
  - 触发`LogoutSuccessEvent`通知(`LogoutSuccessEventPublishingLogoutHandler`)

> 在以上的操作一旦完成之后，将会通过`LogoutSuccessHandler`跳转到`login?logout`界面

## 自定义登出地址

自从`LogoutFilter`出现在`AuthenticationFilter`之前时，对于`/logout`地址就不需要显示的进行`permit`操作。除非自定义登出的其他行为时，才需要显式的执行`permitAll`

### 修改登出url

```java
        // 配置登出逻辑
        http.logout(logout -> {
            // 配置登出url
            logout.logoutUrl("/user/logout");
        });
```

以上的配置则替换了默认的`/logout`请求地址，改为`/user/logout`请求地址。

> 这里有个点需要注意，当开启csrf功能的时候，则只能通过POST请求进行登出。

### 登出成功跳转地址

在spring security默认配置中，在登出成功后会跳转到`/login?logout`地址，也就是默认跳转到登录地址。我们可以通过修改地址信息，跳转到其他界面。这个时候设置的成功地址，就需要手动的设置`permitAll`方法。例如：我们成功后，跳转到`/usr/logout/index`地址，则有以下方式进行程序设置。

```java
        // 配置登出逻辑
        http.logout(logout -> {
            // 配置登出url
            logout.logoutUrl("/user/logout");
            logout.logoutSuccessUrl("/usr/logout/index").permitAll();
        });
```

或者通过一下方式设置：

```java
        http.authorizeRequests((registry) -> {
            registry.antMatchers("/usr/logout/index").permitAll();
            registry.antMatchers("/**").authenticated();
        });
```

## 自定义清理行为

在登出成功之后，除了以上系统默认行为之外，还有`addLogoutHandler()`方法自定义行为，例如：清理固定cookie信息，则代码如下:

```java
        // 配置登出逻辑
        http.logout(logout -> {
            // 配置登出url
            logout.logoutUrl("/user/logout");
            logout.logoutSuccessUrl("/usr/logout/index").permitAll();
            // 清楚指定cookie
            logout.addLogoutHandler(new CookieClearingLogoutHandler("cookie-name"));
        });
```

或者spring security也提供了简便的使用方式，

```java
logout.deleteCookies("cookie-name");
```

## Clear-Site-Data配置

[Clear-Site-Data](https://w3c.github.io/webappsec-clear-site-data/)是W3C中的标准，是指代用户在登出的时候，清除用户保存在客户端的缓存数据，以放置敏感数据的泄露。具体实现就是在响应response中加入`clear-site-data`的header信息，并告知浏览器需要清除数据的类型。

在spring security中，也提供了这样的`LogoutHandler`的实现，具体配置如下：

```java
 // clear-site-data配置
 logout.addLogoutHandler(new HeaderWriterLogoutHandler(new ClearSiteDataHeaderWriter(ClearSiteDataHeaderWriter.Directive.ALL)));
```

> 这里需要强调一点，默认情况下，`ClearSiteDataHeaderWriter`默认只针对安全的请求有效，例如`https`，因为在`RequestMatcher`中判断满足条件为`request.isSecure()`的结果为`true`。因此，对于http链接是不生效的。

## 自定义登出成功Handler

在上面实现中，都是通过security 默认的配置，在登出成功之后，重定向到指定连接地址。这其实也是通过`SimpleUrlLogoutSuccessHandler`的实现。

```java
http
    .logout((logout) -> logout.logoutSuccessHandler(new HttpStatusReturningLogoutSuccessHandler()))
```

> 以上的配置需要小心，设置之后，会覆盖掉默认的配置Handler信息，也就是说，将不能实现登出成功后，跳转到指定地址。

## 自定义登出实现

```java
SecurityContextLogoutHandler logoutHandler = new SecurityContextLogoutHandler();

@PostMapping("/my/logout")
public String performLogout(Authentication authentication, HttpServletRequest request, HttpServletResponse response) {
    // .. perform logout
    this.logoutHandler.doLogout(request, response, authentication);
    return "redirect:/home";
}
```

在自定义登出实现时，则需要自己调用`logoutHandler.doLogout()`的方法，达到和spring security相同的目的。

## 参考文档

1. [Handling Logouts :: Spring Security](https://docs.spring.io/spring-security/reference/servlet/authentication/logout.html)
