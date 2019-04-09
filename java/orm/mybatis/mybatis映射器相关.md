# mybatis映射器相关

## insert节点
1. 当数据库字段设置为自增长时, 可以通过以下方式自动回填id的值
```xml
<insert id="insertRole" parameterType="role" useGeneratedKeys="true" keyProperty="id">
  insert into t_role (role_name, note) values (#{roleName}, #{note})
</insert>
```

2. 如果数据库没有自增长id的属性, 这个时候就需要我们自己设置主键值的生成, 可以采用以下方式:
```xml
<insert id="insertRole" parameterType="role" useGeneratedKeys="true" keyProperty="id">
  <selectKey keyProperty="id" resultType="int" order="BEFORE">
    select if(max(id), null, 1, max(id) + 1) from t_role
  </selectKey>
  insert into t_role (role_name, note) values (#{roleName}, #{note})
</insert>
```
这样就可以通过自定义的方式生成主键的值了。


## 参数
### 存储过程参数
存储过程支持三种参数类型
- IN 输入
- OUT 输出
- INOUT 输入输出参数

Mybatis与之相对应, 分别使用IN,OUT,INOUT来进行区分，通过`mode`属性来进行设置
```xml
#{role,mode=INOUT,jdbcType=CURSOR,javaType=ResultSet,resultMap=roleResultMap}
```

### 高级特性
一般而言, Mybatis都是根据返回数据推断数据类型, 但是我们也可以手工的指定类型:
```xml
#{role,mode=INOUT,jdbcType=CURSOR,jdbcTypeName=MY_TYPE,javaType=ResultSet,resultMap=roleResultMap}
```

### 特殊字符串处理和替换(#/$)
`#`Mybatis进行处理时，会将该参数处理为编译参数"?", 然后通过预编译的方式传入具体的参数值
`$` 则作为直接输出的方式, 不会做预编译的处理

## sql 元素
sql元素通过将sql中通用部分抽离成单独的元素, 已达到简化的目的
```xml
<sql id="column_list"/>
<include refid="column_list" />
```

## resultMap 结果集映射
resultMap的作用在于将sql查询的结果与JavaBean进行映射的作用

### 组成元素
```xml
<resultMap>
  <constructor>
    <idArg />
    <arg />
  </constructor>
  <id />
  <result />
  <association />
  <collection/>
  <discriminator>
    <case />
  </discriminator>
</resultMap>
```

### 2. 使用map存储结果
```xml
<select id="select" resultType="map">
</select>
```
注: 一般而言，map能够映射所有的结果集, 但是意味着可读性下降

### 3. 使用POJO存储对象
1. 通过`resultMap`的方式, 不过实现需要配置`<resultMap/>`节点
2. 通过sql别名方式, 别名与POJO对象属性名称一致即可

### 4. 级联
- association : 映射一对一的关系
- collection : 映射一对多的关系
- discriminator:鉴别器, 它可以根据实际选择使用哪个类作为实例, 允许你根据不同条件关联不同的结果集

#### 另外一种级联方式
1. 在SQL中通过`JOIN`的方式查询出关联数据
2. 在配置`resultMap`时, 直接在关联节点中配置其他数据
![另一种级联方式](../../img/mybatis/other_ossciation_way.png)

#### 级联的性能分析和N+1问题
1. N + 1
N + 1问题主要出现在级联关系时, 在查询数据时，会查询其他关联表的数据, 从而导致过多SQL执行而影响性能

2. 延迟加载
为了解决`N+1`问题，引入了延迟加载，只有在使用级联数据时，才会通过Mapper加载数据

![](../../img/mybatis/aggressive_lazy_loading.png)

延迟加载主要有一下几种方式：
- 全局配置
  - `lazyLoadingEanble` 用于设置是否开启延迟加载`<setting name="lazyLoadingEanbled" value="true" />`
  - `aggressiveLazyLoading`开启层级延迟加载模式.如果在一个POJO中存在同级的级联, 则会同时加载`<setting name="aggressiveLazyLoading" value="true" />`. 该配置默认状态为`true`
- 局部配置
    - `association` 可以通过`fetchType`控制延迟加载 `<association fetchType="eager|lazy />"`
    - `collection` 通过`fetchType`控制延迟加载`<collection fetchType="eager|lazy/>"`

> NOTE: 如以上图，在学生POJO(Student)中, 包含了课程成绩(Grade)以及学生证信息(SelfCard), 当我们访问课程成绩时, 会将学生证的成绩查询出来。这时为了解决这个问题, 我们可以使用`aggressiveLazyLoading=false`的方式完成关联属性的延迟加载.

> NOTE: 但是有时我们希望部分数据延时加载，部分及时加载, 这时我们就需要在`collection`和`association`中配合`fetchType`使用，完成个性化的配置
