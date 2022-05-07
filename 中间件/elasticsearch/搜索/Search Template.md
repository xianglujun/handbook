# Search Template

`Search Template`的主要功能是用于解耦程序与搜索DSL



## 作用

Search Template作用是，通过将查询Template与具体使用解耦，当查询的相关字段或者性能上进行优化时，使用端无序感知和做修改。



### 使用实例

```json
# 定义查询模板
POST _scripts/tmdb
{
  "script": {
    "lang": "mustache",
    "source": {
      "_source": [
        "title"
        ],
        "size": 20,
        "query": {
          "multi_match": {
            "query": "{{q}}", # 指定需要传入的变量名称
            "fields": ["title"]
          }
        }
    }
  }
}

# 使用模板实现查询
POST movies/_search/template
{
  "id": "tmdb",
  "params": {
    "q": "Ghostbusters"
  }
}

```

