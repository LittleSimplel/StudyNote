### 概述

​	MapReduce是一种编程模型，用于大规模数据集（大于1TB）的并行运算。它们的主要思想，都是从**函数式编程**语言里借来的。每次一个步骤方法会产生一个状态，这个状态会直接当参数传进下一步中。而不是使用全局变量。

### MapReduce框架

- MapReduce将复杂的，运行大规模集群上的并行计算过程高度地抽象两个函数：Map和Reduce
- MapReduce采用“分而治之”策略，将一个分布式文件系统中的大规模数据集，分成许多独立的分片。这些分片可以被多个Map任务并行处理。
- MapReduce设计的一个理念就是“计算向数据靠拢”，而不是“数据向计算靠拢”，原因是，移动数据需要大量的网络传输开销
- MapReduce框架采用了Master/Slave架构，包括一个Master和若干个Slave，Master上运行JobTrackerSlave运行TaskTracker
- Hadoop框架是用JAVA来写的，但是,MapReduce应用程序则不一定要用Java来写

#### 角色

- JobTracker：初始化作业，分配作业，TaskTracker与其进行通信，协调监控整个作业
- TaskTracker：定期与JobTracker通信，执行Map和Reduce任务

- HDFS：保存作业的数据、配置、jar包、结果

#### 作业调度

FIFO调度器（默认）、公平调度器、容量调度器

- TaskTracker和JobTracker之间的通信与任务的分配是通过心跳机制完成的；

- TaskTracker会主动向JobTracker询问是否有作业要做，如果自己可以做，那么就会申请到作业任务，这个任务可以使Map也可能是Reduce任务

- TaskTraker将代码和配置信息到本地

- 分别为每一个Task启动JVM运行任务

- 任务在运行过程中，首先会将自己的状态汇报给TaskTracker，然后由TaskTracker汇总告之JobTracker

- 任务进度是通过计数器来实现的

- JobTracker是在接受到最后一个任务运行完成后，才会将作业标志为成功

### 编程模型

- **map()**

  ​	key/value 对作为输入，产生另外一系列 key/value 对**作为中间输出写入本地磁盘**。MapReduce 框架会自动将这些中间数据**按照 key 值进行聚集**，且 key 值相同（可设定聚集策略，默认情况下是对 key 值进行哈希取模）的数据被统一交给 reduce() 函数处理

- **reduce()** 

  ​	函数以 key 及对应的 value 列表作为输入，经合并 key 相同的 value 值后，产生另外一系列 key/value 对作为最终输出写入HDFS

**指定三个组件分别是 InputFormat、Partitioner 和 OutputFormat， 根据自己的应用需求配置：**

- ①指定输入 文件格式。将输入数据切分成若干个 split，且将每个 split 中的数据解析成一个个 map() 函数 要求的 key/value 对
- ②确定 map() 函数产生的每个 key/value 对发给哪个 Reduce Task 函数处 理
- ③指定输出文件格式，即每个 key/value 对以何种形式保存到输出文件中

### MapReduce作业运行流程

1. 在客户端启动一个作业

2. 向JobTracker请求一个Job ID。

3. 将运行作业所需要的**资源文件复制到HDFS上**，包括MapReduce程序打包的JAR文件、配置文件和客户端计算所得的输入划分信息。这些文件都存放在JobTracker专门为该作业创建的文件夹中。文件夹名为该作业的Job ID。JAR文件默认会有10个副本（mapred.submit.replication属性控制）。输入划分（根据block划分）信息告诉了JobTracker应该为这个作业启动多少个map任务等信息。

4. JobTracker接收到作业后，将其放在一个作业队列里，等待作业调度器对其进行调度，当作业调度器根据自己的调度算法调度到该作业时，会根据输入划分信息为每个划分创建一个map任务，并将map任务分配给TaskTracker执行。**map任务不是随机地分配给某个TaskTracker的，而是会将map任务分配给含有该map处理的数据块的TaskTracker上，同时将程序JAR包复制到该TaskTracker上来运行。这样的处理方式体现了mapreduce计算向数据靠拢的设计理念，好处是避免了移动数据需要大量的网络传输开销。**分配reduce任务时并不考虑数据本地化

