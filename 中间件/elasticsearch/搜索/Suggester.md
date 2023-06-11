# Suggester

在输入文本时，可以根据文本的相似性，返回相似文本列表

## Term Suggester

- Suggester就是一种特殊类型的搜索
  - text 是调用时提供的文本，通常用于用户界面上用户输入的内容

##  Suggestion Mode

- Missing - 如索引中已经存在，就不提供建议
- Popular - 推荐出现频率更高的词
- Always - 无论是否存在，都提供建议



## Phrase Suggester

Phrase Suggester 在Term Suggester上增加了一些额外的逻辑

- 额外的参数
  - `Suggest Mode`: missing, popular, always
  - `Max Errors`: 最多可以拼错的Terms数
  - `Confidence`: 限制返回结果数，默认为`1`