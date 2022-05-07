# Term查询

- Term的重要性
  - Term是表达语义的最小单位。搜索和利用统计语言模型进行自然处理都需要Term
- 特点
  - Term Level Query: 
    - Term Query
    - Range Query
    - Exists Query
    - Prefix Query
    - Wildcard Query
- 在ES中，term查询，对于输入不做分词。
  - 将输入做一个整体，在倒排索引中查找准确的词项
  - 使用相关度算分公式为每个包含该词项的文档进行相关度算分
- 可通过Constant Score 将查询转换成一个Filtering，`避免算分，利用缓存`，提高性能

### 复合查询 - Constant Score 转为Filter

- 将Query转成Filter, 忽略TF-IDF计算，避免相关性算分的开销
- Filter可以有效的利用缓存



### 使用示例

```json
POST /products/_bulk
{"index": {"_id":1}}
{"productId": "HHC-AA-SD-3", "desc": "iPhone"}
{"index": {"_id":2}}
{"productId": "HHC-AA-AS-3", "desc": "iPod"}
{"index": {"_id":3}}
{"productId": "HHC-AA-2T-3", "desc": "MBP"}

# term查询
GET /products
POST /products/_search
{
  "query": {
    "term": {
      "desc": {
       // "value": "iPhone"
       "value": "iphone"
      }
    }
  }
}

# 商品编号查询
POST /products/_search
{
  "query": {
    "term": {
      "productId": {
        //"value": "HHC-AA-2T-3"
       // "value": "2t"
       "value": "hhc-aa-2t-3"
      }
    }
  }
}

# 精确匹配产品编号
POST /products/_search
{
  "query": {
    "term": {
      "productId.keyword": {
        "value": "HHC-AA-2T-3"
      }
    }
  }
}

# 避免ES相关性算分查询
POST /products/_search
{
  "explain": true, 
  "query": {
    "constant_score": {
      "filter": {
        "term": {
      "productId.keyword": {
        "value": "HHC-AA-2T-3"
      }
    }
      },
      "boost": 1.2
    }
  }
}
```

![image-20210504170710360](.\image-20210504170710360.png)

