#  bool 查询

- 一个bool查询，是一个或者多个子查询子句的组合
  - 包含4中子句
    - 2中影响算分
    - 2中不影响算分
- 相关性也是用与bool查询的子句，匹配的子句越多，相关性评分越高
- 如果多条查询子句被合并为一条复核查询语句，则每个查询子句计算得出的评分会被合并到总的相关性评分中
- 子查询可以任意顺序出现
- 可以嵌套多个查询
- 如果在bool查询中，没有must条件，should中必须至少满足一条查询
- 查询语句结构，会对相关性算分产生影响
  - 同一层级下的竞争字段，具有相同的权重
  - 通过嵌套bool查询，可以改变对算分的影响

| 操作     | 备注                                   |
| -------- | -------------------------------------- |
| must     | 必须匹配，贡献算分                     |
| should   | 选择性匹配，贡献算分                   |
| must_not | Filter Context查询子句，必须不能匹配   |
| filter   | Filter Context, 必须匹配，但不贡献算分 |

### 解决精确查找问题

> 解决该类问题，需要在ES mappings定义时，新增一个count字段，用于标识所要匹配的值数量统计，以此达到目的

```json
POST /products/_bulk
{"index": {"_id":1}}
{"productId": "HHC-AA-SD-3", "desc": "iPhone","genre": ["Comdey"], "count": 1}
{"index": {"_id":2}}
{"productId": "HHC-AA-AS-3", "desc": "iPod", "genre": ["Comdey", "Somdey"], "count": 2}

# 根据多个term, 实现精确查询
POST /products/_search
{
  "explain": true, 
  "query": {
    "constant_score": {
      "filter": {
        "term": {
          "genre.keyword": {
            "value": "Comdey"
          }
        },
          "term": {
          "count.keyword": {
            "value": 1
          }
        }
      }
    }
  }
}
```

### bool查询示例

![image-20210505102902049](.\image-20210505102902049.png)



### 查询结果示例

```json
POST /news/_bulk
{"index": {"_id": 1}}
{"content": "HuaWei Phone"}
{"index": {"_id": 2}}
{"content": "HuaWei Computer"}
{"index": {"_id": 3}}
{"content": "HuaWei employ like eat HuaWei launch and HuaWei dinner"}

POST news/_search
{
  "query": {
    "bool": {
      "must": {
        "match": {"content": "huawei"}
      }
    }
  }
}

# 通过must_not方式排除不关心的结果
POST news/_search
{
  "query": {
    "bool": {
      "must": {
        "match": {"content": "huawei"}
      },
      "must_not": {
        "match": {"content": "launch"}
      }
    }
  }
}

# 修改算法评分
POST news/_search
{
  "explain": true, 
  "query": {
    "boosting": {
      "positive": {
        "match": {
          "content": "huawei"
        }
      },
      "negative": {
        "match": {
          "content": "launch"
        }
      },
      "negative_boost": 0.5
    }
  }
}
```



## Disjunction Max Query

该查询机制，会查看某个字段上的最高评分，并将结果返回给客户端



### 使用示例

```json
POST blogs/_bulk
{"index": {"_id": 1}}
{"title": "Keeping fox healthy", "content": "My quick brown fox eats rabbits on a regular basist"}
{"index": {"_id": 2}}
{"title": "Quick brown rabbits", "content": "Brown rabbits are commonly seen"}

# 按照多字段查询
POST blogs/_search
{
  "query": {
    "bool": {
      "should": [
        {"match": {
          "title": "Brown fox"
        }},
        {"match": {
          "content": "Brown fox"
        }
        }
      ]
    }
  }
}

# 按照某个字段匹配度最高进行返回
POST blogs/_search
{
  "query": {
    "dis_max": {
      "queries": [
        {"match": {
          "title": "Brown fox"
        }},
        {"match": {
          "content": "Brown fox"
        }
        }
      ]
    }
  }
}

# 按照某个字段匹配度最高进行返回
POST blogs/_search
{
  "query": {
    "dis_max": {
      "queries": [
        {"match": {
          "title": "Quick pets"
        }},
        {"match": {
          "content": "Quick pets"
        }
        }
      ]
    }
  }
}
```



## Tier Breaker 

当进行`dis_max`查询时，可能返回结果评分相同，可以通过`Tie Breaker`调整评分

- 获得最佳评分语句的评分 `_score`
- 将其他匹配语句的评分与`tie_breaker`相乘
- 对以上评分求和规范化

> Tier Breaker是一个介于0-1之间的浮点数，0 - 表示最佳匹配；1表示有语句同等重要

### 使用示例

```json
POST blogs/_search
{
  "query": {
    "dis_max": {
      "queries": [
        {"match": {
          "title": "Quick fox"
        }},
        {"match": {
          "content": "Quick fox"
        }
        }
      ],
      "tie_breaker": 0.2
    }
  }
}
```



## Multi Match Query

- Best Fields 是默认类型，可以不用指定
- Munimun should match 等参数尅传递到生成的query中
- 用广度匹配字段title包括尽可能多的文档
  - 提高召回率
  - 同事使用字段title.std作为`信号`将相关度更高的文档置于结果顶部
- 每个字段对于最终评分的贡献可以通过自定值`boost`来控制
  - fields: ["title^10", "title.std"]
- 跨字段搜索
  - 无法使用Operator
  - 可以用copy_to解决，`但是需要额外的存储空间`
  - 指定: `type: cross_fields`
  - 这种方式能够支持Operator
  - 与`copy_to`相比，其中一个优势就是它可以在搜索时为单个字段提升权重

![image-20210505112513687](.\image-20210505112513687.png)

### 使用示例

```json
DELETE titles
PUT /titles
{
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "analyzer": "english",
        "fields": {
          "std": {
            "type": "text",
            "analyzer": "standard"
          }
        }
      }
    }
  }
}

# 批量插入数据
POST titles/_bulk
{"index": {"_id": 1}}
{"title": "My dog Tutu"}
{"index": {"_id": 2}}
{"title": "i see a lot of barking dongs on he road"}

# 按照title搜索
GET titles/_search
{
  "query": {
    "match": {
      "title": "barking dogs"
    }
  }
}

# Multi match
GET titles/_search
{
  "query": {
    "multi_match": {
      "query": "barking dogs",
      "type": "most_fields", # 将所有字段的比分累加
      "fields": ["title", "title.std"]
    }
  }
}


```



#### 跨字段搜索示例

```json
PUT address/_doc/1
{
  "street": "5 Poland Street",
  "city": "chendu",
  "country": "China",
  "postcode": "344556"
}

# Multi match
GET address/_search
{
  "query": {
    "multi_match": {
      "query": "Poland Street 344556",
      "type": "cross_fields",
      "operator": "and", 
      "fields": ["street", "city", "country", "postcode"]
    }
  }
}


```

