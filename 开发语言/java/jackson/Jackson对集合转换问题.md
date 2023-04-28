# Jackson处理XML转换集合无法指定名称问题

今日在公司负责公司支付业务模块，因为银行系统主要采用XML的报文格式，因此在不想做XML拼接的情况下，使用了Jackson作为xml报文与Bean之间的互相转换关系，但是在使用到集合形式的数据转化时，却和我期望的结果有比较大的差异，因此这边文章作为记录，希望可以帮到其他有需要的小伙伴。

## 依赖以及基础环境

我们还是从一个简单的demo来引入使用的一些基本操作吧, 一下为基础环境:

- JAVA 1.8

- Jackson 2.11.1

- maven

- idea

## XmlMapper的创建

**<mark>在Jackson操作xml最主要就是XmlMapper对象的使用，通过查看源码可以知道, 其实XmlMapper也是ObjectMapper的一个子类</mark>**，ObjectMapper这个类对于大家来说其实并不陌生，因为我们在操作JSON的时候，使用的就是这个类，

```java
public class XmlMapper extends ObjectMapper {
    ....
}
```

### XmlUtil

当我们在操作前，为Xml操作提供一个工具类，工具类中最主要就是对xml的操作，具体代码如下：

```java
package com.jackson;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.dataformat.xml.XmlMapper;

import java.util.Objects;

/**
 * Xml工具类
 */
public class XmlUtil {

    private XmlUtil() {
        throw new UnsupportedOperationException("不支持该操作");
    }

    private static final XmlMapper XML_MAPPER = new XmlMapper();

    static {
        // 美化输出
        XML_MAPPER.enable(SerializationFeature.INDENT_OUTPUT);
    }

    public static String toXmlString(Object obj) {
        if (Objects.isNull(obj)) {
            return null;
        }

        try {
            return XML_MAPPER.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("转换对象为xml失败", e);
        }
    }

    public static <T> T toJavaBean(String xml, Class<T> clazz) {
        if (Objects.isNull(xml) || Objects.isNull(clazz)) {
            return null;
        }

        try {
            return XML_MAPPER.readValue(xml, clazz);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("xml转换失败", e);
        }
    }
}

```

在这个工具类中有两个方法:

- **toXmlString** : 将java对象转换为xml字符创

- **toJavaBean**: 将xml转换为对应对象



## 常用注解

### @JacksonXmlProperty

该注解主要用来指定对象中属性在xml中对应节点的名称，主要有以下几个属性:

- **localName**: 用来指定节点名称，当为空是，和当前属性名称进行匹配

- **isAttribute**: 指定当前属性值是否为节点属性. 例如:<mark> `<key id = "2">`,</mark> 如果需要读取节点属性，则可以指定为true

### @JacksonXmlRootElement

该注解主要标记xml的根节点， 该注解可以与**@JacksonXmlProperty**一起使用，用于标记根节点下的不同路径。 属于基本与**@JacksonXmlProperty**一致

### @JacksonXmlElementWrapper

该节点可以标记结合，生成集合xml信息，在下面的实例中，会涉及到。

- **localName**: 上同

- **useWrapping**: 用于标记是否将集合元素进行包裹，在下面实例中有详细说明

## XML处理集合数据

### 问题描述

当我在与银行数据进行处理的时候，需要批量向不同账户进行转账，则需要在报文中生成相同元素的节点，具体格式如下：

```xml
<DETAIL>
    <ACCINFO>
        <PAYACC>111111</PAYACC>
        <RECACC>111112</PAYACC>
    </ACCINFO>
    <ACCINFO>
        <PAYACC>2222</PAYACC>
        <RECACC>22223</PAYACC>
    </ACCINFO>
</DETAIL>
```

这里这是举个例子，比如我需要生成以上的结构的数据。接下来我们就配置对应的代码

### 业务实体

根据以上的例子，这里我们只需要配置一个Bean实例即可，具体代码如下：

```java
@Data
@JacksonXmlRootElement(localName = "NODE")
public class PayDetail {

    @JacksonXmlProperty(localName = "ACCINFO")
    private List<AccInfo> accInfo;

    @Data
    public static class AccInfo {
        @JacksonXmlProperty(localName = "PAYACC")
        private String payAcc;
        @JacksonXmlProperty(localName = "RECACC")
        private String recAcc;
    }
}
```

这里是我创建的业务实体，这里面我希望accInfo属性能够解析成为列表，我们写一个客户端测试一下，看看输出结果怎样:

### 测试程序

```java
package com.jackson;

import com.jackson.entity.PayDetail;

import java.util.ArrayList;
import java.util.List;

public class XmlCollectionTest {
    public static void main(String[] args) {
        PayDetail payDetail = new PayDetail();
        List<PayDetail.AccInfo> accInfos = new ArrayList<>();
        accInfos.add(new PayDetail.AccInfo("111111", "111112"));
        accInfos.add(new PayDetail.AccInfo("2222", "22223"));

        payDetail.setAccInfo(accInfos);

        System.out.println(XmlUtil.toXmlString(payDetail));
    }
}

```

查看输出结果：

