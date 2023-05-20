# vue3中的变化

- 不采用Vue2中的Object.defineProperty()方法的实现，采用Proxy方式
  
  - Object.defineProperty()主要有以下缺点
    
    - 无法监听es6中的Set和Map的变化
    
    - 无法监听Class中的属性变化
    
    - 属性的删除和新增也无法监听
    
    - 数组元素的新增和删除也无法监听
