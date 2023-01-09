# html5语法

- 内容类型(content-type)
  
  - html5的文件扩展符与内容类型保持不变，任然为*.html或*.htm

- DOCTYPE声明
  
  - 不区分大小写

- 指定字符集编码
  
  - `<meta charset='utf-8' />`

- 可省略标记的元素
  
  - 不允许写结束标记的元素：br ,  col, embed, hr, img , input, link, meta
  
  - 可以省略结束标记的元素：li, dt, dd, p, option, colgroup, thread, tbody, tfoot, tr, td, th
  
  - 可以省略全部标记元素：html, head, body, colgroup, tbody

- 省略引号
  
  - 属性值可以使用双引号，也可以使用单引号

## 2. 新增语义化标签

- section元素 表示页面中的一个内容区块

- article: 表示一块与上下文无关的独立的内容

- aside: 表示在article之外的，与article内容相关的辅助信息

- header: 表示页面中一个内容区块或整个页面的标题

- footer: 表示页面中一个内容区块或整个页面的脚注

- nav元素：表示页面中导航链接部分

- figure元素：表示一段独立的流内容，使用figcaption元素为其添加标题

- main元素：表示页面中的主要的内容(ie不兼容)

## 3. Video和audio应用

- video元素，定义视频
  
  - `<video src = "" controls="controls" >Video元素</video>`

- audio元素，定义音频
  
  - `<audio src="">audio元素</audio>`

- 属性控制
  
  - controls属性：如果出现该属性，则向用户显示空间，比如播放按钮
  
  - autoplay属性：如果出现该属性，则该视频就绪后马上播放
  
  - loop属性：重复播放属性
  
  - muted属性：静音属性
  
  - poster属性：规定视频正在现在时显示的图像，知道用户点击播放按钮

## 4. 增强表单

- type="color": 生成一个颜色选择的表单

- `type="tel"`：唤起拨号键盘表单

- `type="search"`： 产生一个搜索意义的表单

- `type="number"`：产生一个数值表单

- `type="range"`：产生一个滑动条表单

- `type="email"`：限制用户必须输入email类型

- `type="url"`：限制用户必须输入url类型

- `type="date"`：限制用户必须输入日期

- `type="month"`：限制用户必须输入月类型

- `type="week"`：限制用户必须输入周类型

- `type="time"`：限制用户必须输入时间类型

- `type="datetime-local"`：选取本地时间

## 5. 选项列表: datalist

```html
<input type="text" list="mylist">
    <datalist id="mylist">
        <option value="手机"></option>
        <option value="手表"></option>
        <option value="手环"></option>
        <option value="手镯"></option>
    </datalist>
```

# 


