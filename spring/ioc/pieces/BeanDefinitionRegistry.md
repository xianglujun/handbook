# BeanDefinitionRegistry registry)`
 - 该方法主要完成的是将当前的`BeanDefinition`注册到`BeanDefinitionRegistry`中去
   - 因为这里通过`DefaultListableBeanFactory`进行`BeanDefinition`的注册, 因此可以看到, 会根据`beanName`将当前正在创建的`singleton`或者正在创建的`bean`进行销毁, 同时销毁当前已经存在的所有的依赖的缓存信息, 以及对依赖的`bean`全部进行销毁操作.
