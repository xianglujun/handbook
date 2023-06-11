# AQS
AQS的全称为`AbstractQueuedSynchronizer`, 即抽象队列的同步器， 很多同步的API的实现都是基于此实现， 例如`ReentrantLock`,`Semaphore`,`CountDownLatch`等

## 框架
![CLH框架信息](../../img/CLH.png)

在AQS内容，通过维护`volidate int state`的值来实现同步, `state=1`代表锁定; `state=0`代表未锁定。 以及内部维护一个`FIFO`的队列, 缓存线程的等待队列。(多线程争用资源的时候, 会降线程加入到队列之中。)

1. state的访问方式有三种
- setState()
- getState()
- compareAndSetState()

2. AQS的资源的访问模式
- exclusive mode (独占的模式): 争用共享资源时, 只有一个线程能够执行, 其他线程处于(park)阻塞状态(例如: ReentrantLock)。
- shared mode(共享模式): 多个线程可以同时执行

> NOTE: 不同自定的队列同步器, 只需要实现共享资源`state` 的获取和释放即可, 至于线程的等待队列, `AQS`已经帮我们实现。

3. 自定义同步器需要实现以下方法
- tryAcquire(int arg) : 独占方式, 成功则返回true, 失败则返回false
- tryRelease(int arg) : 独占方式, 成功返回true, 失败则返回false
- isHeldExclusively() : 判断该线程是否在独占资源, 只有用到`condition`的时候才会用到该方法
- tryAcquireShared(int arg) : 共享方式. 尝试获取资源，`0` 表示成功, 但是没有剩余资源; 负数表示失败; 正数表示成功，并且还有剩余资源。
- tryReleaseShared(int arg) : 共享方式. 尝试释放资源, 如果释放后允许唤醒后续等待的线程则返回true,否则返回false.

以`ReentrantLock`为例, state 初始化状态为0, 表示未锁定。 会调用`tryAcquire`独占锁对state + 1; 其他线程在进行`tryAcquire`的时候就会失败。 直到线程unlock到state=0的状态。其他线程才有机会获取锁. 在释放锁之前, 当前的线程能够重复获取当前的锁, 并将state的状态累加。 这样的时候，在进行释放锁的时候就需要多次调用释放的操作。

一般来讲, 自定义同步器只需要实现独占模式或者共享模式其中的一种, 主要有tryAcquire-tryRelease 和tryAcquireShared-tryRealeaseShared两种模式，但是`ReentrantReadWriteLock` 实现了两种模式。


## 源码详解
### 1. accquire(int args)
```java
public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg)) {
      selfInterrupt();
    }
  }
```
函数流程如下:
- tryAcquire() - 尝试直接去获取资源, 如果成功则直接返回
- addWaiter() - 如果直接获取资源失败, 创建独占模式的Node, 并加入到线程等待队列的尾部
- acquireQueued - 使线程在队列中获取资源, 一直获取资源后才会返回. 如果在整个过程中被中断, 则返回true. 否则返回false.
- 如果线程在等待过程中被中断, 它是不响应的, 只是获取资源后才进行自我中断(selfInterrupt), 将中断补上。

### 1.1 tryAcquire(int args)
该方式尝试获取独占资源。如果获取成功, 则返回true; 如果失败则返回false; 这也正是`Lock`语义, 类似但是不局限于`tryLock`的实现。

```java
protected boolean tryAcquire(int arg) {
    throw new UnsupportedOperationException();
  }
```

这里是具体交由`AQS`的实现, 这里主要让子类实现该方法, 实现具体的锁定的方式, 主要用于自定义独占同步器。

### 1.2 addWaiter(Node node)
```java
private Node addWaiter(Node mode) {
    // 这里是创建了一个节点, 其中包含了当前的线程, 以及以什么样的模式获取锁
    Node node = new Node(Thread.currentThread(), mode);
    // Try the fast path of enq; backup to full enq on failure
    // 找到队列的尾部
    Node pred = tail;
    // 通过cas的方式向对位添加一个等待的节点
    if (pred != null) {
      node.prev = pred;
      if (compareAndSetTail(pred, node)) {
        pred.next = node;
        return node;
      }
    }

    // 通过CAS自旋的方式加入到队尾
    enq(node);
    return node;
  }
```

