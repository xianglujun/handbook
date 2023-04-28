# Function Score Query

- Function Score Query
  - 可以在查询结束后，对每一个匹配的文档进行一系列的重新算分，根据生成的分数进行排序
- 提供了默认计算分值的函数
  - `Weight`: 为每一个文档设置一个简单而不被规范化的权重
  - `Field Value Factor`: 使用该数值来修改_score
  - `Random Score`: 为每个用户使用一个不同的，随机算分结果
  - `衰减函数`：以某个一段的值为标准，距离某个值越近，得分越高
  - `Script Score`: 自定义脚本完全控制所需逻辑

## 通过`field_value_factor`提升权重

- 新的算分 = 老的算分* `field_value_factor`的具体值.



### Modifier平滑曲线

当评分系数差距很大时，会导致`_score`评分有很大的差异，这是就能够通过`Modifier`实现计算分数的差距

- 新的算分 = 老的算分 * log(1 + 投票数)

### Boost Mode

- Boost Mode
  - Multiply: 算分与函数值的乘积
  - Sum: 算分与函数的和
  - Min / Max : 算分与函数取 最小/最小值
  - Replace: 使用函数值取代算分

### Max Boost

- 可以将分数值控制在一个最大值



### 一致性随机函数

- 使用场景：网站的广告需要提高展现率
- 具体需求：让每个用户能看到不同的随机排名，但是，也希望同一个用户访问时，结果的相对顺序保持一致性

### 使用示例

```json
DELETE blogs

PUT blogs/_doc/1
{
  "title": "Java Learning",
  "content": "In this post we will talk about..",
  "votes": 0
}

PUT blogs/_doc/2
{
  "title": "Java Learning",
  "content": "In this post we will talk about..",
  "votes": 100
}

PUT blogs/_doc/3
{
  "title": "Java Learning",
  "content": "In this post we will talk about..",
  "votes": 10000000
}

# 查询blogs索引
POST blogs/_search
{
  "query": {
    "function_score": {
      "query": {
        "multi_match": {
          "query": "java",
          "fields": ["title","content"]
        }
      },
      "field_value_factor": {
        "field": "votes",
        "modifier": "log1p" # 老的算分 * log(1 + 投票数)
         "factor": 0.1 # 老的算分 * log(1 + 投票数 * factor)
      },
      "boost_mode": "sum",
      "max_boost": 3
    }
  }
}

# 一致性随机函数
POST blogs/_search
{
  "query": {
    "function_score": {
      "random_score": {
        "seed": 314159265399
      }
    }
  }
}
```

