#### 1. 什么是 MQ

> 消息队列，又叫做消息中间件。是指用高效可靠的消息传递机制进行与平台无关的 数据交流，并基于数据通信来进行分布式系统的集成。通过提供消息传递和消息队列模 型，可以在分布式环境下扩展进程的通信（维基百科）。 基于以上的描述（MQ 是用来解决通信的问题），我们知道，MQ 的几个主要特点：

1. 是一个独立运行的服务。生产者发送消息，消费者接收消费，需要先跟 服务器建立连接。 

2.  采用队列作为数据结构，有先进先出的特点。 

3.  具有发布订阅的模型，消费者可以获取自己需要的消息

#### 2. MQ 作用

1. **异步：**对于数据量大或者处理耗时长的操作，我们可以引入 MQ 实现异步通信，减少客户端的等待，提升响应速度。 
2.  **解耦：**对于改动影响大的系统之间，可以引入 MQ 实现解耦，减少系统之间的直接依赖。
3.  **削峰：**对于会出现瞬间的流量峰值的系统，我们可以引入 MQ 实现流量削峰，达到保护应用和数据库的目的。

#### 3. 消息规范

​	2001 年，SUN 公司发布了 **JMS** 规范，它想要在各大厂商的 MQ 上面统一包装一层 Java 的规范，大家都只需要针对 API 编程就可以了， 不需要关注使用了什么样的消息中间件，只要选择合适的 MQ 驱动。但是 JMS 只适用于 Java 语言。以在 06 年的时候，**AMQP**（应用层协议） 规范发布了。它是跨语言和跨平台的，真正地促进了 消息队列的繁荣发展。

#### 4. RabbitMQ 简介

官网 https://www.rabbitmq.com/getstarted.html 

- 高可靠：RabbitMQ 提供了多种多样的特性让你在可靠性和性能之间做出权衡，包 括持久化、发送应答、发布确认以及高可用性。 
-  灵活的路由：通过交换机（Exchange）实现消息的灵活路由。
-  支持多客户端：对主流开发语言（Python、Java、Ruby、PHP、C#、JavaScript、 Go、Elixir、Objective-C、Swift 等）都有客户端实现。 
- 集群与扩展性：多个节点组成一个逻辑的服务器，支持负载。 
- 高可用队列：通过镜像队列实现队列中数据的复制。
-  权限管理：通过用户与虚拟机实现权限管理。 
- 插件系统：支持各种丰富的插件扩展，同时也支持自定义插件。 
- 与 Spring 集成：Spring 对 AMQP 进行了封装

##### 4.1 工作模型

![image-20210830195619189](D:\study\github\StudyNote\开发\消息中间件\img\image-20210830195619189.png)

1. Broker

   我们要使用 RabbitMQ 来收发消息，必须要安装一个 RabbitMQ 的服务，可以安装 在 Windows 上面也可以安装在 Linux 上面，默认是 5672 的端口。这台 RabbitMQ 的 服务器我们把它叫做 Broker，中文翻译是代理/中介，因为 MQ 服务器帮助我们做的事 情就是存储、转发消息。

2. Connection

   无论是生产者发送消息，还是消费者接收消息，都必须要跟 Broker 之间建立一个连 接，这个连接是一个 TCP 的长连接。

3. Channel

   如果所有的生产者发送消息和消费者接收消息，都直接创建和释放 TCP 长连接的话， 对于 Broker 来说肯定会造成很大的性能损耗，因为 TCP 连接是非常宝贵的资源，创建和 释放也要消耗时间。 所以在 AMQP 里面引入了 Channel 的概念，它是一个虚拟的连接。我们把它翻译 成通道，或者消息信道。这样我们就可以在保持的 TCP 长连接里面去创建和释放 Channel，大大了减少了资源消耗。另外一个需要注意的是，Channel 是 RabbitMQ 原 生 API 里面的最重要的编程接口，也就是说我们定义交换机、队列、绑定关系，发送消 息消费消息，调用的都是 Channel 接口上的方法。

