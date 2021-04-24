# Mapping以及数据类型

## 什么是Mapping

- Mapping类似数据库中schema的定义
  - 定义索引中的字段的名称
  - 定义字段的数据类型
  - 字段，倒排索引的相关配置
- Mapping 会把JSON文档映射成Lucene所需要的扁平格式
- 一个Mapping属于一个索引的Type
  - 每个文档都属于一个Type
  - 一个Type有一个Mapping定义
  - 7.0开始，不需要在Mapping定义中指定Type信息



## 字段数据类型

- 简单类型
  - Text / Keywork
  - Date
  - Integer / Floating
  - Boolean
  - IPv4 & IPv4
- 复杂类型 - 对象和嵌套对象
  - 对象类型 / 嵌套类型
- 特殊类型
  - geo_point & geo_shape / percolator

## Dynamic Mapping

- 在写入文档时候，如果索引不存在，会自动创建索引
- Dynamic Mapping机制，使得无需手动定义Mappings， ES会根据文档信息，推算出字段的类型
- 但是有时候会推算的不对，例如`地理位置信息`
- 当类型如果设置的不对时，会导致一些功能无法正常运行。



### 类型自定识别

| JSON类型 | ES类型                                                       |
| -------- | ------------------------------------------------------------ |
| 字符串   | 1.  匹配日期格式，设置成Date<br />2. 配置数字设置为float或者long, 该项默认关闭<br />3. 设置为Text, 并增加keyword子字段 |
| 布尔值   | boolean                                                      |
| 浮点数   | float                                                        |
| 整数     | long                                                         |
| 对象     | Object                                                       |
| 数组     | 由第一个非空数值的类型所决定                                 |
| 空值     | 忽略                                                         |

### 示例

```http
# 写入文档
PUT mapping_test/_doc/1
{
  "firstName": "Chan",
  "lastName": "Jackie",
  "loginDate": "2020-12-20T23:50:59.103Z"
}

# 查看mapping
GET mapping_test/_mapping

# 删除索引
DELETE mapping_test

# 写入文档
PUT mapping_test/_doc/1
{
  "uid": "123",
  "isVip": false,
  "isAdmin": "true",
  "age": 19,
  "heigh": 180
}

# 查看mapping
GET mapping_test/_mapping
```



## 能否更改Mapping的字段类型

- 分为两种情况
  - 新增加字段
    - Dynamic 设置为`true`时，一旦有新增的字段文档写入, Mapping同事被更新
    - Dynamic 设置为`false`时，Mapping不会被更新，新增字段的数据无法被索引，但是信息会在`_source`中
    - Dynamic设置为`Strict`， 导致文档写入失败
  - 对已有字段，一旦已经有数据写入，就不再支持修改字段定义
    - Lucene实现的倒排索引，一旦生成后，就不允许修改
  - 如果希望改变字段类型，必须`Reindex API`, 重建索引
- 原因
  - 如果修改字段的数据类型，会导致已被索引的属于无法被搜索
  - 但是如果是新增加的新字段，就不会影响



### 控制Dynamic Mappling

|               | true | false | strict |
| ------------- | ---- | ----- | ------ |
| 文档可索引    | YES  | YES   | NO     |
| 字段可索引    | YES  | NO    | NO     |
| Mapping被更新 | YES  | NO    | NO     |

- 当dynamic被设置成false时候，存在新增字段的数据写入，该数据可以被索引，但是新增字段被丢弃
- 当设置成Strict模式的时候，数据写入直接出错

```http
PUT movies
{
	"mappings": {
		"_doc": {
			"dynamic": "false"
		}
	}
}
```

#### 使用实例

```http
# 默认Mapping支持dynamic, 写入的文档中加入新的字段
PUT dynamic_mapping_test/_doc/1
{
  "newField": "someValue"
}

POST dynamic_mapping_test/_search
{
  "query": {
    "match": {
      "newField": "someValue"
    }
  }
}

# 修改dynamic为false
PUT dynamic_mapping_test/_mapping
{
  "dynamic": false
}

# 新增authorField
PUT dynamic_mapping_test/_doc/10
{
  "authorField": "someValue"
}

GET dynamic_mapping_test/_mapping

# 新字段不能被索引，因为dynamic设置为false
POST dynamic_mapping_test/_search
{
  "query": {
    "match": {
      "authorField": "someValue"
    }
  }
}

# 修改为strict
PUT dynamic_mapping_test/_mapping
{
  "dynamic": "strict"
}

# 新增lastField
PUT dynamic_mapping_test/_doc/10
{
  "lastField": "someValue"
}

DELETE dynamic_mapping_test
```

