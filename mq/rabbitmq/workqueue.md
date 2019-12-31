# workqueue
> In the first tutorial we wrote programs to send and receive messages from a named queue. In this one we'll create a Work Queue that will be used to distribute time-consuming tasks among multiple workers.
(在最开始的教程中, 通过命名queue发送和接收消息。 在这一章节中, 我们将创建work queue, 该queue用于在多个wroker中共享消费同一条消息)

> The main idea behind Work Queues (aka: Task Queues) is to avoid doing a resource-intensive task immediately and having to wait for it to complete. Instead we schedule the task to be done later. We encapsulate a task as a message and send it to a queue. A worker process running in the background will pop the tasks and eventually execute the job. When you run many workers the tasks will be shared between them.(work queue主要的思想是, 避免立即执行资源密集型的任务, 而是等待任务完成之后, 再发送消息。因此我们使任务稍后执行。我们包装任务为一个消息并发送到queue中. 一个后台执行的工作线程(worker)去除任务并执行任务。当执行多个客户端工作线程时, 将会把任务在多个consumer端共享)

> This concept is especially useful in web applications where it's impossible to handle a complex task during a short HTTP request window.

## work queue的工作原理
默认RabbitMQ会将消息线性地发送给下一个消费端, 平均每个消费端将会得到相等数量的消息。这种消息分发方式被称作`round-robin`.

> By default, RabbitMQ will send each message to the next consumer, in sequence. On average every consumer will get the same number of messages. This way of distributing messages is called round-robin. Try this out with three or more workers.

## Message acknowledgment
在消息消费端, 执行一个任务需要几秒钟时间, 我们或许想知道消费端开始一个长时间任务或者任务执行一般就宕机中究竟发生了什么。在RabbitMQ默认中, 一旦RabbitMQ发送一条消息到消费端(Consumer), 服务端会立刻将该条消息标记为删除状态. 这种情况下，将会导致消息丢失. 我们也可能丢失传送给同一个宕机的消费端(consumer)导致消息全部丢失.

在一般场景中, 我们不希望丢失任何消息, 如果一个工作线程宕机, 我们期望将消息递送到到其他工作线程。

为了保证消息不会丢失, RabbitMQ支持`Message acknowledgment`. 一个`ack`将在消费端接收到消息之后被发送, 用于告知`RabbmitMQ`消费端已经收到消息. 服务端将会对该消息进行删除.

如果一个消费端(consumer)宕机(channel被关闭, 链接被关闭, TCP链接丢失)没有发送`ack`,  `RabbitMQ`将会明白消息没有被消费然后再次将该消息执行入队操作`re-queue`. 如果当前`queue`有其他消费端在线, 该条消息将会很快转发给其他的客户端. 通过这种方式保证消息不会丢失.

> 重新递送的消息没有消息过期时间, RabbitMQ在消费端宕机之后再次发送消息, 尽管重新发送消息将可能执行很长的时间。

`Manual message acknowledgment`默认是开启的。 在先前的例子中, 我们可以通过`autoAck=true`显式的关闭。
```java
channel.basicQos(1); // accept only one unack-ed message at a time (see below)

DeliverCallback deliverCallback = (consumerTag, delivery) -> {
  String message = new String(delivery.getBody(), "UTF-8");

  System.out.println(" [x] Received '" + message + "'");
  try {
    doWork(message);
  } finally {
    System.out.println(" [x] Done");
    channel.basicAck(delivery.getEnvelope().getDeliveryTag(), false);
  }
};
boolean autoAck = false;
channel.basicConsume(TASK_QUEUE_NAME, autoAck, deliverCallback, consumerTag -> { });
```

### Forgotten acknowledgment
丢失`basicAck`是一个常见的错误。这是一个很简单的错误, 但是结果却很严重. 当客户端放弃接收消息时, 消息将会被再次递送。但是RabbitMQ将会消耗更多的内容, 并且不能够释放`unacked`消息

为了debug这类型的错误, 可以通过`rabbitmqctl`打印出`messages_unacknowledged`信息:
```sh
sudo rabbitmqctl list_queues name messages_ready messages_unacknowledged
```

## Message durability
在上面的例子中, 学习了如何在客户端宕机的情况下, 保证消息不被丢失。 但是我们的任务在RabbitMQ服务器停止的时候, 依然可能会丢失。

当RabbitMQ退出或者崩溃时, RabbmitMQ将会丢失queues和messages, 除非我们显式的告知RabbitMQ保存消息. 主要通过`标记queue`和`为消息设置durable`两种途径来保证消息不会丢失.

### 标记queue
```java
boolean durable = true;
channel.queueDeclare("hello", durable, false, false, null);
```
> NOTE: 虽然以上代码正确, 但是不会达到预期的效果。因为我们已经定义了一个叫做`hello`的queue, RabbitMQ不允许重定义存在的queue, 也不允许为queue设置不同的参数。如果这么做, 将会返回`error`信息到程序。

### 为消息设置durable
通过`标记queue`我们保证了queue不被回收, 现在我们需要标记消息为持久化---通过设置`MessageProperties`的值为`PERSITENT_TEXT_PLAIN`

```java
channel.basicPublish("", "task_queue", MessageProperties.PERSITENT_TEXT_PLAIN, message.getBytes());
```

> NOTE: 标记消息为持久化不能完全保证消息不会丢失. 尽管通过标记告知RabbitMQ保存消息到磁盘. 但是RabbitMQ接收消息并保存消息之间有一个短暂的时间。 并且, RabbitMQ并不会为每个消息执行`fsync(2)`操作——消息可能挥别保存到缓存而不是写到磁盘. 这种持久化是一种弱的保证。如果需要更加强的持久化保证, 需要使用`publisher confirms`

## Fair dispatch
在一些场景中只有两个消费端, 当所有的奇数消息很重但是偶数消息很轻的时候, 其中一个消费端就会比另一个消费端做更重的任务。但是rabbitMQ不知道分发的合理性。

这种情况的发生是因为RabbitMQ只在消息进入queue时分发消息. 它不会关心`unack`消息的数量. 对于RabbitMQ而言, 只是盲目的将第n个消息分发给第n个消费端.

为了解决这种问题, 可以使用`basicQos`方法设置`prefetchCount=1`。告知RabbitMQ不要在一个时间点给消费端推送多条消息。换句话说, 不要分发新的消息给消费端, 除非消费诶段已经执行完成前一个消息。相反, RabbitMQ分发消息给下一个消费端
```java
int prefetchCount = 1;
channel.basicQos(prefetchCount);
```