4. Queue

   现在我们已经连到 Broker 了，可以收发消息了。在其他一些 MQ 里面，比如 ActiveMQ 和 Kafka，我们的消息都是发送到队列上的。 队列是真正用来存储消息的，是一个独立运行的进程，有自己的数据库（Mnesia）。 消费者获取消息有两种模式，一种是 Push 模式，只要生产者发到服务器，就马上推 送给消费者。另一种是 Pull 模式，消息存放在服务端，只有消费者主动获取才能拿到消 息。消费者需要写一个 while 循环不断地从队列获取消息吗？不需要，我们可以基于事 件机制，实现消费者对队列的监听。 咕泡出品，必属精品 www.gupaoedu.com 14 由于队列有 FIFO 的特性，只有确定前一条消息被消费者接收之后，才会把这条消息 从数据库删除，继续投递下一条消息。

5. Exchange

   在 RabbitMQ 里面永远不会出现消息直接发送到队列的情况。因为在 AMQP 里面 引入了交换机（Exchange）的概念，用来实现消息的灵活路由。 交换机是一个绑定列表，用来查找匹配的绑定关系。 队列使用绑定键（Binding Key）跟交换机建立绑定关系。 生产者发送的消息需要携带路由键（Routing Key），交换机收到消息时会根据它保 存的绑定列表，决定将消息路由到哪些与它绑定的队列上。 

   **注意：交换机与队列、队列与消费者都是多对多的关系**

6. Vhost

   我们每个需要实现基于 RabbitMQ 的异步通信的系统，都需要在服务器上创建自己 要用到的交换机、队列和它们的绑定关系。如果某个业务系统不想跟别人混用一个系统， 怎么办？再采购一台硬件服务器单独安装一个 RabbitMQ 服务？这种方式成本太高了。 在同一个硬件服务器上安装多个 RabbitMQ 的服务呢？比如再运行一个 5673 的端口？ 没有必要，因为 RabbitMQ 提供了虚拟主机 VHOST。 VHOST 除了可以提高硬件资源的利用率之外，还可以实现资源的隔离和权限的控 制。它的作用类似于编程语言中的 namespace 和 package，不同的 VHOST 中可以有 同名的 Exchange 和 Queue，它们是完全透明的。 5这个时候，我们可以为不同的业务系统创建不同的用户（User），然后给这些用户 分配 VHOST 的权限。比如给风控系统的用户分配风控系统的 VHOST 的权限，这个用户 可以访问里面的交换机和队列。给超级管理员分配所有 VHOST 的权限。

##### 4.2 路由方式

- **直连 Direct**

  队列与直连类型的交换机绑定，需指定一个精确的绑定键。 生产者发送消息时会携带一个路由键。只有当路由键与其中的某个绑定键完全匹配 时，这条消息才会从交换机路由到满足路由关系的此队列上。

- **主题 Topic**

  队列与主题类型的交换机绑定时，可以在绑定键中使用通配符。

  两个通配符： 

  `# 0 个或者多个单词`

  ` * 不多不少一个单词 `

  单词（word）指的是用英文的点“.”隔开的字符。例如 abc.def 是两个单词。

- **广播 Fanou**

  主题类型的交换机与队列绑定时，不需要指定绑定键。因此生产者发送消息到广播 类型的交换机上，也不需要携带路由键。消息达到交换机时，所有与之绑定了的队列， 都会收到相同的消息的副本。

##### 5. RabbitMQ 进阶知

##### 5.1 消息的过期时间

1.  通过队列属性设置消息过期时间 所有队列中的消息超过时间未被消费时，都会过期.

2.  设置单条消息的过期时间 在发送消息的时候指定消息属性。

如果同时指定了 Message TTL 和 Queue TTL，则小的那个时间生效。

##### 5.2 死信队列

