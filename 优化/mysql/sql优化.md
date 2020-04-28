### 优化路线

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

mysql服务状态：`mysqladmin -uzyd -pzyd ext`  相当于`show status`

- Queries ： 表示当前时间发生过的查询次数，要想知道一段时间的查询次数，查询两次做差即可

- Threads_connected：当前线程连接个数
- Threads_running： 当前进程运行个数
- Threads_cached：已经被线程缓存池缓存的线程个数
- Threads_created：表示创建过的线程数，如果发现Threads_created值过大的话，表明MySQL服务器一直在创建线程，这也是比较耗资源，可以适当增加配置文件中thread_cache_size值

```java
mysqladmin -uzyd -pzyd ext |awk '/Queries/{printf("%d\t",$4)}/Threads_connected/{printf("%d\t",$4)}/Threads_running/{printf("%d\n",$4)}'
```

### 优化思路

如果一台服务器出现长时间负载过高 /周期性负载过大,或偶尔卡住如何来处理?

- 是周期性的变化还是偶尔问题

- 是服务器整体性能的问题, 还是某单条语句的问题

- 具体到单条语句, 这条语句是在等待上花的时间,还是查询上花的时间

**监测并观察服务器的状态**

- `Show status`
- `Show processlist`: 显示当前所有连接的工作状态

#### 问题出现是否规律

- 周期性的变化,缓存同时失效影响。

- 不规则的延迟现象往往是由于效率低下的语句造成的,如何抓到这些效率低的语句。可以用`show processlist`命令长期观察,或用慢查询.

  ```java
  mysql  -uzyd -pzyd -e 'show processlist\G'|grep State:|sort|uniq -c|sort -rn
  ------------------
   5   State: Sending data
   2   State: statistics
   2   State: NULL
   1   State: Updating
   1   State: update
  -------------------
  ```

  ##### **以下几种状态要注意:**

  1. **converting HEAP to MyISAM** ：查询结果太大时,把结果放在磁盘 (语句写的不好,取数据太多)
  2. **create tmp table** ：创建临时表(如group时储存中间结果,说明索引建的不好)
  3. **Copying to tmp table** on disk：把内存临时表复制到磁盘 (索引不好,表字段选的不好)
  4. **locked** ：被其他查询锁住 (一般在使用事务时易发生,互联网应用不常发生) 

  ##### **什么情况下产生临时表?**

  1.  group by 的列和order by 的列不同时,两表联查时,取A表的内容,group/order by另外表的列
  2.  distinct 和 order by 一起使用时
  3. 开启了 SQL_SMALL_RESULT 选项
  4. 如果group by 的列没有索引,必产生内部临时表

  ##### 什么情况下临时表写到磁盘上?

  1. 取出的列含有text/blob类型时 ---内存表储存不了text/blob类型
  2. 在group by 或distinct的列中存在>512字节的string列
  3. select 中含有>512字节的string列,同时又使用了union或union all语句

  ##### 如果服务器频繁出现converting HEAP to MyISAM？

  1.  sql有问题,取出的结果或中间结果过大,内存临时表放不下

  2. 服务器配置的临时表内存参数过小
     - tmp_table_size 
     - max_heap_table_size  

#### sql 语句问题查找

如何定位到有问题的语句?

1. 开启服务器慢查询
2. 了解临时表的使用规则（explain ）      
3. 经验

**开启慢查询,观察到具体语句的执行步骤,查看是在那个步骤耗时。**

```java
// 查看是否开启慢查询
Show  variables like 'profiling' 
    
// 开启慢查询
set profiling=on

// 查看
show profiles
------------------------------------------------------
 Query_ID | Duration   | Query                           
        1 | 0.00073300 | SELECT DATABASE()               
        2 | 0.00734900 | select * from dict limit 1 
------------------------------------------------------

// 查看单条语句执行过程
show profile for query 1
+--------------------+----------+
| Status             | Duration |
+--------------------+----------+
| starting           | 0.000052 |
| Opening tables     | 0.000009 |
| System lock        | 0.000003 |
| Table lock         | 0.000006 |
| init               | 0.000016 |
... 省略...
| freeing items      | 0.000029 |
| logging slow query | 0.000002 |
| cleaning up        | 0.000019 |
+--------------------+----------+
15 rows in set (0.00 sec)
```

**explain 分析SQL语句**

**设计表:**

**建表:** 表结构的拆分,如核心字段都用int,char,enum等定长结构非核心字段,或用到text,超长的varchar,拆出来单放一张表。

**建索引:** 合理的索引可以减少内部临时表(索引优化策略里详解)

**写语句:** 不合理的语句将导致大量数据传输以及内部临时表的使用.