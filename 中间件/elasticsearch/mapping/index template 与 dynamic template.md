# index template 与 dynamic template

## index template

- 设定Mappings和Settings, 并按照一定的规则，自动匹配到新创建的索引上
  - 模板仅在一个索引被新创建时，才会产生作用。修改模板不会影响已经创建的索引
  - 可以设定多个索引模板，这些设置会被`merge`到一个索引中
  - 可以指定`order`的值，用于控制`merge`过程。



### 工作方式

- 当索引被创建时
  - 应用ES默认的`settings`和`mappings`
  - 应用`order`数值低的 Index Template中的设定
  - 应用`order`高的index template 中的设定，之前的设定会被覆盖
  - 应用创建索引时，用户所指定的`Settings`和`Mappings`， 会覆盖模板中的对应设定

### 实例

```http
# template
PUT tmp_test/_doc/1
{
  "number": "2",
  "someDate": "2021/04/02"
}

GET tmp_test/_mapping

# 创建默认的template
PUT _template/temp_def
{
  "index_patterns": ["tmp_*"],
  "order": 0,
  "version": 1,
  "settings": {
    "number_of_replicas": 1,
    "number_of_shards": 1
  }
}

GET /_template/temp_def
GET /_template/temp*

# 写入新数据
PUT tmp_tmp_test/_doc/1
{
  "number": "1",
  "someDate": "2020/04/03"
}

GET tmp_tmp_test/_mapping
GET tmp_tmp_test/_settings
```

## Dynamic Template

- 根据ES识别的数据类型，结合字段名称，自定设定字段类型
  - 所有的字符串类型都被设定成Keyword, 或者关闭 keyword字段
  - `is`开头的字符段都被设置成为boolean
  - `long_`开头的都被设置成为long类型

### 定义

- Dynamic Template 是定义在所以的`Mapping`中
- 为Template定义一个名称
- 匹配一组规则
- 为匹配到的字段设置`Mapping`

```json
PUT my_dy_temp
{
    "mappings": {
        "dynamic_templates": {
            "path_match": "name,*",
            "path_unmatch": "*.middle",
            "mapping" : {
                "type" : "text",
                "copy_to": "full_name"
            }
        }
    }
}
```

### 实例

```json
# dynamic template
PUT cus_index/_doc/1
{
  "firstName": "Li",
  "isVip":"true"
}

GET cus_index/_mapping
DELETE cus_index

PUT cus_index
{
  "mappings": {
    "dynamic_templates": [
      {
        "full_name": {
          "path_match": "name.*",
          "path_unmatch": "*.middle",
          "mapping" :{
            "type": "text",
            "copy_to": "full_name"
          }
        }
      }
      ]
  }
}

PUT cus_index/_doc/1
{
  "name": {
    "firstName": "Li",
    "middle":"Zhong",
    "lastName": "JunJuN"
  }
}

```