​	消息在某些情况下会变成死信（Dead Letter）。 队列在创建的时候可以指定一个死信交换机 DLX（Dead Letter Exchange）。 死信交换机绑定的队列被称为死信队列 DLQ（Dead Letter Queue），DLX 实际上 也是普通的交换机，DLQ 也是普通的队列（例如替补球员也是普通球员）。

**什么情况下消息会变成死信？**

- 消息被消费者拒绝并且未设置重回队列：(NACK || Reject ) && requeue == false 

- 消息过期 

- 队列达到最大长度，超过了 Max length（消息数）或者 Max length bytes （字节数），最先入队的消息会被发送到 DLX。

![image-20210830212453721](D:\study\github\StudyNote\开发\消息中间件\img\image-20210830212453721.png)

##### 5.3 延迟队列

我们在实际业务中有一些需要延时发送消息的场景，

例如： 

1、 家里有一台智能热水器，需要在 30 分钟后启动 

2、 未付款的订单，15 分钟后关闭 RabbitMQ 本身不支持延迟队列，总的来说有三种实现方案： 

- 先存储到数据库，用定时任务扫描。

- 利用 RabbitMQ 的死信队列（Dead Letter Queue）实现 。

- 利用 rabbitmq-delayed-message-exchange 插件。

**使用死信队列实现延时消息的缺点：**

- 如果统一用队列来设置消息的 TTL，当梯度非常多的情况下，比如 1 分钟，2 分钟，5 分钟，10 分钟，20 分钟，30 分钟……需要创建很多交换机和队列来路由消息。 

- 如果单独设置消息的 TTL，则可能会造成队列中的消息阻塞——前一条消息没 有出队（没有被消费），后面的消息无法投递（比如第一条消息过期 TTL 是 30min，第二条消息 TTL 是 10min。10 分钟后，即使第二条消息应该投递了，但是由于第一条消息 还未出队，所以无法投递）。

-  可能存在一定的时间误差。

##### 5.4  服务端流控（Flow Control）

1. **x-max-length**：队列中最大存储最大消息数，超过这个数量，队头的消息会被丢。

2. **x-max-length-bytes**：队列中存储的最大消息容量（单位 bytes），超过这个容 量，队头的消息会被丢弃。

   需要注意的是，设置队列长度只在消息堆积的情况下有意义，而且会删除先入队的 消息，不能真正地实现服务端限流。

3. **内存控制：**RabbitMQ 会在启动时检测机器的物理内存数值。默认当 MQ 占用 40% 以上内 存时，MQ 会主动抛出一个内存警告并阻塞所有连接（Connections）。可以通过修改 rabbitmq.config 文件来调整内存阈值，默认值是 0.4。

4. **磁盘控制**：通过磁盘来控制消息的发布。当磁盘空间低于指定的值时（默认 50MB），触发流控措施。 例如：指定为磁盘的 30%或者 2GB

   ```
   disk_free_limit.relative = 3.0
   disk_free_limit.absolute = 2GB
   ```

##### 5.5 消费端限流

​	默认情况下，如果不进行配置，RabbitMQ 会尽可能快速地把队列中的消息发送到消费者。因为消费者会在本地缓存消息，如果消息数量过多，可能会导致 OOM 或者影 响其他进程的正常运行。 在消费者处理消息的能力有限，例如消费者数量太少，或者单条消息的处理时间过长的情况下，如果我们希望在一定数量的消息消费完之前，不再推送消息过来，就要用到消费端的流量限制措施。 可以基于 Consumer 或者 channel 设置 prefetch count 的值，端的最大的 unacked messages 数目。当超过这个数值的消息未被确认，RabbitMQ 会停止投递新的消息给该消费者。

```
spring.rabbitmq.listener.simple.prefetch=2
```

#### 6.1 Spring AMQP

​	Spring AMQP 是对 Spring 基于 AMQP 的消息收发解决方案，它是一个抽象层， 不依赖于特定的 AMQP Broker 实现和客户端的抽象，所以可以很方便地替换。

