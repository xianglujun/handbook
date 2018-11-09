题目1：最小函数min()栈


1. 设计含最小函数min()、取出元素函数pop()、放入元素函数push()的栈AntMinStack，实现其中指定的方法

2. AntMinStack中数据存储使用Java原生的Stack，存储数据元素为int。请实现下面对应的方法，完善功能。


public class AntMinStack {

    /**
     * push 放入元素
     * @param data
     */
    public void push(int data) {
      // todo
    }

    /**
     * pop 推出元素
     * @return
     * @throws Exception
     */
    public int pop() throws Exception {
        // todo
    }

    /**
     * min 最小函数，调用该函数，可直接返回当前AntMinStack的栈的最小值
     *
     * @return
     * @throws Exception
     */
    public int min() throws Exception {
        // todo
    }
}


题目2：算数表达式

设计数据结构与算法，计算算数表达式，需要支持

基本计算，加减乘除，满足计算优先级 例如输入 3*0+3+8+9*1 输出20

括号，支持括号，例如输入 3+（3-0）*2 输出 9

假设所有的数字均为整数，无需考虑精度问题


要求：

1. 输入的表达式是字符串类型String。

2. 对于操作数要求不止一位，这里对字符串里面解析出操作数有要求。需要有从表达式里面解析出完整操作数的能力。

3. 代码结构要求具备一定的面向对象原则，能够定义出表达式，操作数，运算符等对象。

4. 提供基本的测试。

题目3：提供一个懒汉模式的单实例类实现，并满足如下要求：

    1.考虑线程安全。

    2.基于junit提供测试代码，模拟并发，测试线程安全性，给出对应的断言。
