# Index Alias

## 实现零停机运维

- 可以为索引创建一个`alias`别名，当指定alias别名之后，查询索引可以通过`alia`查询
- `一个索引可以指定多个别名`, 相反，`一个别名也可以拥有多个不同类型索引`



## 使用实例

```json
# 创建别名
POST _aliases
{
  "actions": [
    {
      "add": {
        "index": "movies",
        "alias": "movies-latest"
      }
    }
  ]
}

POST movies-latest/_search
{
  "query": {
    "match_all": {}
  }
}

# 创建alias时，指定过滤器
POST _aliases
{
  "actions": [
    {
      "add": {
        "index": "movies",
        "alias": "movies-lates-years",
        "filter": {
          "range": {
            "year": {
              "gte": 1999
            }
          }
        }
      }
    }
  ]
}

POST movies-lates-years/_search
{
  "query": {
    "match_all": {}
  }
}
```