##### Spring AMQP 核心组件

1. **ConnectionFactory**

   Spring AMQP 的连接工厂接口，用于创建连接。CachingConnectionFactory 是 ConnectionFactory 的一个实现类。

2. **RabbitAdmin**

   RabbitAdmin 是 AmqpAdmin 的实现，封装了对 RabbitMQ 的基础管理操作，比 如对交换机、队列、绑定的声明和删除等。

3. **Message**

   Message 是 Spring AMQP 对消息的封装。 

   两个重要的属性： 

   ​	body：消息内容。 

   ​	messageProperties：消息属性

4. **RabbitTemplate 消息模板**

   ​	RabbitTemplate 是 AmqpTemplate 的一个实现（目前为止也是唯一的实现），用 来简化消息的收发，支持消息的确认（Confirm）与返回（Return）。跟 JDBCTemplate 一 样 ， 它 封 装 了 创 建 连 接 、 创 建 消 息 信 道 、 收 发 消 息 、 消 息 格 式 转 换 （ConvertAndSend→Message）、关闭信道、关闭连接等等操作。 针对于多个服务器连接，可以定义多个 Template。可以注入到任何需要收发消息的 地方使用。

5. **MessageListener 消息侦听**

   **MessageListener** 

   MessageListener 是 Spring AMQP 异步消息投递的监听器接口，它只有一个方法 onMessage，用于处理消息队列推送来的消息，作用类似于 Java API 中的 Consumer。 

   **MessageListenerContainer** 

   MessageListenerContainer可以理解为MessageListener的容器，一个Container 只有一个 Listener，但是可以生成多个线程使用相同的 MessageListener 同时消费消 息。 Container 可以管理 Listener 的生命周期，可以用于对于消费者进行配置。 例如：动态添加移除队列、对消费者进行设置，例如 ConsumerTag、Arguments、 并发、消费者数量、消息确认模式等等

   **MessageListenerContainerFactory**

   可以在消费者上指定，当我们需要监听多个 RabbitMQ 的服务器的时候，指定不同 的 MessageListenerContainerFactory。

6. **转换器 MessageConverto**

   **MessageConvertor 的作用？** 

   RabbitMQ 的消息在网络传输中需要转换成 byte[]（字节数组）进行发送，消费者需要对字节数组进行解析。 

   在 Spring AMQP 中，消息会被封装为 org.springframework.amqp.core.Message 对象。消息的序列化和反序列化，就是处理 Message 的消息体 body 对象。 如果消息已经是 byte[]格式，就不需要转换。 如果是 String，会转换成 byte[]。 如果是 Java 对象，会使用 JDK 序列化将对象转换为 byte[]（体积大，效率差）。 在 调 用 RabbitTemplate 的 convertAndSend() 方 法 发 送 消 息 时 ， 会 使 用 MessageConvertor 进行消息的序列化，默认使用 SimpleMessageConverter。 在某些情况下，我们需要选择其他的高效的序列化工具。如果我们不想在每次发送 消息时自己处理消息，就可以直接定义一个 MessageConvertor。

   **MessageConvertor 如何工作？**

    调用了 RabbitTemplate 的 convertAndSend() 方 法 时 会 使 用 对 应 的 MessageConvertor 进行消息的序列化和反序列化。 

   序列化：Object —— Json —— Message(body) —— byte[] 

   反序列化：byte[] ——Message —— Json —— Objec

   **有哪些 MessageConvertor？** 

   在 Spring 中提供了一个默认的转换器：SimpleMessageConverter。 Jackson2JsonMessageConverter（RbbitMQ 自带）：将对象转换为 json，然后再转换成字节数组进行传递。

   **如何自定义 MessageConverter？** 

   例如：我们要使用 Gson 格式化消息： 创建一个类，实现 MessageConverter 接口，重写 toMessage()和 fromMessage() 方法。 toMessage(): Java 对象转换为 Message 

   fromMessage(): Message 对象转换为 Java 对象。

