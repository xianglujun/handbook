# Security Authentication 架构简介

## 类说明

在Spring Security中，包含了很多的类，Authentication主要管理授权以及授权后用户权限等信息，主要类包含以下几种：

- `SecurityContextHolder`: 该类主要保存已经授权用户的详情信息

- `SecurityContext`：从`SecurityContextHolder`中获取，该类中主要包含了当前已授权用户的授权信息。包括了用户基本信息，权限、角色等信息。

- `Authentication`: 该对象可以用作`AuthenticationManager`的输入，以用作用户授权的信息依据。或者已授权的当前用户信息。

- `GrantedAuthority`：已授权主体的权限

- `AuthenticationManager`：该类为一个API类型，用于定义Spring Security中的`Filter`如何作用于授权信息(`Authentication`)

- `ProviderManager`: 对于`AuthenticationManager`的一种通用实现

- `AuthenticationProvider`: 该类主要被`ProviderManager`使用，用于指定类型授权

- `Request Credential With AuthenticationEntryPoint`：主要用于对于客户段请求的处理，(例如：跳转到一个日志界面，或者在response中返回`WWW-Authenticate`)

- `AbstractAuthenticationProcessingFilter`：是基于Filter的一种实现，将独立的任务组装成一个整体。

## SecurityContextHolder

该类主要用于创建SecurityContext对象，在该类中，包含了几种创建`SecurityContext`策略，具体策略如下：

- `MODE_PRE_INITIALIZED`：该策略则需要自己实现，通过调用`setContextHolderStrategy`设置自定义的创建策略

- `MODE_THREADLOCAL`：该策略对应着`ThreadLocalSecurityContextHolderStrategy`实现，盖实现中通过`ThreadLocal`的方式共享`SecurityContext`对象。

- `MODE_INHERITABLETHREADLOCAL`：该策略对应着`InheritableThreadLocalSecurityContextHolderStrategy`的实现，只是与`MODE_THREADLOCAL`不同，该策略实现中使用了`InheritableThreadLocal`用于共享`SecurityContext`实现，因此在创建子线程的时候，也会讲对应的共享信息一同共享给子线程，达到共享的目的。

- `MODE_GLOBAL`：该策略主要是全局共享`SecurityContext`，通过`GlobalSecurityContextHolderStrategy`实现，这种比较适合client的工作模式，全局唯一`SecurityContext`.

## SecurityContext

该类通过`SecurityContextHolder`进行创建，并通过不同的策略实现是否共享。在SecurityContext中，包含了授权的基本信息(`Authentication`)

## Authentication

该类主要作用有两个：

- 作为`AuthenticationManager`的输入，提供认证的凭证信息(例如：用户名和密码). 当在这种场景时, `isAuthenticated()`方法返回false.

- 代表了当前已经授权的用户，可以通过`SecurityContext`获取当前已经授权的用户信息。

在`Authentication`中，主要包含了一下信息：

- `principal`：代表了用户。当使用用户名/密码模式授权的时候，该值始终为`UseDetails`对象

- `credentials`：通常者代表了密码，该值在用户授权完成之后会清空，以放置密码泄露

- `authorities`：授权通过的用户所具有的权限。`GrantedAuthority`是用户的高级别的权限。例如：角色和数据范围等。

### GrantedAuthority

该对象可以通过`Authentication.getAuthorities()`, 一般通过该方法获取到的是一个列表。在角色模式(roles)中，我们获取到的数据大概类似于：`ROLE_ADMINISTRATOR` or `ROLE_HR_SUPERVISOR`。这些信息最后都可以配置到对应的类，方法或者对象实体上。在web请求中，spring security拦截请求，并希望在权限中出现对应的权限信息。

> 当我们使用用户名/密码方式授权的时候，权限信息则通过`UseDetailsService`来加载。

## AuthenticationManager

该类定义了Spring Security的Filter如何执行`Authentication`信息，该类会返回`Authentication`信息，并最终设置到`SecurityContextHolder`上，如果没有使用Spring Security的Filter实例，可以直接向`SecurityContextHolder`上设置。

我们可以自由实现`AuathenticationManager`, 但是最通用的还是`ProviderManager`类

### ProviderManager

该类持有了AuthenticationProvider示例的列表，在处理`Authentication`信息的时候，每个类都有机会来处理，最终结果可以成功，失败或者不予以处理。当为不予以处理的时候，能够让下游的`AuthenticationProvider`处理。当所有的`Provider`都不能处理Authentication信息时，将会抛出`ProviderNotFoundException`, 用来表示没有`Provider`能够处理当前的`Authentication`类型的信息。

![](../../../../assets/2023-05-25-16-45-06-providermanager.png)

> 每个AuthenticationProvider都可能处理一个或者多个类型的`Authentication`信息。

当然ProviderManager还能够设置一个父`ProviderManager`对象，用以在没有`AuthenticationProvider`可以处理`Authentication`信息的时候，可以交由父`AuthenticationProvider`处理，只是一般来说，一个父实现一般也是`ProviderManager`对象实例。

![](../../../../assets/2023-05-25-16-50-41-providermanager-parent.png)

当然，同时也存在多个`ProviderManager`共享一个父`ProviderManager`的情况，主要是因为存在多个`SecurityFilterChain`对象，一般用于同一个系统有不同的认证机制导致的。

![](../../../../assets/2023-05-25-16-52-33-providermanagers-parent.png)

默认情况下，在用户授权完成之后，会将用户登录密码或者凭证信息情况，以防止信息泄露。这将会导致当前用户再次授权的时候会出现问题，这个时候有几种方法：

- 复制当前的授权对象信息另外储存

- 关闭自动清空凭证的配置。`eraseCredentialsAfterAuthentication = false`

### AuthenticationProvider

该类主要针对`ProviderManager`使用，用于处理不同类型的认知。例如`DaoAuthenticationProvider`用于用户名和密码的授权认证。

## AuthenticationEntryPoint

在一般情况下，客户端在请求资源的时候，需要携带凭证信息以便验证身份。这个时候Spring Security不需要在`response`中返回`header`等信息要求客户端传入凭证信息。

但是有些情况客户端在请求需要授权的资源的时候，没有携带凭证信息，这个时候就可以通过`AuthenticationEntryPoint`来实现，可以跳转到一个登录界面、或者在header中响应`WWW-Authenticate`或者其他的行为。

## AbstractAuthenticationProcessingFilter

![](../../../../assets/2023-05-25-17-45-17-abstractauthenticationprocessingfilter.png)

在以上的图像中，每个步骤的功能如下：

- 当客户端发送凭证信息到服务端时，`AbstractAuthenticationProcessingFilter`负责从请求`request`中获取必要参数，并创建Authentication对象。

- 当获取到`Authentication`对象之后，将该对象发送到`AuthenticationManager`进行授权

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
