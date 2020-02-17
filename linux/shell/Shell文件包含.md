# Shell文件包含
和其他语言一样, Shell也可以包含外部脚本, 这样可以很方便的封装一些功用代码作为一个独立的文件。
```sh
. filename # 注意点号(.)和文件名之间有一空格

或

source filename
```

## 实例
test1.sh
```sh
url="http://www.baidu.com"
```

test2.sh代码如下:
```sh
#!/bin/bash
# 使用.号来引用test1.sh文件
. ./test1.sh

# 或者使用以下包含文件代码
# source ./test1.sh

echo "百度官方网址: $url"
```
