# mybatis动态SQL
|元素|作用|备注|
|:---|:---|:---|
|if   | 判断语句  |单条件判断语句   |
|choose(when,otherwise)   | 相当于java中case when   |多条件判断语句   |
|trim(where,set)   |辅助元素   |用于处理一些SQL拼接问题   |
|foreach   |循环语句   |在in语句中列举条件常用   |

## if 元素
```xml
<if test="condition != null and condition != ''"></if>
```

## choose, when, otherwise元素
相对于if来讲为非此即彼的关系, 而choose表达的为另外一种关系, 例如以下场景：
- 当角色编号不为空, 则使用角色编号查询
- 当角色编号为空, 但是角色名称不为空时, 使用角色名称进行查询
- 当角色编号为空, 角色名称为空时, 则备注一定不能为空

```xml
<choose>
  <when test="roleId != null and roleId != ''">
    AND role_id = #{roleId}
  </when>
  <when test="roleName!=null and roleName != ''">
    AND role_name = #{roleName}
  </when>
  <otherwise>
    AND note is not null
  </otherwise>
</choose>
```

## trim, set, where 元素
1. where 元素
```sql
select * from role where 1 = 1
<if test='roleName != null'>
  AND role_name = #{roleName}
</if>
```
我们可以看到，当where之下如果全都是条件判断的时候,`1=1`这样的条件使得我们能够正常的执行SQL
这时我们可以通过使用`<where/>`节点, 来避免这样的问题:
```sql
select * from role
<where>
  <if test='roleName != null'>
    AND role_name = #{roleName}
  </if>
</where>
```
当我们这样使用时，只有当where中的条件成立时, where才会展示出来

2. trim 元素
`<trim/>` 元素是用来特换掉特殊的字符, 例如:
```xml
select * from role
<trim prefix="where" prefixOverrides="and">
  <if test="roleName != null and roleName != ''">
    and role_name = #{roleName}
  </if>
</trim>
```
这时我们就可以替换掉多余的`and`字符串。
- prefix: 该属性时替换后的字符
- prefixOverrides: 需要替换的字符
- suffixOverrides: 替换后缀字符
- suffix: 替换之后的后缀字符

3. set 元素
`<set />`元素用来持续更新作用
```xml
<update id="updateSelective">
    update student
    <set>
        <if test="note != null and note != ''">
            note = #{note},
        </if>
        <if test="cnName != null and cnName != ''">
            cnname = #{cnName}
        </if>
    </set>
    where id = #{id}
</update>
```

4. foreach 元素
`<foreach/>`元素用来遍历集合, 并按照设定规则输出指定格式
- collection: 集合元素参数名称
- item: 配置中循环的当前元素
- index: 当前元素所在集合中的下标
- open,close: 决定了将这些元素以什么样的格式包裹起来
- separator: 将这些元素以符号进行分割

该操作一般用在对`in`操作时使用。

5. test 属性
`test`属性用来进行条件判断, 例如`<if />`的用法.

6. bind元素
`<bind />`元素用来对传入参数做特殊处理
```xml
<bind name="pattern" value="'%' + roleName + '%'"

select * from student where cnname like #{patter}
```