该方会在第一次进行尝试直接添加到队尾, 如果尝试失败, 则会通过`CAS`自旋的形式加入到队列的尾部。

对于Node而言, 有一下四种状态需要说明:
- `CANCELLED` : 值为1，在等待队列中等待超时, 或者线程等待被中断, 从要从线程等待队列中移除该NODE节点。即`waitStatus`的状态为`CANCELLED`，并且该节点的状态不会再改变。
- `SIGNAL` - 值为``-1``, 该状态处于唤醒状态, 当前面的节点处于释放资源或者被取消, 将会通知其后继节点执行
- `CONDITION` - 值为``-2``, 该标识的节点处于`等待队列`中, 节点的线程等待在`Condition`上, 当其他的线程调用了`Condition`的`signal`后, 将从`等待队列`转移到同步队列中, 并获取同步锁
- `PROPAGATE` - 值为``-3``, 与共享模式相关, 在共享模式中, 该状态表明节点处于可以执行的状态。
- `0` 表示一个初始化的状态。

> NOTE: 通过`waitStatus > 0`表示`CANCELLED`和`waitStatus < 0`表示有效状态

### 1.3 enq(Node node)
```java
private Node enq(final Node node) {
    // 通过CAS向队列的尾部添加一个节点
    for (; ; ) {
      Node t = tail;
      if (t == null) { // Must initialize
        // 如果当前没有设置head, 则会先创建一个虚拟的head,
        // 然后直接向尾部进行插入数据node
        Node h = new Node(); // Dummy header
        // 这里是设置predecessor和next的，能够被互相访问。
        h.next = node;
        node.prev = h;
        if (compareAndSetHead(h)) {
          tail = node;
          return h;
        }
      } else {
        node.prev = t;
        // 加入到队尾成功则返回, 加入失败则继续尝试加入到队尾
        if (compareAndSetTail(t, node)) {
          t.next = node;
          return t;
        }
      }
    }
  }
```

### 1.4 acquireQueued(Node, int)
```java
final boolean acquireQueued(final Node node, int arg) {
    try {
      boolean interrupted = false;
      for (; ; ) {
        final Node p = node.predecessor();
        // 这个方式判断当前节点的上一个节点, 如果上一个节点为头部节点,
        // 我们知道头部节点是一个虚拟的节点, 因此是不需要等待的，则尝试获取
        // 资源, 如果获取成功, 则当前的节点设置为头部节点
        if (p == head && tryAcquire(arg)) {
          setHead(node);
          p.next = null; // help GC
          return interrupted;
        }
        // 该处主要找到一个park的点, 主要判断父节点是否为signal的waitStatus
        if (shouldParkAfterFailedAcquire(p, node) &&
            parkAndCheckInterrupt()) {
          interrupted = true;
        }
      }
    } catch (RuntimeException ex) {
      cancelAcquire(node);
      throw ex;
    }
  }
```

这个方法会判断, 如果需要排队的节点高寒处于第二个节点, 则尝试获取资源的状态, 如果失败, 则需要将当前的节点寻找到能够`park`的位置.

