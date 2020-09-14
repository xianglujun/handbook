# Spring国际化

## Spring国际化使用场景

- 普通国际化文案
- Bean Validation校验国际化文案
- Web站点页面渲染
- Web MVC错误消息提示

## Spring国际化接口

- 核心接口
  - MessageSource
- 主要概念
  - 文案模板编码(code)
  - 文案模板参数(args)
  - 区域(Locale)

## 层次性MessageSource

- Spring层次性接口回顾
  - HierarchicalBeanFactory
  - ApplicationContext
  - BeanDefinition
- Spring层次性国际化接口
  - HierarchicalMessageSource

## Java国际化标准实现

- 核心接口
  - 抽象实现 - ResourceBundle
  - Properties资源实现- PropertiesResourceBundle
  - 举例实现：ListResourceBundle

### Java国际化标准实现

- ResourceBundle核心特性
  - Key-Value设计
  - 层次性设计
  - 缓存设计
  - 字符编码控制 - java.util.ResourceBundle.Control(@since 1.6)
  - Control SPI扩展: java.util.spi.ResourceBundleControlProvider(`@since 1.8`)