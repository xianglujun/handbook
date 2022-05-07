# CountDownLatch

## 使用方式:
设置计数器, 但是当前的计数器不能为重置

## 使用场景
- 并行计算: 任务拆分为多个子任务, 并等待子任务执行完成

## 注意事项
- 为CountDownLatch设置初始计数器
- CountDownLatch计数器不能被回滚
- CountDownLatch可以设置等待超时时间

## Semaphore

### 使用场景

- 并发访问控制, 用于控制共享资源线程访问数量

## CyclicBarrier

- 并发访问控制, 线程之间等待执行结果, 并执行后面的记过；并且它的计数器可以被重置
- 每个线程准备就绪后, 才能继续往下执行

### 与CountLatchDown对比

- CountDownLatch
  - 计数器只能使用一次
  - 描述了一个或者多个线程等待其他线程的关系
- CyclicBarrier
  - 描述器可以通过reset方法重复使用
  - 描述了线程内部之间相互等待的关系

## 内部实现原理
- RetrantLock 与 Condition
- 当count == 0时, 执行barrierAction, 并从新开始计数
- Generation, 用于标记当前的barrier是否已经被阻断

## ReetrantLock

### ReetrantLock 与synchronize的区别

- 重入性
- 锁的实现
- 性能区别(synchronized在引入偏向锁和自旋锁后，性能差距不大)
- 功能区别
  - ReetrantLock 可以指定公平锁或者非公平锁; synchronzed 只能是非公平锁
  - 提供了一个Condition, 可以分组唤醒需要唤醒的线程；而synchronzed只能随机唤醒
  - 提供了能够中断等待锁的机制. lock.interruptibly();
  - ReetrantLock 在使用的时候, 必须手工释放锁

## ReentrantReadWriteLock

- 实现的是`悲观锁`。
- 分为读锁和写锁, 分别在操作的时候, 必须保证读锁或者写锁不存在时, 才会执行
- 在写操作时, 必须不存在"读锁"; 在读操作时, 必须不存在"写锁"

## StampLock
- 实现的是"乐观锁"
- 相对于ReentrantReadWriteLock来说，性能提升很高

## Condition
- 多线程间协调通信的能力
- 通过await加入到Condition的queue的队列中, 通过notifyAll()来将线程从Condition的queue中移除, 并加入到aqs的等待队列中

## 选择锁的依据

- 当只有少量竞争时, 可以使用"synchronized"
- 竞争较多, 但是线程的趋势可以预估, 可以使用"ReentrantLock"
- synchronized 通过jvm的方式自动解锁