#### 1.4.1 shouldParkAfterFailedAcquire(Node, Node)
该方法检查状态, 主要检查当前的排队的节点是否能够进入park状态
```java
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
    int ws = pred.waitStatus;
    if (ws == Node.SIGNAL)
      /*
       * This node has already set status asking a release
       * to signal it, so it can safely park
       */ {
      return true;
    }

    if (ws > 0) {
      /*
       * Predecessor was cancelled. Skip over predecessors and
       * indicate retry.
       *
       * 这里判断了祖先节点已经被取消, 则应该取消祖先节点的等待, 并从等待队列中剔除。
       */
      do {
        node.prev = pred = pred.prev;
      } while (pred.waitStatus > 0);
      pred.next = node;
    } else {
      /*
       * waitStatus must be 0 or PROPAGATE. Indicate that we
       * need a signal, but don't park yet. Caller will need to
       * retry to make sure it cannot acquire before parking.
       */
      compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
    }
    return false;
  }
```
主要判断前继节点是否处于`SIGNAL`的状态, 如果前继的节点不是`SIGNAL`的状态, 那么会尝试将前置的节点设置为`SIGNAL`状态。如果前继节点为`CANCELLED`的状态, 将会跳过这些节点, 使已经取消的节点能够被回收.


#### 1.4.2 parkAndCheckInterrupt()

当等待的节点找到了park的位置之后, 通过`park()`方法处于`waiting`的状态, 等待被`unpark`或者`interrupt`的执行。

```java
private final boolean parkAndCheckInterrupt() {
    LockSupport.park(this);
    return Thread.interrupted();
  }
```

### 1.5 小结
这里总结一下`acquireQueued`的过程:
- 进入到线程等待队列, 并寻找到安全的park的配置
- 调用`park()`方法进入`waiting`状态, 等待`unpark()`或者`interrupt()`方法
- 被唤醒后, 查看自己是否能够拿到资源状态, 如果拿到, 则被设置为head节点; 如果没有拿到, 则继续当前的流程，。

### 1.6 acquire方法的小节
总结下`acquire`的流程:
- 调用自定义同步器的`tryAcquire`方法尝试获取资源, 如果成功则直接返回
- 如果获取失败, 则通过`addWaiter`方法将当前线程缓存到队列的尾部, 并标记为独占模式
- `acquireQueued`方法找到适合自己的park点, 并在等待队列中休息, 直到(unpark)会去重复尝试获取资源.如果被interrupt则返回true, 否则返回false.
- 如果线程在等待过程中被中断, 并不会立即响应, 而是等到拿到资源后, 通过`selfInterrupt`进行自我中断。

![acquire执行流程](../../img/acquire_process.png)

## 2. release(int)
该方法用于释放独占模式的锁资源, 如果彻底释放了资源(state == 0 表明释放锁完成), 则会唤醒队列中的其他资源竞争资源,
```java
public final boolean release(int arg) {
    if (tryRelease(arg)) {
      Node h = head;
      // 这里回去判断, 如果当前的node状态不是0，代表了
      // 有后续的节点在等待, 因为在独占模式中, 如果有后续等待节点,
      // 会将当前的节点的状态设置为SIGNAL状态
      if (h != null && h.waitStatus != 0) {
        unparkSuccessor(h);
      }
      return true;
    }
    return false;
  }
```

这里主要通过`trayRelease`的方法进行锁的释放. ==*这里主要通过tryRelease()方法的返回值判断是否释放成功, 所以当我们在实现tryRelease方法的时候, 需要特别的注意这一点*==

### 2.1 tryRelease(int arg)
```java
protected boolean tryRelease(int arg) {
    throw new UnsupportedOperationException();
  }
```
该方法是一个hook方法, 当我们需要自定义实现同步器的时候, 需要实现该方法。 一般来讲, tryRelease都会成功的, 因为这是独占模式, 当线程来释放资源, 那么可以证明当前的线程肯定已经获取到独占资源了。 直接减掉对应的资源就可以了, 也不需要考虑线程的安全问题了。(根据同步器的实现, 会根据tryRelease()方法的返回值来判断是否已经释放资源, 因此当state=0的时候则返回true, 否则返回false.)

