# HBase与DBMS比较

- 查询数据不灵活
  
  - 不能使用column之间过滤查询
  
  - 不支持全文索引，使用ES和HBase整合完成全文索引
    
    - 使用MR批量读取HBase中的数据，在ES里面建立索引只保存rowkey的值
    
    - 根据关键词从索引中搜索到rowkey
    
    - 根据rowkey从hbase查询所有数据
