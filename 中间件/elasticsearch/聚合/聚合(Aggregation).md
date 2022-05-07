# 聚合(Aggregation)

## 定义

- ES 除了提供搜索意外，同时提供了针对ES数据统计分析的功能，具有以下特点
  - 实时性高
  - Hadoop(T + 1)
- 通过聚合，可以得到分析和总结之后的数据，并非寻找单个文档
- 高性能聚合，可以从ES中得到想要的结果
  - 无需在客户端自己去实现分析逻辑



## 分类

- Bucket Aggregation - 一些满足特定条件的文档的集合
- Metric Aggregation - 一些数学运算，可以针对文档字段进行统计
- Pipeline Aggregation - 对其他的聚合结果进行二次聚合
- Matrix Aggregation - 支持多个字段的操作并提供结果矩阵



### Bucket & Metric

- Metric 主要指一系列的统计方法，类比为sql中的统计方法
- Bucket 主要针对满足条件的文档，类似sql中的`group by `用法



### Bucket

- ES 提供了很多类型的Bucket，帮助使用者用多种方式划分文档
  - Term & Range (时间、年龄区间、地理位置)
- 例子：
  - 成都属于四川/ 一个学生属于 男性或者女性
  - 嵌套关系 - 成都属于四川，属于中国

### Metric

- 基于数据结果结果，
  - 支持在字段上进行计算
  - 支持在脚本(painless script)产生的结果之上进行计算
- 大多数Metric是数学计算，仅输出一个值
  - min / max / sum /avg / cardinality
- 部分metric支持输出多个值
  - stats / percentiles / percetnile_ranks



### 使用示例

```json
# 聚合函数学习
# 按照目的地进行分桶统计
GET kibana_sample_data_flights/_search
{
  "size": 0,
  "aggs": {
    "flight_dest": {
      "terms": {
        "field": "DestCountry"
      }
    }
  }
}

# 统计航班的最低票价，平均票价，最低票价
GET kibana_sample_data_flights/_search
{
  "size": 0,
  "aggs": {
    "flight_dest": {
      "terms": {
        "field": "DestCountry"
      },
      "aggs": {
        "avg_price": {
          "avg": {
            "field": "AvgTicketPrice"
          }
      },
          "max_price": {
            "max": {
              "field": "AvgTicketPrice"
            }
          },
          "min_price": {
            "min": {
              "field": "AvgTicketPrice"
            }
        }
    }
  }
}
}

# 票价统计+天气信息
GET kibana_sample_data_flights/_search
{
  "size": 0,
  "aggs": {
    "flight_dest": {
      "terms": {
        "field": "DestCountry"
      },
      "aggs": {
        "stats_price": {
          "stats": {
            "field": "AvgTicketPrice"
          }
      },
          "weather": {
            "terms": {
              "field": "DestWeather",
              "size": 10
            }
          }
    }
  }
}
}
```