5. TaskTracker每隔一段时间会给JobTracker发送一个心跳，告诉JobTracker它依然在运行，同时心跳中还携带着很多的信息，比如当前map任务完成的进度等信息。当JobTracker收到作业的最后一个任务完成信息时，便把该作业设置成“成功”。当JobClient查询状态时，它将得知任务已完成，便显示一条消息给用户

###  Map、Reduce任务阶段

- **输入分片**

  - 进行map计算之前，mapreduce会根据输入文件计算输入分片 (**根据hdfs的block切分**) ，每个输入分片针对一个map任务。会存在输入分片不均匀的情况。
  - 输入分片存储的并非数据本身，而是一个分片长度和一个记录数据的位置的数组

- **map阶段**

  **combiner阶段：**

  - combiner阶段操作是可选的，combiner其实也是一种reduce操作，Combiner是一个本地化的reduce操作，它是**map运算的后续操作，主要是在reduce计算出中间文件前做一个简单的合并重复key值的操作**。
  - 在reduce计算前对相同的key做一个合并操作，文件会变小，提高了宽带的传输效率
  - **注意：**使用它的原则是combiner的输入不会影响到reduce计算的最终输入，如：如果计算只是求总数，最大值，最小值可以使用combiner，但是做平均值计算使用combiner的话，最终的reduce计算结果就会出错。

- **shuffle阶段**

  - 将map的输出作为reduce的输入的过程就是shuffle
  - Shuffle一开始就是map阶段做输出操作，一般mapreduce计算的都是海量数据，map输出时候不可能把所有文件都放到内存操作，因此map写入磁盘的过程十分的复杂，更何况map输出时候要对结果进行排序，内存开销是很大的，map在做输出时候会在**内存里开启一个环形内存缓冲区**，这个缓冲区专门用来输出的，**默认大小是100mb**，并且在配置文件里为这个缓冲区设定了一个**阀值，默认是0.80**（这个大小和阀值都是可以在配置文件里进行配置的），同时map还会为输出操作启动一个守护线程，如果缓冲区的内存达到了阀值的80%时候，这个守护线程就会把内容写到磁盘上，这个过程叫spill，另外的20%内存可以继续写入要写进磁盘的数据，**写入磁盘和写入内存操作是互不干扰的，如果缓存区被撑满了，那么map就会阻塞写入内存的操作，让写入磁盘操作完成后再继续执行写入内存操作**。
  - 写入磁盘前会有个排序操作，这个是在写入磁盘操作时候进行，不是在写入内存时候进行的，如果我们定义了combiner函数，那么排序前还会执行combiner操作。每次spill操作也就是写入磁盘操作时候就会写一个溢出文件，也就是说在做map输出有几次spill就会产生多少个溢出文件，
  - 等map输出全部做完后，map会合并这些输出文件。这个过程里还会有一个**Partitioner**操作，对于这个操作很多人都很迷糊，其实Partitioner操作和map阶段的输入分片（Input split）很像，一个Partitioner对应一个reduce作业，如果我们mapreduce操作只有一个reduce操作，那么Partitioner就只有一个，如果我们有多个reduce操作，那么Partitioner对应的就会有多个，Partitioner因此就是reduce的输入分片，这个程序员可以编程控制，主要是根据实际key和value的值，根据实际业务类型或者为了更好的reduce负载均衡要求进行，这是提高reduce效率的一个关键所在。到了reduce阶段就是合并map输出文件了，Partitioner会找到对应的map输出文件，然后进行复制操作，复制操作时reduce会开启几个复制线程，这些线程默认个数是5个，程序员也可以在配置文件更改复制线程的个数，这个复制过程和map写入磁盘过程类似，也有阀值和内存大小，阀值一样可以在配置文件里配置，而内存大小是直接使用reduce的tasktracker的内存大小，复制时候reduce还会进行排序操作和合并文件操作，这些操作完了就会进行reduce计算了。
  - 数据分组 决定了Map task输出的每条数据交给哪个Reduce Task处理。**默认实现：hash(key) mod R R是Reduce Task数目，允许用户自定义**，很多情况下需要自定义Partitioner ，比如“hash(hostname(URL)) mod R”确保相同域名的网页交给同一个Reduce Task处理 属于（map）阶段。

