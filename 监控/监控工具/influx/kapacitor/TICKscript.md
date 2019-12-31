# TICKscript
用于对`telegraf`的数据进行统计, 并进行告警信息

## 将统计信息历史缓存到`dump`中
```sh
httpOut('dump')
```
```sh
http://localhost:9092/kapacitor/v1/tasks/{taskName}/dump 进行访问其中缓存的数据
```
## Syntax(语法)
在`TICKscript`语法中, 主要包含了两类语法:
- InfluxQL
- Lambda expressions

### TICKscript syntax
> TICKscript is case sensitive and uses Unicode. The TICKscript parser scans TICKscript code from top to bottom and left to right instantiating variables and nodes and then chaining or linking them together into pipelines as they are encountered. When loading a TICKscript the parser checks that a chaining method called on a node is valid. If an invalid chaining method is encountered, the parser will throw an error with the message “no method or property <identifier> on <node type>”.

以上是对`TICKscript`语言的解释, 大致意思是说:
> TICKscript 解析器会从上到下, 从左到右的解析文件, 并将每个方法以链式的方式进行关联。并且在进行解析时, 队徽每一个关联的方法进行验证, 如果方法验证失败, 将会抛出异常`no method or property <identifier> on <node type>`

## Code Representation(代码规范)
- 所有的`tick`文件均是采用`utf-8`的方式进行保存
- `Whitespace` 是用来分割变量名称、操作符、和字面量(literal values). 同时能够增加script文件的可读性
- `Comments(注解)` 单行注解采用`//`进行标记

## Key Words(关键字)
|关键字名称| 作用|
| :-----  | :-----                                 |
| ------- | -------------------------------------- |
| TRUE    | 代表字面量`true`                       |
| FALSE   | 代表字面量`false`                      |
| AND     | 用于布尔类型的链接操作                 |
| OR      | 用于布尔类型的OR操作                   |
| lambda: | 代表接下来的表达式是一个lambda的表达式 |
| var     | 声明一个变量                           |
| dbrp    | 声明一个database的变量                 |

## Operators
该处代表了`TICKscript`所表示的基本的操作。
`todo`

**Chain Operators**
|Operator|Usage|Example|
| :-----: | :-----                                                                                    | :-----                 |
| ------- | ----------------------------------------------------------------------------------------- | ---------------------- |
| `|`     | 主要是为了创建一个新的`nodes`, 并与前一个method进行关联, 形成一个完成的`pipelines`的链路  | `stream|operators()`   |
| `.`     | 主要为了调用node的一些方法, 用于改变内部的属性或者进行一些必要的设置                      | from().database(mydb); |
| `@`     | 定义一个用户自定义的一个方法, 本质上还是将用户自定义(UDF)的方法加入到`pipeline`的链路之中 | from()....@myFunc()    |


## Types
`TICKscript`能够识别5中类型标识(Type Identifier). 这些标识能够直接在`模板任务(Template Task)`中直接使用， 而这些类型的字面量能够直接从任务的定义中直接获取
|identifier|Usage|
| :------  | :-------                                                        |
| -------- | --------------------------------------------------------------- |
| String   | In template task, declare a variable as type `string`           |
| duration | In template task, declare a variable as type `duration`         |
| int      | In template task, declare a variable as type `int64`            |
| float    | In template task, declare a variable as type `float64`          |
| lambda   | In template task, declare a variable as Lambda Expresionss type |
