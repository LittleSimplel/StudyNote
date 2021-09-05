#### 1. 可靠性消息投递

在我们使用 RabbitMQ 收发消息的时候，有几个主要环节：

![image-20210831200841775](D:\study\github\StudyNote\开发\消息中间件\img\image-20210831200841775.png)

- ①代表消息从生产者发送到 Broker

  生产者把消息发到 Broker 之后，怎么知道自己的消息有没有被 Broker 成功接收？

- ②代表消息从 Exchange 路由到 Queue

  Exchange 是一个绑定列表，如果消息没有办法路由到正确的队列，会发生什么 事情？应该怎么处理？

- ③ 代表消息在 Queue 中存储

  队列是一个独立运行的服务，有自己的数据库（Mnesia），它是真正用来存储消 息的。如果还没有消费者来消费，那么消息要一直存储在队列里面。如果队列出了问 题，消息肯定会丢失。怎么保证消息在队列稳定地存储呢？

- ④代表消费者订阅 Queue 并消费消

  队列的特性是什么？FIFO。队列里面的消息是一条一条的投递的，也就是说，只 有上一条消息被消费者接收以后，才能把这一条消息从数据库删掉，继续投递下一条 消息。那么问题来了，Broker 怎么知道消费者已经接收了消息呢？

**① 消息发送到 RabbitMQ 服务器**

​		第一个环节是生产者发送消息到 Broker。可能因为网络或者 Broker 的问题导致消息 发送失败，生产者不能确定 Broker 有没有正确的接收。 在 RabbitMQ 里面提供了两种机制服务端确认机制，也就是在生产者发送消息给 RabbitMQ 的服务端的时候，服务端会通过某种方式返回一个应答，只要生产者收到了 这个应答，就知道消息发送成功了。

**第一种 Transaction（事务）模式**：它是阻塞的，一条消 息没有发送完毕，不能发送下一条消息，它会榨干 RabbitMQ 服务器的性能。所以不建 议大家在生产环境使用。

**第二种 Confirm（确认）模式**：批量确认

**第三种 异步确认模式**

```java
rabbitTemplate.setConfirmCallback(new RabbitTemplate.ConfirmCallback() {
	@Override
	public void confirm(CorrelationData correlationData, boolean ack, String cause) {
		if (!ack) {
			System.out.println("发送消息失败：" + cause);
			throw new RuntimeException("发送异常：" + cause);
		}
	}
});
```

**② 消息从交换机路由到队列**

第二个环节就是消息从交换机路由到队列。在什么情况下，消息会无法路由到正确 的队列？可能因为路由键错误，或者队列不存在。 我们有两种方式处理无法路由的消息，**一种就是让服务端回发给生产者**，一种是让 交换机路由到另一个备份的交换机。 消息回发的方式：使用 mandatory 参数和 ReturnListener（在 Spring AMQP 中是 ReturnCallback）。

```java
rabbitTemplate.setMandatory(true);
rabbitTemplate.setReturnCallback(new RabbitTemplate.ReturnCallback(){
public void returnedMessage(Message message, int replyCode, String replyText, String exchange, String routingKey){
		System.out.println("回发的消息：");
		System.out.println("replyCode: "+replyCode);
		System.out.println("replyText: "+replyText);
		System.out.println("exchange: "+exchange);
		System.out.println("routingKey: "+routingKey);
	}
});
```

**③ 消息在队列存储**

如果 RabbitMQ 的服务或者硬件发生故障，比如系统宕机、重启、关闭等等，可能 会导致内存中的消息丢失，所以我们要把消息本身和元数据（队列、交换机、绑定）都 保存到磁盘。

**解决方案：** 

- 队列持久化：RabbitConfig.java

  ```java
  @Bean("GpExchange")
  public DirectExchange exchange() {
  // exchangeName, durable, exclusive, autoDelete, Properties
  return new DirectExchange("GP_TEST_EXCHANGE", true, false, new HashMap<>());
  ```

- 交换机持久化: 

  ```java
  @Bean("GpExchange")
  public DirectExchange exchange() {
  // exchangeName, durable, exclusive, autoDelete, Properties
  return new DirectExchange("GP_TEST_EXCHANGE", true, false, new HashMap<>());
  }
  ```

- 消息持久化

  ```java
  MessageProperties messageProperties = new MessageProperties();
  messageProperties.setDeliveryMode(MessageDeliveryMode.PERSISTENT);
  Message message = new Message("持久化消息".getBytes(), messageProperties);
  rabbitTemplate.send("GP_TEST_EXCHANGE", "gupao.test", message);
  ```

- 集群

  如果只有一个 RabbitMQ 的节点，即使交换机、队列、消息做了持久化，如果服务 崩溃或者硬件发生故障，RabbitMQ 的服务一样是不可用的，所以为了提高 MQ 服务的 可用性，保障消息的传输，我们需要有多个 RabbitMQ 的节点.

**④ 消息投递到消费者**

​		如果消费者收到消息后没**来得及处理即发生异常，或者处理过程中发生异常**，会导致④失败。服务端应该以某种方式得知消费者对消息的接收情况，并决定是否重新投递 这条消息给其他消费者。