```xml
<NODE>
  <ACCINFO>
    <ACCINFO>
      <PAYACC>111111</PAYACC>
      <RECACC>111112</RECACC>
    </ACCINFO>
    <ACCINFO>
      <PAYACC>2222</PAYACC>
      <RECACC>22223</RECACC>
    </ACCINFO>
  </ACCINFO>
</NODE>


```

通过输出结果，我们发现一个问题，就是**ACCINFO**节点被输出了两次，这个其实不是我们所想要的，这时候就会用到上面针对集合的注解**@JacksonXmlElementWrapper**, 因此我们改造实体Bean

### @JacksonXmlElementWrapper

- **useWrapping**：该属性主要用来控制结合的包裹，我们看下在不同值的情况下的不同效果。

#### useWrapping = true

实体Bean的代码如下：

```java
package com.jackson.entity;

import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlElementWrapper;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlProperty;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlRootElement;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@JacksonXmlRootElement(localName = "NODE")
public class PayDetail {

    @JacksonXmlElementWrapper(useWrapping = true, localName = "ACCINFO")
    private List<AccInfo> accInfo;

    @Data
    @AllArgsConstructor
    public static class AccInfo {
        @JacksonXmlProperty(localName = "PAYACC")
        private String payAcc;
        @JacksonXmlProperty(localName = "RECACC")
        private String recAcc;
    }
}

```

输出结果如下：

```xml
<NODE>
  <ACCINFO>
    <accInfo>
      <PAYACC>111111</PAYACC>
      <RECACC>111112</RECACC>
    </accInfo>
    <accInfo>
      <PAYACC>2222</PAYACC>
      <RECACC>22223</RECACC>
    </accInfo>
  </ACCINFO>
</NODE>
```

通过以上输出结果可以得出一下结果：

- **useWrapping = true** : 表示了输出了结果的列表，并且需要将列表再用一个节点进行包裹

- **localName**: 只是指定了包裹的节点的名称

> 从上面的输出来看，和我们期望的结果相差还是很远，这种也不是我们所需要的这种格式

#### useWrapping = false

我们修改实体Bean代码如下：

```java
package com.jackson.entity;

import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlElementWrapper;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlProperty;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlRootElement;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@JacksonXmlRootElement(localName = "NODE")
public class PayDetail {

    @JacksonXmlElementWrapper(useWrapping = false, localName = "ACCINFO")
    private List<AccInfo> accInfo;

    @Data
    @AllArgsConstructor
    public static class AccInfo {
        @JacksonXmlProperty(localName = "PAYACC")
        private String payAcc;
        @JacksonXmlProperty(localName = "RECACC")
        private String recAcc;
    }
}

```

输出结果如下：

```xml
<NODE>
  <accInfo>
    <PAYACC>111111</PAYACC>
    <RECACC>111112</RECACC>
  </accInfo>
  <accInfo>
    <PAYACC>2222</PAYACC>
    <RECACC>22223</RECACC>
  </accInfo>
</NODE>
```

>  通过输出结果可以得知，当**useWrapping = false**的时候，**<mark>这个时候localName的配置其实是没有效果的</mark>**，这个时候和我们期望的结果很相似，但是节点的名称不相符合。



其实到了这里和我们期望的结果集就已经很接近了，但是节点的名称无法更改，此时我们应该想到是否可以通过**@JacksonXmlProperty**注解的方式来改变节点的名称。

### @JacksonXmlProperty

我们继续修改Bean实体的代码，这个时候通过该注解指定节点名称，看是否能够生效。具体代码如下：

```java
package com.jackson.entity;

import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlElementWrapper;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlProperty;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlRootElement;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@JacksonXmlRootElement(localName = "NODE")
public class PayDetail {

    @JacksonXmlElementWrapper(useWrapping = false)
    @JacksonXmlProperty(localName = "ACCINFO")
    private List<AccInfo> accInfo;

    @Data
    @AllArgsConstructor
    public static class AccInfo {
        @JacksonXmlProperty(localName = "PAYACC")
        private String payAcc;
        @JacksonXmlProperty(localName = "RECACC")
        private String recAcc;
    }
}

```

输出结果如下:

```xml
<NODE>
  <ACCINFO>
    <PAYACC>111111</PAYACC>
    <RECACC>111112</RECACC>
  </ACCINFO>
  <ACCINFO>
    <PAYACC>2222</PAYACC>
    <RECACC>22223</RECACC>
  </ACCINFO>
</NODE>

```

> 这个时候我们可以看到，这个时候我们预期结果一直

### 结论

> 当我们使用Jackson处理集合时，尤其是需要自定义xml格式的时候，这个时候每个注解不能单独的独立的来对待，对于这次遇到的这种情况，是需要---
> 
> - **@JacksonXmlElementWrapper(useWrapping = false)**
> 
> - **@JacksonXmlProperty(localName = "ACCINFO")**
> 
> 这两个注解的配合使用来解决。



## 常见问题

### 1. `com.fasterxml.jackson.databind.exc.UnrecognizedPropertyException`该怎么解决?

**<mark>该异常主要是因为xml中定义的属性比实体Bean的属性多时</mark>**，就会出现这样的异常信息，因为有时候我们不需要关系所有的xml属性信息，这个时候我们可以将该异常过掉，主要在**XmlMapper**中配置，实例代码如下:

```java
XML_MAPPER.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
```



以上就是Jackson在处理集合时候的相关基础知识，希望可以帮助到你。。