### 2.2 unparkSuccessor(Node node)
```java
private void unparkSuccessor(Node node) {
    /*
     * If status is negative (i.e., possibly needing signal) try
     * to clear in anticipation of signalling. It is OK if this
     * fails or if status is changed by waiting thread.
     */
    int ws = node.waitStatus;
    if (ws < 0) {
      // 在进行唤醒的后继节点的时候, 会降当前的node节点设置为初始化状态
      compareAndSetWaitStatus(node, ws, 0);
    }

    /*
     * Thread to unpark is held in successor, which is normally
     * just the next node.  But if cancelled or apparently null,
     * traverse backwards from tail to find the actual
     * non-cancelled successor.
     */
    Node s = node.next;
    // 如果下一个节点为空或者已经被取消
    if (s == null || s.waitStatus > 0) {
      s = null;

      // 这里的遍历主要是如果下一个节点为空或者已经被取消, 则从tail节点依次向
      // 前进行遍历, 并获取处于正常状态的节点并唤醒
      for (Node t = tail; t != null && t != node; t = t.prev) {
        if (t.waitStatus <= 0) {
          s = t;
        }
      }
    }
    // 如果s的节点确实存在, 则调用唤醒的状态
    if (s != null) {
      LockSupport.unpark(s.thread);
    }
  }
```

这里通过`unpark()`方法唤醒了下一个不是`CANCELLED`状态的线程, 这是我们可以通过将`acquireQueued()`方法进行联系, 当线程被唤醒之后, 主要有一下步骤:
- 获取`interrupted`的状态, 并返回
- 如果`interrupted`状态为`true`, 则表明线程被打断, 但是依然回去获取独占资源(自旋)
- 这是`predecessor`的节点等于`head`节点, 则获得了回去独占资源的资格
- `tryAcquire`获取到独占资源
- do you want do........

### 2.3 小结
`release()`方法主要是释放独占资源, 最终状态为`state == 0`, 并通知等待队列的线程获取独占资源。

## 3. acquireShared(int)
这个方式是获取共享模式的入口, 主要是尝试获取共享资源, 获取失败则进入到等待队列。
```java
public final void acquireShared(int arg) {
    if (tryAcquireShared(arg) < 0) {
      doAcquireShared(arg);
    }
  }
```

在获取共享资源的时候, 主要通过`tryAcquireShared`的方式获取资源, 在这个方法中, 定义了基本的语法规则:
- 负数: 代表获取失败
- 0: 获取成功, 但是没有剩余资源
- 正数: 获取成功, 还有剩余资源可以获取

1. `tryAcquireShared()`尝试获取共享资源
2. 如果获取共享资源失败, 则通过`doAcquireShared()`将线程加入到等待队列

### 3.1 doAcquireShared(int arg)
```java
private void doAcquireShared(int arg) {
    // 将当前的线程加入到队尾
    final Node node = addWaiter(Node.SHARED);
    try {
      boolean interrupted = false;
      for (; ; ) {
        final Node p = node.predecessor();
        // 如果前继节点为head, 尝试否是能够获取到共享资源
        // 因为head是正在执行的线程, 这是线程执行到这里, 可能是head已经被执行完成,
        // 则尝试获取锁
        if (p == head) {
          int r = tryAcquireShared(arg);
          // 如果资源不够, 则继续寻找park点
          if (r >= 0) { // 获取共享资源成功
            // 将head指向自己, 如果还有剩余的资源, 则唤醒其后的节点资源
            setHeadAndPropagate(node, r);
            p.next = null; // help GC
            if (interrupted) {
              // 如果当前的线程通过interrupted的方式打断, 则执行自我中断的方式
              selfInterrupt();
            }
            return;
          }
        }
        // 尝试获取共享资源失败, 则找到能够park的位置
        // 并进行park, 等待被interrupted或者unpark
        if (shouldParkAfterFailedAcquire(p, node) &&
            parkAndCheckInterrupt()) {
          interrupted = true;
        }
      }
    } catch (RuntimeException ex) {
      cancelAcquire(node);
      throw ex;
    }
  }
```
在这里的实现中, 只有当前的线程处于head的下一个节点时, 才会去获取共享资源。并唤醒之后的其他节点获取共享资源。

