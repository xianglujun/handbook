# Hive SQL

## Hive SerDe

Hive SerDe：Serializer and Deserializer

SerDe用于序列化和反序列化，构建在数据存储和执行引擎之间，对两者实现解耦。

Hive同各国`ROW FORMAT DELIMITED`以及`SERDE`进行内容的读写。

```sql
row_format
: DELIMITED
    [FIELDS TERMINATED BY char [ESCAPED BY char]]
    [COLLECTION ITEMS TERMINATED BY char]
    [MAP KEYS TERMINATED BY char]
    [LINES TERMINATED BY char]
:SERDE serde_name [WITH SERDEPROPERTIES (property_name=property_value...)]
```

### Hive 正则匹配

```sql
create table logtb1(
    host string,
    identity string,
    s_u string,
    time string,
    request string,
    referer string,
    agent string
)
row format serde 'org.apache.hadoop.hive.serde2.RegexSerDe'
with serdeproperties(
    "input.regex" = "([^ ]*)\s+([^ ]*)\s+([^ ]*)\s+\\[(.*)\\]\s+\"(.*)\”\s+([-|[0-9]]*)\s+(.*)"
) stored as textfile;
```

数据格式如下

```tex
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
192.168.57.4 - - [29/Feb/2016:18:14:35+0800] "GET[29/Feb/2016:18:14:36+08001/tomcat.css HTTP/1.1” 304 -
```

## Hive函数

### 内置运算符

#### 关系运算符(where字句中)

| 运算符           | 类型     | 说明                                                                                     |
| ------------- | ------ | -------------------------------------------------------------------------------------- |
| A = B         | 所有原始类型 | 如果A等于B, 则返回true, 否则返回false                                                             |
| A == B        | 无      | 失败，因为无效的语法，SQL使用"="表示相等关系                                                              |
| A <> B        | 所有原始类型 | 如果A不等于B返回true, 否则返回false。如果A或B值为NULL， 则返回NULL                                          |
| A < B         | 所有原始类型 | 如果A小于B返回true, 否则返回false.如果A或B值为NULL, 则返回NULL                                           |
| A <= B        | 所有原始类型 | 如果A小于等于B返回true, 否则返回false.如果A或B值为NULL, 则返回NULL                                         |
| A > B         | 所有原始类型 | 如果A大于B返回true, 否则返回false.如果A或B值为NULL, 则返回NULL                                           |
| A >= B        | 所有原始类型 | 如果A大于等于B返回true, 否则返回false.如果A或B值为NULL, 则返回NULL                                         |
| A IS NULL     | 所有类型   | 如果A的值为NULL, 返回true，否则返回false                                                           |
| A IS NOT NULL | 所有类型   | 如果A的值不为NULL, 则返回true, 否则返回false                                                        |
| A LIKE B      | 字符串    | 如果A或B值为NULL, 结果返回NULL。字符串A与B通过sql进行匹配，如果符合返回true, 否则返回false. 其中"_"表示匹配一个字符，"%"表示匹配多个字符 |
| A RLIKE B     | 字符串    | 如果A或B值为NULL, 结果返回NULL。字符串A与B通过JAVA进行匹配，如果相符则返回true, 否则返回false.                         |
| A REGEXP B    | 字符串    | 与RLIKE相同。使用正则表达式匹配                                                                     |

#### 算术运算符

| 运算符    | 类型     | 说明                                                                 |
| ------ | ------ | ------------------------------------------------------------------ |
| A + B  | 所有数字类型 | A和B相加，结果与操作数同类型                                                    |
| A - B  | 所有数字类型 | A和B相减，结果与操作数同类型                                                    |
| A * B  | 所有数字类型 | A和B相乘，结果与操作值有共同类型。如果乘法造成溢出，将选择更高的类型                                |
| A / B  | 所有数字类型 | A和B相除，结果是一个double类型的结果                                             |
| A % B  | 所有数字类型 | A除以B余数与操作数值有共同类型                                                   |
| A & B  | 所有数字类型 | 运算符查看两个参数的二进制表示法的值，并执行按位与操作。两个表达式的相同位为1时，结果位1；否则为0                 |
| A \| B | 所有数字类型 | 运算符查看两个参数的二进制表示法的值，并进行按位或运算。相同位只要有一个1，则结果为1，否则为0                   |
| A ^ B  | 所有数字类型 | 运算符查看两个参数的二进制表达法的值，并执行按位异或操作。当且仅当只有一个表达式的某位上为1时，结果的该位才为1.否则结果的该位为0 |
| ~A     | 所有数字类型 | 对一个表达式执行按位"非"取反操作                                                  |

#### 逻辑运算符

| 运算符     | 类型  | 说明                                                           |
| ------- | --- | ------------------------------------------------------------ |
| A AND B | 布尔值 | A和B同时为true是，结果为true, 否则为false                                |
| A && B  | 布尔值 | 与AND相同                                                       |
| A OR B  | 布尔值 | A或B 中任何一个结果为true， 则结果为true, 否则为false. 如果A和B同时为NULL, 则结果为NULL |
| A \| B  | 布尔值 | 与OR相同                                                        |
| NOT A   | 布尔值 | 如果A为NULL或结果为false时，返回true. 否则返回false                         |
| !A      | 布尔值 | 与NOT相同                                                       |

