# Spring校验

## Spring校验使用场景

- Spring常规校验(`Validator`)
- Srping数据绑定(`DataBinder`)
- Spring Web参数绑定(`WebDataBinder`)
- Spring WebMVC/WebFlux 处理参数校验

## Validator接口设计

- 接口职责
  - Spring内部校验器接口，通过编程的方式校验目标对象
- 核心方法
  - supports(Class): 校验目标类能否校验
  - validate(Object, Errors): 校验目标对象，并将校验失败的内容输出至Errors对象
- 配套组件
  - 错误搜集器: org.springframework.validation.Errors
  - Validator工具类: org.springframework.validation.ValidationUtils

## Errors接口设计

- 接口职责
  - 数据绑定和校验错误搜集接口，与Java Bean和其属性有强关联性
- 核心方法
  - reject方法：搜集错误文案
  - rejectValue: 搜集对象字段中的错误文案
- 配套组件
  - Java Bean错误描述：`org.springframework.validation.ObjectError`
  - Java Bean 属性错误描述: `org.springframework.validation.FieldError`

## Errors 文案来源

- Errors文案生成步骤
  - 选择Errors实现(比如: BeanPropertyBindingResult)
  - 调用reject或rejectValue方法
  - 获取Errors对象中ObjectError或FieldError
  - 将ObjectError或FieldError中的code和args，关联MessageSource实现(如: ResourceBundleMessageSource)

## 自定义Validator

- 实现`org.springframework.validation.Validator`接口
  - 实现supports方法
  - 实现validate方法
    - 通过Errors对象搜集错误
      - ObjectError: 对象错误
      - FieldError: 对象属性错误
    - 通过ObjectError关联MessageSource实现最终文案

## Validator的救赎

- Bean Validation 与Validator适配
  - 核心组件 `org.springframework.validation.beanvalidation.LocalValidatorFactoryBean`
  - 依赖 Bean Validation - JSR-303 or JSR-349 provider
  - Bean方法参数校验 `org.springframework.validation.beanvalidation.MethodValidationPostProcessor`