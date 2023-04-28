# js变量类型

## 变量的声明

在js中有多重变量的声明方式，具体如下:

```js
// 定义一个变量x
var x

// 定义一个变量x, 并赋值为0
x = 0

// 输出x变量的值
x
```



## 类型列表

```js
x = 1; // 整数
x = 0.01; // 整数与实数功用一个数据类型

x = "JavaScript"; // 通过双引号创建的字符串
x = 'JavaScript'; // 通过单引号创建的字符串

x = true; // 布尔类型, 值为true
x = false; // 布尔类型, 值为false

x = null; // null 是一个特殊的值, 意思为"空"
x = undefined // null和undefined很相似

```

## 对象类型

```js
// 定义对象
person = { // 对象的定义以花括号开始
    firstName: "xiang", // 定义了属性firstName, 值为xiang
    lastName: "lujun"   // 定义类属性lastName, 值为lujun
};

// 访问属性可以通过.或者[]的方式
person.firstName; // xiang
person["lastName"]; // lujun

// 为属性赋值
person.lastName = "song";
person.age = 30; // 当我们为不存在的属性赋值时, 不会报错

person.age;
```

## 数组

```js
primes=[2,3,5,7,9]; // 定义一个数组

// 通过下标的方式访问数组中的元素
primes[0];  // 访问数组第一个元素
primes.length; // 5: 访问数组的长度

primes[1] = 4; // 修改下标为1的元素的值

empty = []; // 定义一个空数组
empty.length;  // 0; 空数组的长度为0
```