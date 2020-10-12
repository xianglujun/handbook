# Switch在JVM中的差异

## Switch查找case的方式

- tableswitch: `a table with keys and labels`
- lookupswitch: `uses a table with labels only（采用二分查找法）`

### tableswitch

当使用`tableswitch`时，从`stack`中获取int值，并直接通过`index`获取需要跳转的`label`， 并且立即执行跳转操作。在整个`lookup + jump`进程中，时间复杂度为`O(1)`



```java
 public static void testSwitch(String type) {
        Enum result = Enum.valueOf(type);
        Stopwatch stopwatch = Stopwatch.createStarted();
        switch (result) {
            case A:
                System.out.println(type);
                break;
            case B:
                System.out.println(type);
                break;
            case D:
                System.out.println(type);
                break;
            case E:
                System.out.println(type);
                break;
            case IF:
                System.out.println(type);
                break;
            case GOOD:
                System.out.println(type);
                break;
            case TEST:
                System.out.println(type);
                break;
            case PREVIEW:
                System.out.println(type);
                break;
            case PRODUCT:
                System.out.println(type);
                break;
            case SWITCH:
                System.out.println(type);
                break;
            default:
                // nothing
        }
        stopwatch.stop();
        System.out.println("switch用时:" + stopwatch.elapsed(TimeUnit.MILLISECONDS));
    }
```

在上面的执行中，主要使用了`tableswitch`的方式存储`label`:

```java
TABLESWITCH
      1: L3
      2: L4
      3: L5
      4: L6
      5: L7
      6: L8
      7: L9
      8: L10
      9: L11
      10: L12
      default: L13
```

对于`tablwswitch`的伪代码如下:

```java
int val = pop();
if (val < low || val > high) {
    pc += default
} else {
    pc += table[val-low]
}
```

#### `tablwswitch`存在间隙(`hole`)

```java
public static void testHoleSwitch(int val) {
        switch (val) {
            case 1:
                System.out.println(1);
                break;
            case 2:
                System.out.println(2);
                break;
            case 4:
                System.out.println(3);
                break;
            case 6:
                System.out.println(4);
                break;
            case 7:
                System.out.println(5);
                break;
            default:
                System.out.println("default");
        }
    }
```

对应字节码信息：

```java
TABLESWITCH
      1: L1
      2: L2
      3: L3
      4: L4
      5: L3
      6: L5
      7: L6
      default: L3
```

在以上的代码中，会生成`假的case标签(fake case)`, 这些虚假的标签指向了`default`的实现。



### lookupswitch

```markdown
When performing a **lookupswitch**, the int value on top of the stack is compared against the keys in the table until a match is found and then the jump destination next to this key is used to perform the jump. Since a lookupswitch table always **must be sorted** so that keyX < keyY for every X < Y, `the whole lookup+jump process is a **O(log n)` operation** as the key will be searched using a binary search algorithm (it's not necessary to compare the int value against all possible keys to find a match or to determine that none of the keys matches). O(log n) is somewhat slower than O(1), yet it is still okay since many well known algorithms are O(log n) and these are usually considered fast; even O(n) or O(n * log n) is still considered a pretty good algorithm (slow/bad algorithms have O(n^2), O(n^3), or even worse).
```

#### 实例

```java
public static void testStringSwitch(String string) {
        switch (string) {
            case "223":
                System.out.println("223.hascode:" + "223".hashCode());
                System.out.println("ddddddd");
                break;
            case "2223":
                System.out.println("2223.hascode:" + "2223".hashCode());
                System.out.println("测试系统");
                break;
            default:
                // do nothing
        }
    }
```

对应的字节码:

```java
LOOKUPSWITCH
      49651: L1
      1539201: L2
      default: L3
```

> 对于string类型而言，生成的`lookswitch`信息，使用的则是`String#hashcode()`作为key来生成，因为hashCode（）是散列的实现，因此导致了大量的间隙，所以采用`lookswitch`的操作.

对于以上查找中，一共有2个case, 因此需要查找1次，就能找到目标值。如果有100个case，则VM最多需要7次比较才能找到对应的label或者跳到default的label中。



## 扩展

