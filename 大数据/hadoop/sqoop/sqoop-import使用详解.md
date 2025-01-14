# sqoop-import命令使用详解

import命令主要是将数据从RMDB到HDFS进行导入，在HDFS中，关系型数据库表中每一行数据都代表了一个record记录，这个record记录能够存储为text文件、二进制文件或者SequenceFile

## 数据库连接参数

| 参数名                                | 描述                                      |
| ---------------------------------- | --------------------------------------- |
| --conect <jdbc-url>                | 指定JDBC链接url字符串                          |
| --connection-manager <class_name>  | 指定使用的connection manager class 类         |
| --driver <class_name>              | 手动指定JDBC驱动类                             |
| --hadoop-mapred-home <dir>         | 覆盖`$HADOOP_MAPRED_HOME`配置               |
| --help                             | 打印使用帮助                                  |
| --password-file                    | 指定包含授权密码的文件路径                           |
| -P                                 | 从控制台读取输入的密码                             |
| --password <password>              | 设置授权密码                                  |
| --username <username>              | 设置授权用户名                                 |
| --verbose                          | 执行时输出更多的日志信息                            |
| --connection-param-file <filename> | 指定数据库连接字符串，以properties形式存储，也就是key=value |
| --relaxed-isolation                | 将连接的事务隔离级别修改为`UNCOMMITTED`              |

> Sqoop支持多种的数据库连接，具体数据库类型需要将对应的jdbc的jar上传到`$SQOOP_HOME/lib`目录下，然后通过`--driver`指定驱动类

## 导入数据参数

| 参数名                             | 描述                                                                 |
| ------------------------------- | ------------------------------------------------------------------ |
| --append                        | 将数据以追加的形式写入到HDFS中                                                  |
| --as-svrodatafile               | 将数据导入到Avro文件中                                                      |
| --as-sequencefile               | 导入数据到SequenceFile中                                                 |
| --as-textfile                   | 这个是默认类型，将数据导入到text 文件中                                             |
| --as-parquetfile                | 导入数据到Parquet File中                                                 |
| --boundary-query <statemente>   | 主要用于分割文件时使用                                                        |
| --columns <col1, col2, col3..>  | 指定导入关系型数据中的哪些列                                                     |
| --delete-target-dir             | 如果指定文件夹已经存在，则删除文件夹                                                 |
| --direct                        | 如果数据库存在，则使用直接连接                                                    |
| --fetch-size <n>                | 指定一次性从数据库中读取n条数据                                                   |
| --inline-lob-limit <n>          | 指定LOB最大值                                                           |
| -m, --num-mappers <n>           | 指定执行map任务数量                                                        |
| -e, --query <statemente>        | 需要导入的数据，SQL语句                                                      |
| --split-by <column-name>        | 指定以表中的字段分割工作单元，不能和`--autoreset-to-one-mapper`一起使用                  |
| --split-limit <n>               | 指定每个split的大小，这个只能是Integer或者datetime列，如果是date或者timestamp类型，将会按照毫秒计算 |
| --autoreset-to-one-mapper       | 如果一张表没有主键或者没有指定分割列，将使用一个mapper任务执行导入，该参数不能和`--split-by <col>`一起使用  |
| --table <table-name>            | 需要导入的表名                                                            |
| --target-dir <dir>              | HDFS目标文件夹                                                          |
| --temporary-rootdir <dir>       | HDFS的目录路径，用于存储在导入期间产生的临时文件，默认为`_sqoop`                             |
| --warehouse-dir <dir>           | HDFS目标的路径的父文件夹路径                                                   |
| --where <where clause>          | 在导入期间的where条件过滤                                                    |
| -z, --compress                  | 启用压缩                                                               |
| --compression-codec <c>         | 使用Hadoop的压缩算法, 默认为`gzip`                                           |
| --null-string <null-string>     | 当列值为Null时，将以指定字符串替换                                                |
| --null-non-string <null-string> | 当列值为Null时，如果列的类型不是字符串，则以指定字符串替换                                    |

> `--null-string`和`--null-non-string`没有指定时，对应列值将以`null`字符串替代