​		RabbitMQ 提供了消费者的消息确认机制（message acknowledgement），消费 者可以**自动或者手动地发送 ACK 给服务**。

​		没有收到 ACK 的消息，消费者断开连接后，RabbitMQ 会把这条消息发送给其他消 费者。如果没有其他消费者，消费者重启后会重新消费这条消息，重复执行业务逻辑。

​		消费者在订阅队列时，可以指定 autoAck参数，当 autoAck 等于 false 时，**RabbitMQ 会等待消费者显式地回复确认信号后才从队列中移去消息。**

**如何设置手动 ACK？**

SimpleRabbitListenerContainer 或者 SimpleRabbitListenerContainerFactory

```
spring.rabbitmq.listener.direct.acknowledge-mode=manual
spring.rabbitmq.listener.simple.acknowledge-mode=manual
```

注意这三个值的区别：

**NONE：自动 ACK。消息一旦被接收，消费者自动发送ACK**

**MANUAL： 手动 ACK 。消息接收后，不会发送ACK，需要手动调用**

AUTO：如果方法未抛出异常，则发送 ack。 当抛出 AmqpRejectAndDontRequeueException 异常的时候，则消息会被拒绝， 且不重新入队。当抛出 ImmediateAcknowledgeAmqpException 异常，则消费者会发送 ACK。其他的异常，则消息会被拒绝，且 requeue = true 会重新入队。

**这两ACK要怎么选择呢？这需要看消息的重要性：**

- 如果消息不太重要，丢失也没有影响，那么自动ACK会比较方便
- 如果消息非常重要，不容丢失。那么最好在消费完成后手动ACK，否则接收消息后就自动ACK，RabbitMQ就会把消息从队列中删除。如果此时消费者宕机，那么消息就丢失了。

**如果消息无法处理或者消费失败**，也有两种拒绝的方式，Basic.Reject()拒绝单条， Basic.Nack()批量拒绝。如果 requeue 参数设置为 true，可以把这条消息重新存入队列， 以便发给下一个消费者（当然，只有一个消费者的时候，这种方式可能会出现无限循环 重复消费的情况。可以投递到新的队列中，或者只打印异常日志）。

**服务端收到了 ACK 或者 NACK，生产者会知道吗？即使消费者没有接收到消 息，或者消费时出现异常，生产者也是完全不知情的**

是生产者最终确定消费者有没有消费成功的两种方式： 

- 消费者收到消息，处理完毕后，调用生产者的 API（破坏解耦？） 

- 消费者收到消息，处理完毕后，发送一条响应消息给生产者

 **补偿机制**

如果生产者的 API 就是没有被调用，也没有收到消费者的响应消息，怎么办？**可能是消费者处理时间太长或者网络超时。**

**生产者与消费者之间应该约定一个超时时间，比如 5 分钟，对于超出这个时间没有 得到响应的消息，可以设置一个定时重发的机制，但要发送间隔和控制次数，比如每隔 2 分钟发送一次，最多重发 3 次，否则会造成消息堆积。**

- **重发可以通过消息落库+定时任务来实现。**

重发，是否发送一模一样的消息？

参考： ATM 机上运行的系统叫 C 端（ATMC），前置系统叫 P 端（ATMC），它接收 ATMC 的消息，再转发给卡系统或者核心系统。 1）如果客户存款，没有收到核心系统的应答，不知道有没有记账成功，最多发送 5 次存款确认报文，因为已经吞钞了，所以要保证成功2）如果客户取款，ATMC 未得到应答时，最多发送 5 次存款冲正报文。因为没有吐 钞，所以要保证失败。

#### 2. 消息幂等性

如果消费者每一次接收生产者的消息都成功了，只是在响应或者调用 API 的时候出 了问题，会不会出现消息的重复处理？例如：存款 100 元，ATM 重发了 5 次，核心系统 一共处理了 6 次，余额增加了 600 元。

为了避免相同消息的重复处理，必须要采取一定的措施。RabbitMQ 服务端 是没有这种控制的（同一批的消息有个递增的 DeliveryTag），它不知道你是不是就要把 一条消息发送两次，只能在消费端控制。

消息出现重复可能会有三个原因：

1. **生产者的问题，环节①重复发送消息，比如在开启了 Confirm 模式但未收到 确认，消费者重复投递。**
2. **环节④出了问题，由于消费者未发送 ACK 或者其他原因，消息重复投递。** 
3. **生产者代码或者网络问题。**

如何避免消息的重复消费？

- 对于重复发送的消息，可以对每一条消息生成一个唯一的业务 ID，通过日志或者消 息落库来做重复控制。
- 分布式锁

#### 3. 最终一致