### 内置函数

#### 复杂类型函数

| 函数     | 类型                             | 说明                                   |
| ------ | ------------------------------ | ------------------------------------ |
| map    | (key1, value2, key2, value2..) | 通过指定的键/值对，创建一个map                    |
| struct | (val1, val2, val3...)          | 通过指定的字段值，创建一个结构。结构字段名称将COL1, COL2... |
| array  | (val1, val2, val3...)          | 通过指定的元素，创建一个数组                       |

#### 对复杂类型函数操作

| 函数      | 类型              | 说明                       |
| ------- | --------------- | ------------------------ |
| A[n]    | A是一个数组，n是一个整型   | 返回数组A中的第n个元素，第一个元素下标从0开始 |
| M[]key] | M是Map<K,V>，关键K型 | 返回Map中键key对应的值           |
| S.x     | S为struct类型      | 返回结构S中的x属性的值             |
|         |                 |                          |

#### 数学函数

| 返回类型       | 函数                                                 | 说明                       |
| ---------- | -------------------------------------------------- | ------------------------ |
| BIGINT     | round(double a)                                    | 四舍五入                     |
| DOUBLE     | round(double a,int d)                              | 小数部分d位之后数字四舍五入           |
| BIGINT     | floor(double a)                                    | 对给定的数字A进行向下取整最接近的整数      |
| BIGINT     | ceil(double, a), ceiling(double a)                 | 将给定数字a向上取整               |
| double     | rand(), rand(int seed)                             | 返回大于或等于0且小于1的平均分布随机数。    |
| double     | exp(double a)                                      | 返回e的a次方                  |
| double     | ln(double a)                                       | 返回给定数值的自然对数              |
| double     | log10(double a)                                    | 返回给定数值的以10为底自然对数         |
| double     | log2(double a)                                     | 返回给定数值的以2为底自然对数          |
| double     | log(double base, double a)                         | 返回给定数值a的以base为底自然对数      |
| double     | pow(double a, double p), power(double a, double p) | 返回数字a的p次幂的结果             |
| double     | sqrt(double a)                                     | 返回数值的平方根                 |
| string     | bing(bigint a)                                     | 返回二进制格式                  |
| string     | hex(bigint a) hex(string a)                        | 将证书或字符串转换为十六进制字符串        |
| string     | unhex(string a)                                    | 将十六进制字符串转换为由数字表示的字符串     |
| string     | conv(bigint num, int from_base, int to_base)       | 将指定数值，由原来的度量体系转换为指定的试题体系 |
| double     | abs(double a)                                      | 取绝对值                     |
| int double | pmod(int am, int b), pmod(double a, double b)      | 返回a除以b的余数的绝对值            |
| double     | sin(double a)                                      | 返回给定角度的正弦值               |

#### 搜集函数

| 返回类型 | 函数                    | 说明           |
| ---- | --------------------- | ------------ |
| int  | size(Map<key, value>) | 返回map类型的元素数量 |
| int  | site(Array<T>)        | 返回数组类型的元素数量  |

#### 类型转换函数

> INT -> BIGINT自动转换， BIGINT -> INT需要强制转换类型

| 返回类型    | 函数                   | 说明    |
| ------- | -------------------- | ----- |
| 指定 type | cast(expr as <type>) | 类型转换。 |

#### 日期函数

| 返回类型   | 函数                                              | 说明                                                                                                          |
| ------ | ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| string | from_unixtime(bigint unixtime[, string format]) | UNIX_TIMESTAMP参数表示返回一个值"yyyy-MM-dd HH:mm:ss"或"yyyyMMddHHmmss.uuuuuu"格式，这取决于是否在一个字符串或数字语境中使用的功能，该值表示当前的时区的时间 |
| bigint | unix_timestamp()                                | 如果不带参数的调用，返回一个unix时间戳，从1970年开始计算                                                                            |
| bigint | unix_timestamp(string date)                     | 指定日期参数调用UNIX_TIMESTAMP(), 返回从1970年到指定时间的秒数                                                                  |
| bigint | unix_timestamp(string date, string pattern)     | 指定时间输入格式，返回从1970到指定日期的秒数                                                                                    |
| string | to_date(string timestamp)                       | 返回时间中的年月日                                                                                                   |
| string | to_dates(string date)                           | 给定一个日期date, 返回一个天数                                                                                          |
| int    | year(string date)                               | 返回指定时间的年份                                                                                                   |
| int    | month(string date)                              | 返回指定时间的月份                                                                                                   |
| int    | day(string date)                                | 返回指定时间的日期                                                                                                   |

#### 条件函数

