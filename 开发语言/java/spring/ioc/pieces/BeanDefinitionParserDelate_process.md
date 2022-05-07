# BeanDefinitionDelegae 解析流程
## createBeanDefinition
该方法用于创建`BeanDefinition对象`
- BeanDefinitionReaderUtils.createBeanDefinition(String parent, String className, ClassLoader classLoader)
  - 创建GenericBeanDefinition对象
  - 设置parentName的值
  - 如果classLoader != null, 则加载Class对象; 如果classLoader为空, 则设置beanClassName的值

## parseBeanDefinitionAttributes
解析`bean`节点的所有的属性, 包括`scope`,`abstract`,`lazy-init`,`autowire`,`dependency-check`,`depends-on`,`autowire-candidate`,`primary`,`init-method`,`destroy-method`,`factory-method`,`factory-bean`的属性
- 设置`BeanDefiniton`的scope属性
    - 判断&lt;bean&gt;是否设置了`scope`属性, 如果设置了，则设置`BeanDefintion`的`setScope`的值
    - 如果没有设置`scope`属性, 则判断是否设置了`singleton`的属性, 如果设置了，则调用`BeanDefnition`的`setScope`的值为`singleton`, 否则设置为`prototype`
    - 如果以上条件都没有设置, 则判断`constainBean`是否不为null, 如果不为null,就代表当前的&lt;bean&gt;的节点为子节点, 需要, 就与`constainBean`的`scope`属性保持一致就行。
- 设置`BeanDefintion`的`abstract`属性
    - 判断&lt;bean&gt;节点是否设置了`abstract`的属性，并判断属性的值是否为`true`.如果为true, 则将`BeanDefinition`的`abstract`的属性设置为`true`
- 设置lazyInit属性
    - 获取&lt;bean&gt;的`lazy-init`的属性
        - 如果为`default`, 则获取&lt;beans&gt;上的`default-lazy-init`的配置
    - 设置`BeanDefinition`的`setLazyInit`的属性
- 设置`autowire`属性
    - 获取&lt;bean&gt;的`autowire`的属性
        - 如果`autowire`的值为`default`, 则使用&lt;beans&gt;的`default-autowire`属性的值
        - 如果`autowire`的值为`byName`, 则以`1`代替
        - 如果`autowire`的值为`byType`, 则以`2`代替
        - 如果`autowire`的值为`constructor`, 则以`3`代替
        - 如果`autowire`的值为`autodetect`, 则以`4`代替
        - 如果属性值为设置, 或者设置成为无法识别的信息, 则以`0`代替
        - 将对应的`autowire`的数值, 设置为`BeanDefinition`的`setAutowireMode`的属性
- 设置`dependencyCheck`属性
    - 获取&lt;bean&gt;节点的`dependency-check`的属性值`dependencyCheck`
        - 如果`dependencyCheck`的值为`default`, 采用`<beans>`的`default-dependency-check`的属性值代替
        - 如果`dependencyCheck`的值为`all`, 以数值 `3`代替
        - 如果`dependencyCheck`的值为`objects`, 以数值 `1`代替
        - 如果`dependencyCheck`的值为`simple`, 以数值 `2`代替
        - 如果`dependencyCheck`的值没有设置,或者设置为无法识别的值, 则以`0`代替
        - 将`dependencyCheck`的值设置为`BeanDefintion`的`setDependencyCheck`属性中去
- 设置`dependsOn`属性
    - 判断&lt;bean&gt;是否包含了`depends-on`属性, 如果有, 则获取属性，保存为`dependsOn`
    - 将`dependsOn`根据`;,`进行分割, 获得`String[]`的数组列表
    - 将数组列表设置为`BeanDefinition`的`setDependsOn`属性
- 设置`autowireCandidate`属性
    - 获取&lt;bean&gt;的`autowire-candidate`的属性值`value`
        - 如果`value`的值为` `或者为`default`, 默认则获取`<beans>`的`default-autowire-candidate`的属性值`defaultValue`
            - `defaultValue`根据`,`进行分割, 得到一个`String[]`的匹配模型列表
            - `String[]`列表遍历, 并与当前的&lt;bean&gt;的节点的`beanName`进行匹配，如果匹配成功则返回`true`, 如果不成功, 则返回`false`
        - 如果`value`值已经存在, 就与`true`进行比较
        - 设置`BeanDefinition`的`setAutowireCandidate`的属性
- 设置`primary`属性
    - 获取&lt;bean&gt;的`primary`属性`value`
    - 如果`value`的值为`true`, 则将`BeanDefinition`的`setPrimary`的属性设置为`true`, 否则设置为`false`
- 设置`initMethodName`属性
    - 获取&lt;bean&gt;的`init-method`的属性`initMethodName`
       - 如果`init-method`属性没有设置, 则获取`<beans>`节点的`default-init-method`
    - 设置`BeanDefinition`的`setInitMethodName`的属性
