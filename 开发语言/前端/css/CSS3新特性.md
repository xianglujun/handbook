# css3新特性

## 1. 选择器

### 1.1 层级选择器

```css
/*子代选择器*/
.box>li {
    border: 1px solid red;
}
/* ~当前元素的后面所有的亲兄弟 */
        .child~li {
            background-color: green;
        }
        /* 其后的第一个p标签，但是必须紧挨着 */
        .content+p {
            color: black;
            font-size: 100px;
        }
```

## 2. 属性选择器

1. E[attr]: 只是用属性名，但是没有确定属性值

2. E[attr="value"]：指定属性名，并指定了该属性的属性值

3. E[attr~="value"]：指定属性名，并且具有属性值，此属性值是一个词列表，并且以空格隔开，其中词列表中包含了一个value词，而且等号前面"~"不能不写

4. E[attr^="value"]：指定了属性名，并且有属性值，属性值是以value开头的

5. E[attr$="value"]：指定了属性名，并且有属性值，而且属性值以value结束的

6. E[attr*="value"]：指定了属性名，并且有属性值，而且属性值中包含了value

## 3. 伪类选择器

### 3.1 结构型伪类选择器

- X:first-child：匹配子集的第一个元素，IE就可以支持

- X:last-child：匹配父元素中最后一个X元素

- X:nth-child(n)：用于匹配索引值为n的子元素，索引值从1开始

- X:only-chlid：这个伪类一般用的比较少，比如上诉代码匹配的是div下的有且仅有一个的p, 也就是说，如果div内有多个p, 将不匹配

- X:root：匹配文档的根元素。在HTML中，根元素永远是HTML

- X:empty：匹配没有任何子元素的元素X

### 3.2 目标伪类选择器

`E:target`选择匹配E的所有元素，且目标元素被URL指向

### 3.3 UI元素状态伪类选择器

- E:enabled：匹配所有用户界面(form表单)中处于可用状态的E元素

- E:disabled：匹配所有用户界面(form表单)中处于不可用状态的E元素

- E:checked：匹配所有用户界面(form表单)中处于选中状态的元素E

- E:selection：匹配E元素中被用户选中或处于高亮状态的部分

### 3.4 否定伪类选择器

- E:not(s)：(IE6-8浏览器不支持:not()选择器)
  
  - 用于匹配所有不匹配简单选择符s的元素E

### 3.5 动态伪类选择器

- E:link
  
  - 链接伪类选择器
    
    - 选择匹配的E元素，而且匹配元素被定义了超链接并没有被访问过。常用语链接锚点上

- E:visited
  
  - 链接伪类选择器
    
    - 选择匹配的E元素，而且匹配元素被定义了超链接并已被访问过，常用语链接锚点上

- E:active
  
  - 用户行为选择
    
    - 选择匹配的E元素，且匹配元素被激活。常用于链接锚点和按钮上

- E:hover
  
  - 用户行为选择器
    
    - 选择匹配的E元素，且用户鼠标停留在元素E上。IE6及以下浏览器仅支持a:hover

## 4. 文本阴影

`text-shadow`用于实现文本阴影，具体写法为:

```css
text-shadow: -10px -10px 5px red;
```

其中的参数含义为：

- 10px: 水平方向的位移

- 10px: 垂直方向的位移

- 5px: 模糊成都

- red: 阴影颜色

## 5. 盒子阴影 box-shadow

属性值:

- h-shadow: 必须的，水平阴影的位置，允许负值

- v-shadow: 必须的，垂直阴影的位置，允许负值

- blur: 可选，模糊距离

- spread: 可选。阴影的大小

- color: 可选，阴影的颜色

- inset: 可选，从外层的阴影改变阴影内侧阴影

## 6.  border-radius

设置盒子边框圆角，能够使用`px`或者`%`来实现，

- `border-radius: 1px`当值只有一个的时候，四个角一样

- `border-radius: 1px 2px`左上右下，左下右上一致

- `border-radius: 1px 2px 3px`表示左上，左下右上，右下

- `border-radius: 1px 2px 3px 4px`顺时针设置

- `border-radius: 30px/60px`表示水平/垂直方向的设置

## 7. 字体引入

`@font-face`是CSS3中的一个模块，他主要是把自己定义的Web字体嵌入到你的网页中，随着`@font-face`模块的出现，我们在web开发中使用字体不怕只能

`@font-face`的语法规则：

- font-family: 字体列表，我的字体名称

- src: 字体守在的路径

- font-weight: 字体的粗细

- font-style: 字体样式

语法说明:

- 字体名称：此值指代的就是你自定义的字体名称，最好是使用下载的默认字体，该名称可以直接在font-family中直接使用

- source: 指代了字体的存放路径，可以是相对路径也可以是绝对路径