> NOTE: 如果当前的线程获取资源不能满足的时候, 则会一直阻塞, 不会讲执行权利让出。
> 例如: head释放了5个资源, 第二个需要6个资源, 第三个需要1个资源, 第四个需要2个资源, 这是第二个在发现资源不够的时候, 不会讲执行的权利让个第三个和第四个执行， 而是继续park操作, 等待共享资源的释放。

### 3.1.1 setHeadAndPropagate(Node, int);
```java
private void setHeadAndPropagate(Node node, int propagate) {
    Node h = head; // Record old head for check below
    setHead(node);
    /*
     * Try to signal next queued node if:
     * Propagation was indicated by caller,
     * or was recorded (as h.waitStatus) by a previous operation
     * (note: this uses sign-check of waitStatus because
     * PROPAGATE status may transition to SIGNAL.)
     * and
     * The next node is waiting in shared mode,
     * or we don't know, because it appears null
     *
     * The conservatism in both of these checks may cause
     * unnecessary wake-ups, but only when there are multiple
     * racing acquires/releases, so most need signals now or soon
     * anyway.
     */
    if (propagate > 0 || h == null || h.waitStatus < 0) {
      Node s = node.next;
      if (s == null || s.isShared()) {
        doReleaseShared();
      }
    }
  }
```
该方法主要将获取到共享资源的node设置为head节点, 如果满足还有资源的时候, 则去告知邻居节点, 获取共享资源


### 3.2 小结
这里获取共享资源就学习的差不多了, 主要做了一下两件事情:
- `tryAcquireShared()`尝试获取共享资源, 如果获取成功, 则返回
- `doAcquireShared()`用于获取共享资源, 并park等待线程被`interrupted`或者`unpark`, 不会响应`interrupt`的操作

该方法的使用和`acquire`的实现很相似, 只不过共享资源的获取, 回去唤醒其后的节点, 用于去获取共享资源

## 3.4 releaseShared(int)
此方法会在共享模式中释放指定数量的共享资源, 如果释放成功, 并唤醒正在等待资源的线程。它会唤醒等待对类中的其他线程获取共享资源。
```java
public final boolean releaseShared(int arg) {
    // 尝试释放资源
    if (tryReleaseShared(arg)) {
      // 唤醒后续节点
      doReleaseShared();
      return true;
    }
    return false;
  }
```
此方法的流程为: ==释放共享资源, 唤醒等待队列的线程==, 这里需要与`tryRelease()`进行区别, tryRelease只会在`state==0`的时候, 才会返回true, 是以为它是以独占资源的方式. 而`tryReleaseShared()`的有剩余资源的时候, 则会去唤醒等待队列的线程获取剩余的资源。

### 3.4.1 doReleaseShared()
```java
private void doReleaseShared() {
    /*
     * Ensure that a release propagates, even if there are other
     * in-progress acquires/releases. This proceeds in the usual
     * way of trying to unparkSuccessor of head if it needs
     * signal. But if it does not, status is set to PROPAGATE to
     * ensure that upon release, propagation continues.
     * Additionally, we must loop in case a new node is added
     * while we are doing this. Also, unlike other uses of
     * unparkSuccessor, we need to know if CAS to reset status
     * fails, if so rechecking.
     */
    for (; ; ) {
      Node h = head;
      if (h != null && h != tail) {
        int ws = h.waitStatus;
        if (ws == Node.SIGNAL) {
          if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0)) {
            continue; // loop to recheck cases
          }
          unparkSuccessor(h);
        } else if (ws == 0 &&
            !compareAndSetWaitStatus(h, 0, Node.PROPAGATE)) {
          continue; // loop on failed CAS
        }
      }
      if (h == head) // loop if head changed
      {
        break;
      }
    }
  }
```

## 3.5 小结
以上为AQS的独占方式和共享方式的源码实现, 主要通过两个方法来实现（acquire和acquireShared）方法来获取资源, 但这两种方式产生的阻塞, 都不会响应中断阻塞, 都会在回去到资源之后才会响应阻断的请求。

## 参考文章
[JAVA并发之AQS](https://www.cnblogs.com/waterystone/p/4920797.html)