​		如果确实是消费者宕机了，或者代码出现了 BUG 导致无法正常消费，在我们尝试多 次重发以后，消息最终也没有得到处理，怎么办？ 例如存款的场景，客户的钱已经被吞了，但是余额没有增加，这个时候银行出现了 长款，应该怎么处理？如果客户没有主动通知银行，这个问题是怎么发现的？银行最终 怎么把这个账务做平？ 在我们的金融系统中，都会有双方对账或者多方对账的操作，通常是在一天的业务 结束之后，第二天营业之前。我们会约定一个标准，比如 ATM 跟核心系统对账，肯定是 以核心系统为准。ATMC 获取到核心的对账文件，然后解析，登记成数据，然后跟自己 记录的流水比较，找出核心有 ATM 没有，或者 ATM 有核心没有，或者两边都有但是金 额不一致的数据。 对账之后，我们再手工平账。比如取款记了账但是没吐钞的，做一笔冲正。存款吞 了钞没记账的，要么把钱退给客户，要么补一笔账。

#### 4. 消息的顺序性

​		消息的顺序性指的是消费者消费消息的顺序跟生产者生产消息的顺序是一致的。 例如：商户信息同步到其他系统，有三个业务操作：1、新增门店 2、绑定产品 3、 激活门店，这种情况下消息消费顺序不能颠倒（门店不存在时无法绑定产品和激活）。 又比如：1、发表微博；2、发表评论；3、删除微博。顺序不能颠倒。 在 RabbitMQ 中，一个队列有多个消费者时，由于不同的消费者消费消息的速度是 不一样的，顺序无法保证。只有一个队列仅有一个消费者的情况才能保证顺序消费（不同的业务消息发送到不同的专用的队列）。 除非负载的场景，不要用多个消费者消费消息。

#### 5. 集群与高可用

##### 5.1 为什么要做集群？

集群主要用于实现高可用与负载均衡。 高可用：如果集群中的某些 MQ 服务器不可用，客户端还可以连接到其他 MQ 服务 器。 负载均衡：在高并发的场景下，单台 MQ 服务器能处理的消息有限，可以分发给多 台 MQ 服务器。 

RabbitMQ 有两种集群模式：**普通集群模式和镜像队列模式。**

##### 5.2RabbitMQ 如何支持集群？

应用做集群，需要面对数据同步和通信的问题。因为 Erlang 天生具备分布式的特性， 所以 RabbitMQ 天然支持集群，不需要通过引入 ZK 或者数据库来实现数据同步。 **RabbitMQ 通过/var/lib/rabbitmq/.erlang.cookie 来验证身份，需要在所有节点上 保持一致**

##### 5.3 RabbitMQ 的节点类型？

集群有两种节点类型，一种是磁盘节点（Disc Node），一种是内存节点（RAM Node）。 

- **磁盘节点：将元数据（包括队列名字属性、交换机的类型名字属性、绑定、vhost） 放在磁盘中。 **

- **内存节点：**将元数据放在内存中。 

  PS：内存节点会将磁盘节点的地址存放在磁盘（不然重启后就没有办法同步数据了）。 如果是持久化的消息，会同时存放在内存和磁盘。 集群中至少需要一个磁盘节点用来持久化元数据，否则全部内存节点崩溃时，就无 从同步元数据。未指定类型的情况下，默认为磁盘节点。 我们一般把应用连接到内存节点（读写快），磁盘节点用来备份。

集群通过 25672 端口两两通信，需要开放防火墙的端口。 需要注意的是，**RabbitMQ 集群无法搭建在广域网**上，除非使用 federation 或者 shovel 等插件（没这个必要，在同一个机房做集群）。

集群的配置步骤： 

1. 配置 hosts 
2. 同步 erlang.cookie 
3. 加入集群（join cluster）

##### 5.4 普通集群

<img src="D:\study\github\StudyNote\开发\消息中间件\img\image-20210831213105622.png" alt="image-20210831213105622" style="zoom:67%;" />

疑问：为什么不直接把队列的内容（消息）在所有节点上复制一份？ 

主要是出于存储和同步数据的网络开销的考虑，如果所有节点都存储相同的数据， 就无法达到线性地增加性能和存储容量的目的（堆机器）。 假如生产者连接的是节点 3，要将消息通过交换机 A 路由到队列 1，最终消息还是会 转发到节点 1 上存储，因为队列 1 的内容只在节点 1 上。 同理，如果消费者连接是节点 2，要从队列 1 上拉取消息，消息会从节点 1 转发到 节点 2。其它节点起到一个路由的作用，类似于指针。 普通集群模式不能保证队列的高可用性，因为队列内容不会复制。如果节点失效将 导致相关队列不可用，因此我们需要第二种集群模式。

##### 5.5 镜像集群

第二种集群模式叫做镜像队列。 镜像队列模式下，消息内容会在镜像节点间同步，可用性更高。不过也有一定的副作用，系统性能会降低，节点过多的情况下同步的代价比较大。

| 操作方式              | 操作方式                                                     |
| --------------------- | ------------------------------------------------------------ |
| rabbitmqctl (Windows) | rabbitmqctl set_policy ha-all "^ha." "{""ha-mode"":""all""}" |
| HTTP API              | PUT /api/policies/%2f/ha-all {"pattern":"^ha.", "definition":{"ha-mode":"all"}} |
| Web UI                | 1、avigate to Admin > Policies > Add / update a policy <br />2、Name 输入：mirror_image <br />3、Pattern 输入：^（代表匹配所有）<br />4、Definition 点击 HA mode，右边输入：all <br />5、Add policy |

