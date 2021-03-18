### 概述

1. HDFS集群分为两大角色:NameNode、DataNode
2. NameNode负责客户端请求的响应，元数据的管理(查询、修改)
3. DataNode负责管理用户的文件数据块(数据块的读/写操作)
4. 文件会按照固定的大小(blocksize)切成若干块后分布式存储在若干台datanode上
5. 每一个文件块可以有多个副本，并存放在不同的datanode上
6. DataNode会**定期**向NameNode汇报自身所保存的文件block信息，而namenode则会负责保持文件的副本数量
7. HDFS的内部工作机制对客户端保持透明，**客户端请求访问HDFS都是通过向namenode申请来进行**

### 写数据流程

#### 概述

​	客户端要向HDFS写数据，首先要跟namenode通信以确认可以写文件并获得接收文件block的datanode，然后客户端按顺序将文件逐个block传递给相应datanode(client 直连datanode)，并由接收到block的datanode负责向其他datanode复制block的副本。

**注意：**切割是在客户端实现的，而不是NameNode。文件的传输也是由客户端传到指定datanode上，副本由datanode传给其他datanode

#### 步骤流程

1.  跟namenode通信请求上传文件，namenode检查目前文件是否已存在，父目录是否存在
2.  namenode返回是否可以上传
3.  client请求第一个block该传输到哪些datanode服务器上(副本)
4.  namenode返回3个datanode服务器ABC(假如副 本数为3。优先找同机架的，其次不同机架，再其次是同机架的再一台机器。还会根据服务器的容量，)
5.  client请求3台datanode中的一台A上传数据(本质上是一个RPC调用，建立pipeline)，A收到请求会继续调用B，然后B调用C，将整个pipeline建立完成，逐级返回客户端
6.  client开始往A上传第一个block(先从磁盘读取数据放到一个本地内存缓存)，以packet为单位，A收到一个packet就会传给B，B传给C；A每传一个packet会放入一个应答队列等待应答。
7.  当一个block传输完成之后，client再次请求namenode上传第二个block的服务器。

### 读数据流程

#### 概述

​	客户端将要读取的文件路径发给namenode，namenode获取文件的元信息(主要是block的存放位置信息)返回给客户端，客户端根据返回的信息找到相应datanode逐个获取文件的block并在**客户端进行数据追加合并从而获得整个文件**。

#### 步骤流程

1.  跟namenode通信查询元数据，找到文件块所在的datanoede服务器
2.  挑选一台datanode(就近原则，然后随机)服务器，请求建立socket流
3.  datanode开始发送数据(从磁盘里面读取数据放入流，以packet为单位来做校验)
4.  客户端以packet为单位接收，先在本地缓存，然后写入目标文件

### HDFS不适合的应用类型

- 低时间延迟的访问：要求低时间延迟的数据访问的应用，不适合在HDFS上运行。HDFS是提高数据吞吐量的应用优化的，但可能会以提高时间延迟为代价。
- 大量小文件不适合：由于namenode将文件系统的元数据存储在内存中，因此文件系统所能存储的文件数量受限制于namenode的内存容量。
- 并发写入，文件随机修改：一个文件只有一个写线程，不能多个线程同时读写，仅支持文件的追加（append），不支持修改。

