# Publisher / Subscriber

## Exchanges
在前面的张杰中, 我们通过一个队列`queue`实现发送和接收消息。接下来我们将介绍rabbitMQ的
全消息模式.

让我们快速地查看一下前面所讲述的内容:
- 一个消息生产方(producer)是通过用户应用发送消息
- 一个队列(queue)是一个缓存用于存储消息
- 一个消费方(consumer)通过用户应用来接收消息

消息模式的核心思想是, producer不会直接将消息发送到队列中. 实际上, producer甚至不知道消息
将会发送到哪一个队列.

相反, `producer`只能够发送消息到`exchange`。 一个`exchange`是很简单的组件。一方面`exchange`
从`producer`中接收消息，另一方面`exchange`将消息推送到`queue`中。对于`exchange`而言,
必须知道在接收到一个消息之后, 必须要做什么事情。
- 消息是否添加到一个特殊的队列中
- 消息是否添加到一些队列中
- 或者直接放弃该消息.

这些配置信息将会被定义在`exchange`中。

### exchanges 类型设置
对于`exchange`有一些可用的类型: `direct`, `topic`, `headers`, `fanout`. 这里我们主要关注
`fanout`的使用。
```java
channel.exchangeDeclare("logs", "fanout")
```
> NOTE: `fanout`类型exchange很简单, 它只是广播所有的消息到exchange所知道的`queue`中

### Listing exchanges
为了能够列举出所有的`exchange`, 可以通过`rabbitmqctl`命令:
```sh
sudo rabbitmqctl list_exchanges
```

在命令返回的结果中, 有许多以`amq.*`列表, 和默认的exchange信息(未命名). 这些`exchange`
是默认被创建的，可以在任何时候使用它们。

#### Nameless exchange
在前面的张杰中, 我们在发送消息时没有设置exchange, 依然能够发送消息到queue中。那是因为
我们使用了默认的`exchange`， 我们通过`""`来进行标记.

回归一下发送消息的代码:
```java
channel.basicPublish("", "hello", null, message.getBytes());
```

- 第一个参数时`exchange`的名称, 空串代表了默认的`exchange`或者未命名的`exchange`
- 第二个参数表明了，所有的消息最终被路由到了`hello`的队列上。

### 通过exchange发送消息
```java
channel.basicPublish("logs", "", null, message.getBytes())
```

## Tempoary queues
在前面的例子中, 我们可以定义一个队列， 我们需要将工作线程直线该队列。为队列命名是很重要的,
因为队列主要用于在消息生产端和消息消费端进行消息的传递。

在日志的案例中, 我们期望能够接受到所有的消息, 而不是消息的一部分。 所以我们更加关注的是最新的
消息，而不是老的消息本身，为了能够解决这样的问题, 需要有一下两步:
- 无论什么时候链接Rabbit, 我们需要一个新的, 空的队列。为了实现这样的目的, 我们可以创建一个随机的名称,——这么做可以让Rabbit服务器选择一个随机的队列给我们使用
- 一旦我们断开消费端(consumer), 对应的队列需要被自动删除

在`java`客户端中, 可以通过没有参数的`queueDeclare()`创建一个无持久化, 自动删除的队列:
```java
String queueName = channel.queueDeclare().getQueue();
```

通过以上设置, `queueName`包含一个随机的队列名称.

## Binds
在上面的例子中, 我们已经创建了`fanout exchange`和一个队列, 现在我们需要告诉`exchange`发送消息到我们的
队列中, 建立`exchange`和`queue`之间的关系被称作`binding`.

```java
channel.queueBind(queueName, "logs", "");
```

从现在开始, `logs` exchange将会追加消息到队列之上`queue`

> NOTE: Listing bindings: 我们可以通过命令的方式查看绑定的列表:
> `rabbitmqctl list_bindings`

## Putting it all together
```java
public class EmitLog {

  private static final String EXCHANGE_NAME = "logs";

  public static void main(String[] argv) throws Exception {
    ConnectionFactory factory = new ConnectionFactory();
    factory.setHost("localhost");
    try (Connection connection = factory.newConnection();
         Channel channel = connection.createChannel()) {
        channel.exchangeDeclare(EXCHANGE_NAME, "fanout");

        String message = argv.length < 1 ? "info: Hello World!" :
                            String.join(" ", argv);

        channel.basicPublish(EXCHANGE_NAME, "", null, message.getBytes("UTF-8"));
        System.out.println(" [x] Sent '" + message + "'");
    }
  }
}
```

从上面代码中我们可以看出, 在建立起链接之后, 我们声明了一个`exchange`。这一步对于向一个不存在的exchange发送消息是不允许的。

>NOTE: 消息将会被丢失, 如果没有queue绑定到exchage. 但是对于如果没有消费端处于监听状态, RabbitMQ将会直接抛弃消息。

`RecevieLog.java`
```java
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.DeliverCallback;

public class ReceiveLogs {
  private static final String EXCHANGE_NAME = "logs";

  public static void main(String[] argv) throws Exception {
    ConnectionFactory factory = new ConnectionFactory();
    factory.setHost("localhost");
    Connection connection = factory.newConnection();
    Channel channel = connection.createChannel();

    channel.exchangeDeclare(EXCHANGE_NAME, "fanout");
    String queueName = channel.queueDeclare().getQueue();
    channel.queueBind(queueName, EXCHANGE_NAME, "");

    System.out.println(" [*] Waiting for messages. To exit press CTRL+C");

    DeliverCallback deliverCallback = (consumerTag, delivery) -> {
        String message = new String(delivery.getBody(), "UTF-8");
        System.out.println(" [x] Received '" + message + "'");
    };
    channel.basicConsume(queueName, true, deliverCallback, consumerTag -> { });
  }
}
```
