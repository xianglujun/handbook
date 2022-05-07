# 定义mappling

## 自定义Mapping的一些建议

- 可以参考API手册，纯手写
- 为了减少输入的工作量，减少出错概率，可以参照一下步骤：
  - 创建一个临时的index, 写入一些样本数据
  - 通过访问Mapping API获得该临时文件的动态mapping定义
  - 通过对临时index文件进行修改，然后再次使用该mapping配置创建索引
  - 删除临时索引



## 控制字段是否被索引

- index : 控制当前字段是否被索引，
  - 默认为`true`, 设置成`false`后，该字段不会创建索引
  - 不创建索引的字段不能被搜索

```http
PUT test
{
	"mappings": {
		"properties": {
			"name": {
				"type": "text",
				"index": false
			}
		}
	}
}

DELETE users
PUT users 
{
  "mappings": {
    "properties": {
      "firstName": {
        "type": "text"
      }, "lastName": {
        "type": "text"
      },
      "mobile": {
        "type": "text",
        "index": false
      }
    }
  }
}

# 加入新数据
PUT users/_doc/1
{
  "firstName": "Li",
  "lastName": "mingming",
  "mobile": "12345678"
}

# 根据电话号码查询
POST /users/_search
{
  "query": {
    "match": {
      "mobile": "12345678"
    }
  }
}
```

当查询没有索引的字段时，将抛出如下错误

```json
{
  "error" : {
    "root_cause" : [
      {
        "type" : "query_shard_exception",
        "reason" : "failed to create query: Cannot search on field [mobile] since it is not indexed.",
        "index_uuid" : "3Cjf1anJTD2gr62nscG7rQ",
        "index" : "users"
      }
    ],
    "type" : "search_phase_execution_exception",
    "reason" : "all shards failed",
    "phase" : "query",
    "grouped" : true,
    "failed_shards" : [
      {
        "shard" : 0,
        "index" : "users",
        "node" : "tC0IlsnSR7m2WEb30xd3eA",
        "reason" : {
          "type" : "query_shard_exception",
          "reason" : "failed to create query: Cannot search on field [mobile] since it is not indexed.",
          "index_uuid" : "3Cjf1anJTD2gr62nscG7rQ",
          "index" : "users",
          "caused_by" : {
            "type" : "illegal_argument_exception",
            "reason" : "Cannot search on field [mobile] since it is not indexed."
          }
        }
      }
    ]
  },
  "status" : 400
}

```



## Index Options

- 四种不同级别的Index Options配置
  - docs - 记录doc id
  - freqs - 记录doc id 和 term frequencies
  - positions - 记录doc id / term frequencies / term position
  - offsets - doc id / term frequencies / term position /character offects
- Text 类型默认记录postions, 其他默认记录docs
- 记录内存越多，占用内存越大

```http
PUT test
{
	"mappings": {
		"properties": {
			"name": {
				"type": "text",
				"index_options": "offsets"
			}
		}
	}
}
```



## null_value

null_value的设置有以下作用：

- 需要对`Null`值实现搜索
- 只有keyword 类型支持特定`Null_Value`

```http
DELETE users
PUT users 
{
  "mappings": {
    "properties": {
      "firstName": {
        "type": "text"
      }, "lastName": {
        "type": "text"
      },
      "mobile": {
        "type": "keyword",
        "null_value": "NULL"
      }
    }
  }
}

# 加入新数据
PUT users/_doc/1
{
  "firstName": "Li",
  "lastName": "mingming",
  "mobile": null
}

# 根据电话号码查询
POST /users/_search
{
  "query": {
    "match": {
      "mobile": "NULL"
    }
  }
}
```

## copy_to

- `_all`在7中被`copy_to`所替代
- 满足一些特定的搜索需求
- `copy_to`将字段的数值拷贝到目标字段，达到`_all`的作用
- `copy_to`的目标字段不出现在`_source`定义中

```http
DELETE users
PUT users 
{
  "mappings": {
    "properties": {
      "firstName": {
        "type": "text",
        "copy_to": "fullName"
      }, "lastName": {
        "type": "text",
        "copy_to": "fullName"
      },
      "mobile": {
        "type": "keyword",
        "null_value": "NULL"
      }
    }
  }
}

# 加入新数据
PUT users/_doc/1
{
  "firstName": "Li",
  "lastName": "mingming",
  "mobile": null
}

# 查询fullName
GET users/_search?q=fullName:(Li mingming)

# 根据电话号码查询
POST /users/_search
{
  "query": {
    "match": {
      "fullName": {
        "query": "Li mingming",
        "operator": "and"
      }
    }
  }
}
```

