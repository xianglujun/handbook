# xpath路径选择

## 选择

| 表达式      | 描述                           |
| -------- | ---------------------------- |
| nodename | 选取此节点的所有子节点。                 |
| /        | 从文档的根元素开始选取元素                |
| //       | 从匹配选择的当前节点选择文档中的节点，而不考虑它们的位置 |
| .        | 选取当前节点                       |
| ..       | 选取当前节点的父节点                   |
| @        | 选取属性                         |

## 谓语

| 路径表达式                              | 结果                                                     |
| ---------------------------------- | ------------------------------------------------------ |
| /bookstore/book[1]                 | 选取属于bookstore子元素的第一个book元素                             |
| /bookstore/book[last()]            | 选取属于bookstore子元素的最后一个book元素                            |
| /bookstore/book[last()-1]          | 选取属于bookstore子元素的导数第二个book元素                           |
| /bookstore/book[position()-3]      | 选取最前面的两个属于bookstore元素的子元素的book元素                       |
| //title[@lang]                     | 选取所有拥有名为lang的属性的title元素                                |
| //title[@lang='eng']               | 选取所有title元素，且这些元素拥有值为eng的lang属性                        |
| /bookstore/book[price>35.00]       | 选取bookstore元素的所有book元素，且其中的price的值必须大于35.00            |
| /bookstore/book[price>35.00]/title | 选取bookstore元素中的book元素的所有title元素，且其中的price元素的值必须大于35.00 |

## 选取未知节点

xpath通配符可用来选取未知的XML元素

| 通配符    | 描述        |
| ------ | --------- |
| *      | 匹配任何元素节点  |
| @*     | 匹配任何属性节点  |
| node() | 匹配任何类型的节点 |

在下面的表格中，我们列出了一些路径表达式，已经这些表达式的结果

| 路径表达式        | 结果                   |
| ------------ | -------------------- |
| /bookstore/* | 选取bookstore元素下的所有子元素 |
| //*          | 选取文档中的所有元素           |
| //title[@*]  | 选取所有带有属性的title元素     |

## 选取若干路径

通过在路径表达使用`|`运算符，可以选取若干个路径

| 路径表达式                             | 结果                                                |
| --------------------------------- | ------------------------------------------------- |
| //bookstore/title \| //book/price | 选取book元素的所有title和price元素                          |
| //title \| // price               | 选取文档中的所有的title和price元素                            |
| /bookstore/book/title \| //price  | 选取属于bookstore元素的book元素的所有title元素，以及文档中所有的price元素。 |

## 运算符

| 运算符 | 描述      | 实例                     | 返回值                                           |
| --- | ------- | ---------------------- | --------------------------------------------- |
| |   | 计算两个节点集 | //book \| //cd         | 返回所有拥有book和cd元素的节点集                           |
| +   | 加法      | 6+4                    | 10                                            |
| -   | 减法      | 10-3                   | 7                                             |
| *   | 乘法      | 7*8                    | 56                                            |
| div | 除法      | 10 div 2               | 5                                             |
| =   | 等于      | price=9                | 如果price的值是9, 则返回true, 否则返回false               |
| !=  | 不等于     | price!=9               | 如果price的值不是9，则返回true，否则返回false                |
| <   | 小于      | price<9                | 如果price是8，则返回true, 否则返回false                  |
| <=  | 小于或等于   | price<=9               | 同上                                            |
| >   | 大于      | price>9                | 如果price的值是10，则返回true，否则返回false                |
| >=  | 大于或等于   | price>=9               | 同上                                            |
| or  | 或       | price=9 or price = 10  | 当price的值为9时或者price的值为10时，返回true, 否则返回false    |
| and | 与       | price>9 and price < 10 | 如果price的值为9.8时，返回true. 如果price的值为8.6时，返回false |
| mod | 计算除法的余数 | 5 mod 2                | 1                                             |
