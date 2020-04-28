### 优化思路

![MySQL服务器调优思路.png](http://ww1.sinaimg.cn/large/0062TeRXgy1ge9dzeckryj30t81350vq.jpg)

### 性能测试

> 高性能不是指"绝对性能"强悍,而是指业务能发挥出硬件的最大水平，性能强的服务器并非"设计"而来,而是不断改进,提升短板。测试,就是量化找出短板的过程。只有会测试,能把数据量化，才能进一步改进优化。

#### 测试指标

- 吞吐量
     单位时间内的事务处理数,单位tps(每秒事务数)
- 响应时间
      语句平均响应时间,一般截取某段时间内,95%范围内的平均时间
- 并发性
     线程同时执行
- 可扩展性
    资源增加,性能也能正比增加

#### 测试工具

- sysbench

  支持多线程，支持多种数据库。主要包括以下几种测试：

  - cpu性能
  - 磁盘io性能
  - 调度程序性能
  - 内存分配及传输速度
  - POSIX线程性能
  - 数据库性能(OLTP基准测试)

- mysqlslap

  mysqlslap 可以用于模拟服务器的负载，并输出计时信息。测试时，可以指定并发连接数，可以指定 SQL 语句。如果没有指定 SQL 语句，mysqlslap 会自动生成查询 schema 的 SELECT 语句。

- tpcc-mysql

  TPC-C是专门针对联机交易处理系统（OLTP系统）的规范，一般情况下我们也把这类系统称为业务处理系统。

  TPC-C是TPC(Transaction Processing Performance Council)组织发布的一个测试规范，用于模拟测试复杂的在线事务处理系统。其测试结果包括每分钟事务数(tpmC)，以及每事务的成本(Price/tpmC)。

  在进行大压力下MySQL的一些行为时经常使用。

#### **AWK查看mysql服务性能指标**

mysql服务状态：`mysqladmin -uzyd -pzyd ext`  

- Queries ： 表示当前时间发生过的查询次数，要想知道一段时间的查询次数，查询两次做差即可

- Threads_connected：当前线程连接个数
- Threads_running： 当前进程运行个数
- Threads_cached：已经被线程缓存池缓存的线程个数
- Threads_created：表示创建过的线程数，如果发现Threads_created值过大的话，表明MySQL服务器一直在创建线程，这也是比较耗资源，可以适当增加配置文件中thread_cache_size值

```java
mysqladmin -uzyd -pzyd ext |awk '/Queries/{printf("%d\t",$4)}/Threads_connected/{printf("%d\t",$4)}/Threads_running/{printf("%d\n",$4)}'
```