- 设置`destroyMethodName`属性
    - 获取&lt;bean&gt;节点的`destroy-method`的属性值`destoryMethodName`
        - 如果`destory-method`的属性没有设置, 则默认获取`<beans>`的`default-destory-method`的属性
    - 如果`destoryMethodName`的值不为空, 则设置`BeanDefinition`的`setDestoryMethodName`的属性
- 设置`factoryMethodName`属性
    - 获取`<bean>`节点中的`factory-method`的属性值
    - 如果属性值不为空, 则设置`BeanDefinition`的`setFactoryMethodName`的属性
- 设置`factoryBeanName`属性
    - 获取`<bean>`节点中的`factory-bean`的属性值
    - 如果属性值不为空, 则设置`BeanDefintion`的`setFactoryBeanName`的属性

## parseMetaElements
获取`<meta>`的节点, , 主要获取`key`和`value`属性

  - 获取&lt;bean&gt;下的所有节点
  - 判断节点是否为`meta`节点
  - 如果节点为`<meta>`的节点, 获取`<meta>`节点的`key`和`value`属性
  - 将`key`和`value`的值存放在`BeanMetadataAttribute`中去
  - 将`BeanMetadataAttribute`存放在`BeanMetadataAttributeAccessor`中进行保存, 通过发现,`DefaultListableBeanFactory`其实也是`BeanMetadataAttribute`的一个子类

## parseLookupOverrideSubElements
获取`<lookup-method>`的节点, 并通过`LookupOverride`保存`name`和`bean`的两个属性

  - 这个方法很重要, 因为在创建bean对象的时候， 用到了这里的内容
  - 获取`<bean>`下的所有节点
  - 遍历所有的节点信息, 并判断当前节点是否为`<lookup-method>`节点
  - 如果是`<lookup-method>`节点, 获取节点的`name(methodName)`属性和`bean`属性
  - 将`name(methodName)`和`bean`的值封装在`LookupOverride`对象之中
  - 并将`LookupOverride`的引用存在`BeanDefinition`的`getMethodOverrides`的列表之中

## parseReplacedMethodSubElements
获取`<replaced-method>`节点, 并通过`ReplaceOverride`保存`name`和`replacer`的属性值

  - 这个方法也很重要, 因为methodOverrides在创建`BeanDefintion`时，会有使用
  - 获取当前`<bean>`节点下的所有的节点列表
  - 遍历节点列表, 并判断节点是否为`replaced-method`节点, 如果是, 获取`name`和`replacer(callback)`属性的值
  - 将`name`和`replacer(callback)`属性封装成为`ReplaceOverride`对象
  - 并将`ReplaceOverride`对象放入`BeanDefinition`的`getMethodOverrides`的列表之中