| 返回  | 函数                                                        | 说明                                   |
| --- | --------------------------------------------------------- | ------------------------------------ |
| T   | if(boolean testCondition, T valueTrue, T valueFaseOrNull) | 判断是否满足条件，如果满足返回一个值，如果不满足则返回另外一个值     |
| T   | COALESCE(T v1, T v2...)                                   | 返回一组数据中，第一个不为NULL的值，如果均为NULL, 返回NULL |
| T   | CASE a WHEN  b THEN c [WHEN  d THEN e]*[ELSE f] END       | 当a=b时，返回c; 当a=d时，返回e, 否则返回f          |
| T   | CASE WHEN a THEN b [WHEN c THEN d] *[ELSE e] END          | 当值为a时返回b, 当值为c时返回d, 否则返回e            |

### 自定义函数

自定义函数包含三种UDF, UDAF, UDTF

- UDF(User-Defined-Function)：一进一出

- UDAF(User-Defined Aggregation Function)：聚集函数，多进一出

- UDTF(User-Defined Table-Generating Functions)： 一进多处

> 使用方式：在HIVE会话中add自定义函数jar文件，然后创建function继而使用函数

#### 自定义函数的步骤(UDF)

- UDF函数可以直接应用于select语句，对查询结构做格式化处理后，再输出内容

- 编写UDF函数的时候需要注意以下几点
  
  - 自定义UDF需要继承`org.apache.hadoop.hive.ql.UDF`
  
  - 需要实现evaluate函数，evaluate函数支持重载

以下实现了一个简单的 脱敏工具类，值展示文本的第一个字符即可：

```java
package org.hadoop.hive.learn.udf;

import org.apache.hadoop.hive.ql.exec.UDF;

/**
 * 只展示第一个字符的操作
 */
public class SensitiveFunc extends UDF {
    public String evaluate(String str) {
        if (str == null || str.length() <= 1) {
            return str;
        }

        int length = str.length();
        String res = str.substring(0,1);

        StringBuilder sb = new StringBuilder(res);
        for (int i = 1; i < length; i++) {
            sb.append("*");
        }
        return sb.toString();
    }

    public static void main(String[] args) {
        SensitiveFunc sensitiveFunc = new SensitiveFunc();
        String res = sensitiveFunc.evaluate("你好劜");
        System.out.println(res);
    }
}

```

- 将以上代码打包为jar包，并上传到hive所在服务器中。

- 进入hive客户端，添加jar包
  
  ```shell
  add jar /root/hive-learn-1.0-SNAPSHOT.jar
  ```

- 创建临时函数：
  
  ```sql
  create temporary function tuomin as 'org.hadoop.hive.learn.udf.SensitiveFunc'
  ```

在创建完成以上的函数之后，就可以使用这个函数了：

![](../../../assets/2024-12-16-14-09-11-image.png)

我们可以看到自己定义的脱敏函数已经完成啦~~~~

> 这样的缺点是，因为创建的时temporary的函数，因此在hive客户端关闭之后，这个函数就无法再次被找到。

在以上的步骤中，我们也可以将jar包上传的hdfs上，然后通过一下命令使用:

```sql
create temporary function tumin as 'org.hadoop.hive.learn.udf.SensitiveFunc' using jar 'hdfs://node1:8020/path/tuomin.jar'
```

##### 创建永久函数

永久函数因为需要使用到jar, 这个时候我们可以将jar包上传到hdfs中，然后创建永久函数，当在任何机器上使用函数时，都可以直接从hdfs上加载jar包并使用，具体步骤如下:

```shell
# 创建目录
hdfs dfs -mkdir -p /lib/hive/udf

# 上传jar包
hdfs dfs -put /root/hive-learn-1.0-SNAPSHOT.jar /lib/hive/udf/hive-sql-func.jar
```

然后有了以上的jar包之后，则在Hive客户端，创建永久的函数:

```sql
hive> create function sens as 'org.hadoop.hive.learn.udf.SensitiveFunc' using jar 'hdfs://mycluster/lib/hive/udf/hive-sql-func.jar'
```

有了这个函数之后，我就可以在任何地方使用这个函数了：

![](../../../assets/2024-12-16-14-32-32-image.png)

一下为在hive的客户端工具查询的情况：

![](../../../assets/2024-12-16-14-34-48-image.png)

##### 函数的维护

```sql
#删除函数名
drop function sens
```

#### UDAF自定义集函数

> 多行进一行出，如sum(), min()，用在group by时

##### 实现步骤如下

1. 必须继承
   
   - `org.apache.hadoop.hive.ql.exec.UDAF`(函数类继承)
   
   - `org.apache.hadoop.hive.ql.exec.UDAFEvaluator`(内部类 Evaluator实现UDAFEvaluator接口)

2. Evaluator需要实现`init`, `iterate`,`terminatePartial`, `merge`, `terminate`这几个函数
   
   - init()：类似于构造函数，用于UDAF初始化
   
   - iterate()：接受传入的参数，并进行内部的轮转，返回boolean
   
   - termiatePartial()：无参数，其为iterate函数轮转结束后，返回轮转数据，类似于hadoop的Combiner
   
   - merge()：接受terminatePartial的返回结果，进行数据merge操作，其返回类型为boolean
   
   - terminate()：返回最终的聚集函数结果


