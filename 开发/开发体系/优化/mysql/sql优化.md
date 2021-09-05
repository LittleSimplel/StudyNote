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

#### 表的优化与列类型选择

##### 表的优化

1. 定长与变长分离

   核心且常用字段,宜建成定长,放在一张表；而varchar, text,blob,这种变长字段,适合单放一张表, 用主键与核心表关联起来

2. 常用字段和不常用字段要分离.

   需要结合网站具体的业务来分析,分析字段的查询场景,查询频度低的字段,单拆出来.

3. 冗余字段和冗余表（减少表的关联查询）
4. 主键的选择:
   - 在myisam中,字符串索引会被压缩,用字符串做主键性能不如整型
   - 用递增的值,不要用离散的值,离散值会导致文件在磁盘的位置有间隔,浪费空间且不易连续读取

##### 列选择原则

1. 字段类型优先级` 整型 > date/time > enum/char>varchar > blob/text`

   整型: 定长,没有国家/地区之分,没有字符集的差异

   time定长,运算快,节省空间. 考虑时区,写sql时不方便 where > ‘2005-10-12’;

   enum: 能起来约束值的目的, 内部用整型来存储,但与char联查时,内部要经历串与值的转化

   Char 定长, 考虑字符集和(排序)校对集

   varchar, 不定长 要考虑字符集的转换与排序时的校对集,速度慢.

   text/Blob 无法使用内存临时表

   **emp:**

   性别:  以utf8为例

   char(1) , 3个字长字节

   enum(‘男’,’女’);  // 内部转成数字来存,多了一个转换过程

   tinyint() ,  // 0 1 2 // 定长1个字节.

2. 够用就行,不要慷慨 (如smallint,varchar(N))

   原因: 大的字段浪费内存,影响速度,

   以年龄为例 tinyint unsigned not null ,可以存储255岁,足够. 用int浪费了3个字节

   以varchar(10) ,varchar(300)存储的内容相同, 但在表联查时,varchar(300)要花更多内存

3. 尽量避免用NULL()

   原因: NULL不利于索引,要用特殊的字节来标注,在磁盘上占据的空间其实更大.

###### Enum列的说明

1. enum列在内部是用整型来储存的

2. enum列与enum列相关联速度最快

3. enum列比(var)char 的弱势---在碰到与char关联时,要转化. 要花时间.

4. 优势在于,当char非常长时,enum依然是整型固定长度.

   当查询的数据量越大时,enum的优势越明显.

5. enum与char/varchar关联 ,因为要转化,速度要比enum->enum,char->char要慢,

   但有时也这样用-----就是在数据量特别大时,可以节省IO.

#### 索引优化策略

###### 理想的索引

1. 查询频繁 
2. 区分度高
3. 长度小  
4.  尽量能覆盖常用查询字段

##### 索引类型

1. B-tree索引

     注: 名叫btree索引,大的方面看,都用的平衡树,但具体的实现上, 各引擎稍有不同

     比如,严格的说,NDB引擎,使用的是T-tree

     Myisam,innodb中默认用B-tree索引

     但抽象一下---B-tree系统,可理解为”排好序的快速查找结构”. 

2. hash索引

​     在memory表里,默认是hash索引, hash的理论查询时间复杂度为O(1)

**疑问: 既然hash的查找如此高效,为什么不都用hash索引?**

- hash函数计算后的结果,是随机的,如果是在磁盘上放置数据,比主键为id为例, 那么随着id的增长, id对应的行,在磁盘上随机放置.

- 无法对范围查询进行优化

- 无法利用前缀索引. 比如 在btree中, field列的值“hellopworld”,并加索引

  查询 xx=helloword,自然可以利用索引, xx=hello,也可以利用索引. (左前缀索引)

  因为hash(‘helloword’),和hash(‘hello’),两者的关系仍为随机

- 排序也无法优化.

- 必须回行.就是说 通过索引拿到数据位置,必须回到表中取数据

**btree索引的常见误区**

1.  在where条件常用的列上都加上索引

     例: where cat_id=3 and price>100 ; //查询第3个栏目,100元以上的商品

     误: cat_id上,和, price上都加上索引

     错: 只能用上cat_id或Price索引,因为是独立的索引,同时只能用上1个

2. 在多列上建立索引后,查询哪个列,索引都将发挥作用

   **多列索引上,索引发挥作用,需要满足左前缀要求**

   以 index(a,b,c) 为例,

   | 语句                                 | 索引是否发挥作用           |
   | ------------------------------------ | -------------------------- |
   | Where a=3                            | 是, 只使用了a列            |
   | Where a=3 and b=5                    | 是,使用了a,b列             |
   | Where a=3 and b=5 and c=4            | 是,使用了abc               |
   | Where b=3  或者 where c=4            | 否                         |
   | Where a=3 and c=4                    | a列能发挥索引 , c不能      |
   | Where a=3 and b>10 and c=7           | A能利用,b能利用, C不能利用 |
   | where a=3 and b like ‘xxxx%’ and c=7 | A能用,B能用,C不能用        |

   多列索引经典题目: <http://www.zixue.it/thread-9218-1-4.html>

##### 聚簇索引与非聚簇索引

**Myisam与innodb引擎,索引文件的异同**

- Myisam 
- innodb

##### 索引覆盖

索引覆盖是指 如果查询的列恰好是索引的一部分,那么查询只需要在索引文件上进行,**不需要回行到磁盘再找数据**.

这种查询速度非常快,称为”索引覆盖”

##### 索引长度与区分度

1. 索引长度直接影响索引文件的大小,影响增删改的速度,并间接影响查询速度(占用内存多)

   针对列中的值,从左往右截取部分,来建索引

2. 截的越短, 重复度越高,区分度越小, 索引效果越不好

3.  截的越长, 重复度越低,区分度越高, 索引效果越好,但带来的影响也越大--增删改变慢,并间影响查询速度.

   所以, 我们要在  区分度 + 长度  两者上,取得一个平衡.

   惯用手法: 截取不同长度,并测试其区分度