## parseConstructorArgElements
### parseConstructorArgElements(Element beanEle, BeanDefinition bd)
获取`<constructor-arg>`节点并保存

  - 获取当前`<bean>`节点下的所有子节点
  - 遍历子节点, 并判定节点的名称是否为`<constructor-arg>`
      - [parseConstructorArgElement(Element ele, BeanDefinition bd)](#parseconstructorargelement)

## parseConstructorArgElement
具体解析`<constructor-arg>`的地方, 获取该节点的`index`,`type`,`name`属性

  - 获取`<constructor-arg>`的`index`属性
  - 获取`<constructor-arg>`的`type`属性
  - 获取`<constructor-arg>`的`name`属性
  - 判断是否设置设置了`index属性`
      - 如果设置了`index`属性, 将`index`属性转换为`int`类型
      - 将`index`的值封装为`ConstructorArgumentEntry`对象, 并将当前操作的对象放入`parseState`的状态栈中
      - [parsePropertyValue(Element ele, BeanDefinition bd, String propertyName)](#parsepropertyvalue)

## parsePropertyValue
### parsePropertyValue(Element ele, BeanDefinition bd, String propertyName)

该方法主要用于解析`<property>`和`<constructor-arg>`节点

  - 判断入参`propertyName`是否为null，如果为null，则是获取`<constructor-arg>`的参数值; 如果不为null, 则是获取`<property>`的值
  - 获取当前节点下的所有节点
  - 遍历当前节点, 当前节点只能包含`<meta>`节点和`<description>`节点, 并且只能有一个节点
  - 判断`<constructor-arg>`节点是否包含了`ref`属性,
  - 判断`<constructor-arg>`节点是否包含了`value`属性。
  - 当前的节点中, `value`属性和`ref`属性只能包含一个
  - 如果当前的`<constructor-arg>`设置了`ref`的属性, 则获取`ref`属性值, 并保存为`RuntimeBeanReference`的值
  - 如果当前的`<constructor-arg>`设置了`value`的值, 则获取value的值, 并保存为`TypedStringValue`
  - 如果当前的`<constructor-arg>`包含了子节点`subElment`接点信息，则继续解析节点信息
      - [parsePropertySubElement(Element ele, BeanDefinition bd)](#parsepropertysubelement_no_default_value)

## parsePropertySubElement_NO_DEFAULT_VALUE
### parsePropertySubElement(Element ele, BeanDefinition bd)
该方法主要用来解析子节点, 包含了`bean`,`list`,`set`,`props`,`map`的节点
  - [parsePropertySubElement(Element ele, BeanDefinition bd, String defaultValueType)](#parsepropertysubelement)


## parsePropertySubElement
### parsePropertySubElement(Element ele, BeanDefinition bd, String defaultValueType)
这里是真正执行解析的地方,

  - 如果当前节点不是默认的`beans`空间的节点, 则调用`parseNestedCustomElement(Element ele, BeanDefinition containingBd) `方法
  - 如果节点是一个`bean`的节点, 则继续解析当前的`bean`节点信息`decorateBeanDefinitionIfRequired(			Element ele, BeanDefinitionHolder definitionHolder, BeanDefinition containingBd)`
  - 如果当前节点为`<ref>`节点
      - 如果当前节点`<ref>`包含了`bean`属性, 则获取`bean`属性的值, 保存为`refName`
      - 如果没有`bean`属性，则判断是否包含了`local`的属性, 如果包含了`local`属性，获取并保存为`refName`
      - 如果`local`属性不存在, 或者没有设置值, 则获取`parent`的属性, 并保存为`refName`, 如果`refName`不为空, 则标记`toParent`的值为`true`
      - 如果以上三个属性都没有包含, 则直接返回null
      - 如果`refName`的值获取成功, 返回`RuntimeBeanReference(refName, toParent)`
  - 如果当前节点是`<idref>`节点
      - 判断当前的节点是否包含了`bean`属性，如果有, 则保存属性值为`refName`
      - 如果没有包含`bean`属性, 则判断是否包含了`local`的属性, 如果已经包含，则保存为`refName`
      - 如果`refName`的值为空，则返回`null`
      - 如果不为空, 则返回`RuntimeBeanNameReference(refName)`的引用
  - 如果当前节点为`<value>`节点
      - 获取当前节点的值, 并保存为`value`
      - 判断当前的`<value>`节点是否包含了`type`属性, 如果包含了，则获取`type`的属性值, 并保存为`specifiedTypeName`
      - 如果`specifiedTypeName`的值为空, 则以默认值进行替代`defaultTypeName`
      - 根据`value`和`typeName`构建`TypedStringValue`对象
          - 如果`typeName`为空, 则以`TypedStringValue(value)`进行构建
          - 如果`typeName`并且`readerContext`包含了加载器, 则加载`typeName`对应的`Class`对象, 并通过`TypedStringValue(value, Class targetType)`构建
          - 如果`ClassLoader`为空, 则通过`TypedStringValue(value, typeName)`进行构建
      - 设置`TypedStringValue`对象的`setSpecifiedTypeName`的值为`specifiedTypeName`
  - 如果是`<null>`节点
      - 直接创建`TypedStringValue(null)`对象
  - 判断是否为`<array>`节点
      - 获取`<array>`节点的`value-type`的属性, 保存为`elementType`
      - 获取`<array>`节点下的所有子节点
      - 创建`ManagedArray`对象
      - 设置`ManagedArray`的`setElementTypeName`的属性为`elementType`
      - 判断当前的`<array>`节点是否包含了`merge`属性, 如果没有设置该属性, 则获取`<beans>`中的`default-merge`属性, 并设置`ManagedArray`的`setMergeEnabled`属性
      - 获取当前`<array>`所有节点，并解析为对应的引用对象, 并通过`ManagedArray`的`add`方法加入到列表项中
  - 判断是否为`<list>`节点
      - 获取`value-type`属性
      - 创建`ManagedList`对象
      - 设置`ManagedList`的`setElementTypeName`的属性为`elementType`
      - 判断当前`<list>`节点是否包含了`merge`属性, 如果没有设置该属性, 则获取`<beans>`根节点中的`default-merge`属性, 并设置`ManagedList`的`setMergeEnabled`属性
      - 获取当前`<list>`下的所有节点, 并解析为对应的引用对象, 并通过`ManagedList`的`add`方法加入到列表之中
  - 判断是否为`<set>`节点
    - 获取`value-type`属性
    - 创建`ManagedSet`对象
    - 设置`ManagedSet`的`setElementTypeName`的属性为`elementType`
    - 判断当前`<set>`节点是否包含了`merge`属性, 如果没有设置该属性, 则获取`<beans>`根节点中的`default-merge`属性, 并设置`ManagedSet`的`setMergeEnabled`属性
    - 获取当前`<set>`下的所有节点, 并解析为对应的引用对象, 并通过`ManagedSet`的`add`方法加入到列表之中
  - 判断是否为`<map>`节点
    - 获取`<map>` 节点中的`key-type`属性, 用于表示`map`的`key`的类型
    - 获取`<map>`节点中的`value-type`属性, 用于表示`map`的`value`的类型
    -  获取所有的`<entry>`节点
    - 创建`ManagedMap`的对象
    - 设置`ManageMap`中的`setKeyTypeName`的值为`key-type`属性
    - 设置`ManageMap`中的`setValueTypeName`的值为`value-type`属性
    - 判断`<map>`节点中的`merge`属性, 如果没有设置该属性, 则获取`<beans>`根节点中的`default-merge`属性, 并设置`MangedMap`的`setMergeEnabled`属性
    - 遍历`<entry>`所有节点
      - 获取`map`的key节点
        - 判断当前`<entry>`节点下的素有节点, 并获取`<key>`和`<value>`的节点, 并分别存储为`keyEle`和`valueEle`
        - 判断`<entry>`节点是否已包含了`key`和`key-ref`属性
        - 如果包含了`key`属性, 则通过`key`和`keyType`构建`TypedStringValue`对象
        - 如果包含了`key-ref`属性, 则通过获取`key-ref`属性的值`refName`, 并构建`RuntimeBeanReference(refName)`对象
        - 如果没有配置`key`和`key-ref`属性, 则通过获取`keyEle`的节点信息，并解析成为表示的引用类型
      - 获取`map`的`value`信息
        - 判断`<entry>`节点是否包含了`value`和`value-ref`的属性
        - 如果`value`属性已经包含, 则通过`value`属性值和`value-type`构建`TypedStringValue`对象
        - 如果`value`属性没有包含, 则获取`value-ref`的属性值`refName`,并封装成为`RuntimeBeanReference(refName)`对象
        - 如果没有设置`value`和`value-ref`的属性, 则通过`valueEle`获取属性的值, 然后继续遍历`<value>`节点, 并返回对应的封装引用对象
    - 将上面解析到的`key`和`value`的值放入`ManagedMap`集合之中
  - 如果是`<props>`节点
    - 创建`ManagedProperties`对象
    - 判断`<props>`节点中是否设置了`merge`属性, 如果没有设置, 则获取`<beans>`节点中的`default-merge`节点的配置, 并设置`ManagedProperties`的`setMergeEnabled`属性
    - 遍历`<props>`下的所有`<prop>`节点
      - 获取`<prop>`节点中的`key`属性
      - 获取`<prop>`节点中的text内容
      - 根据`key`创建`TypedStringValue`为`keyValue`
      - 根据`value`创建`TypedStringValue`为`value`
      - 将`value`和`keyValue`通过`ManagedProperties`.`put`属性计入到兑现该引用中

## parsePropertyElements
### parsePropertyElements(Element beanEle, BeanDefinition bd)

解析所有的`<property>`节点, 并将节点信息放在`metadataAttribute`中
  - 解析`<property>`的节点
    - 获取`<bean>`下的所有`<property>`节点列表
    - 获取`<property>`节点的`name属性`
    - 在`parseState`中压入当前正在解析的`<property>`节点
    - 解析`<property>`节点的`key`和`value`属性或者其子节点信息, 例如`<list>`, `<set>`等
    - 创建`PropertyValue`对象, `PropertyValue(key, value)`
    - 获取`<property>`下的`<meta>`节点， 并将`<meta>`节点的`key`和`value`属性设置到`BeanMetadataAttribute`对象之中
    - `PropertyValue`设置`addMetadataAttribute`, 其值为`BeanMetadataAtrribute`
    - 通过`BeanDefinition`的`getPropertyValues`将当前加载的`PropertyValue`属性, 加载到列表之中
    - 将当前正在解析的`<property>`从`parseState`中进行移除

## parseQualifierElements
### parseQualifierElements(Element beanEle, AbstractBeanDefinition bd)

解析`<qualifier>`节点, 并保存解析出来的信息
  - 解析`<qualifier>`节点信息
    - 获取`<qualifier>`节点的`type`属性
    - 如果`type`属性设置, 则将当前正在解析的`qualifier`节点加入到`parseState`中
    - 创建`AutowireCandidateQualifier(typeName)`对象
    - 获取`<qualifier>`节点的`value`的属性,
    - 通过`AutowireCandidateQualifier`的`setAttributes`将value值设置到对象之中
    - 获取所有`<attribute>`节点
    - 遍历`<attribute>`节点
    - 获取`<attribute>`节点的`key`和`value`属性
    - 将对应的值存放在`BeanMetadataAttribute(key, value)`之中
  - 将`AutowireCandidateQualifier`信息存放到`BeanDefnition之中`
