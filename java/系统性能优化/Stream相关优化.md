# Stream 操作优化

## Stream 如何优化遍历

### Stream的实现原理

#### Stream操作分类

- Stream 操作分为两大类
  - 中间操作(Intermediate operations)
    - 无状态(Stateless) - `指元素的处理不受之前元素的影响`
      - unordered()
      - filter
      - map
      - peek
    - 有状态(Stateful) - `指该操作只有拿到所有元素之后才能继续下去`
      - distinct()
      - sorted()
      - limit()
      - skip()
  - 终结操作(Terminal operations)
    - 短路(Short-circuiting) - `指遇到某些符合条件的元素可以得到最终结果`
      - anyMatch()
      - allMatch()
      - findFirst()
      - findAny()
      - noneMatch()
    - 非短路(Unshort-circuiting) - `指必须处理完所有元素才能得到最终结果`
      - forEach()
      - forEachOrdered()
      - toArray()
      - reduce()
      - collect()
      - max()
      - min()
      - count()

#### Stream 源码实现

- PipelineHelper
  - AbstractPipeline
    - ReferencePipeline
      - Head
      - StatelessOp
      - StatefulOp
- BaseStream
  - AbstractPipeline
  - Stream
    - ReferencePipeline
- Sink