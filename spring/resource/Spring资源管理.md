# Srping 资源管理

## 引入动机

- 为什么Spring不适用Java标准资源管理，而选择重新发明轮子
  - Java标准资源管理很强大，然而扩展复杂，资源存储方式并不统一
  - Spring要自立门户
  - Spring `抄`， `超`, `潮`

## Java标准资源管理

- Java标准资源定位

| 职责         | 说明                                                         |
| ------------ | ------------------------------------------------------------ |
| 面向资源     | 文件系统，artifactory(jar, war, ear文件)以及远程资源         |
| API整合      | java.lang.ClassLoader#getResource, java.io.File 或 java.net.URL |
| 资源定位     | java.net.URL或java.net.URI                                   |
| 面向流式存储 | java.net.URLConnection                                       |
| 协议扩展     | java.net.URLStreamHandler或java.net.URLStreamHandlerFactory  |

### Java URL协议扩展

- 基于`java.net.URLStreamHandlerFactory`
- 基于`java.net.URLStreamHandler`

### 基于`java.net.URLStreamHandler`扩展协议

- JDK 1.8内建协议实现

  | 协议   | 实现类                              |
  | ------ | ----------------------------------- |
  | ftp    | sum.net.www.protoco.ftp.Handler     |
  | http   | sun.net.www.protocol.http.Handler   |
  | https  | sun.net.www.protocol.https.Handler  |
  | jar    | sun.net.www.protocol.jar.Handler    |
  | mailto | sun.net.www.protocol.mailto.Handler |
  | netdoc | sun.net.www.protocol.netdoc.Handler |
  | file   | sun.net.www.protocol.file.Handler   |

- 实现类名必须为`Handler`

  | 实现类命名规则 | 说明                                                         |
  | -------------- | ------------------------------------------------------------ |
  | 默认           | sun.net.www.protocol.${protocol}.Handler                     |
  | 自定义         | 通过Java Properties java.protocol.handler.pkgs 指定实现类包名，现类名必须为`Handler`. 如果存在多个包名指定，通过分隔符`|` |

  