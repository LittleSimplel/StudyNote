### hive

1. 官网 下载 上传 解压 

2. 修改配置文件 conf下

   重命名：mv hive-env.template.sh hive-env.sh

   vi hive-env.sh

   ```
   # HADOOP_HOME
   HADOOP_HOME=/xxx 
   # conf的路径
   export HIVE_CONF_DIR=/xxx/hive/conf
   ```

3. 启动  

   先启动HDFS ：`start-dfs.sh`  和yarn `start-yarn.sh`

   创建两文件：

   `hdfs dfs -mkdir /tmp`

   `hdfs dfs -chmod 777 /tmp`

   `hdfs dfs -mkdir -p /user/hive/warehouse`

   `hdfs dfs -chmod 777 /user/hive/warehouse`

    启动 ：bin/hive

### 安装mysql 修改密码

### hive替换元数据数据库为mysql

1. 复制 mysql jar 到 hive/lib 下

2. 在hive/conf 下 `vi hive-site.xml`

   ```xml
   <?xml version="1.0"?>
   <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
   <configuration>
   <property>
       // 注意<value>标签在一行
       <name>javax.jdo.option.ConnectionURL</name>
       <value>
         jdbc:mysql://zyd-db-m:3306/hive?createDatabaseIfNotExist=&amp;useSSL=false
       </value>
   </property>
   
   <property>
      <name>javax.jdo.option.ConnectionDriverName</name>
      <value>com.mysql.jdbc.Driver</value>
   </property>
   
   <property>
       <name>javax.jdo.option.ConnectionUserName</name>
       <value>scm</value>
   </property>
   
   <property>
       <name>javax.jdo.option.ConnectionPassword</name>
       <value>scm</value>
   </property>
     <property>
       <name>datanucleus.schema.autoCreateAll</name>
       <value>true</value>
     </property>
     <property>
       <name>hive.server2.thrift.port</name>
       <value>10000</value>
     </property>
     <property>
       <name>hive.server2.thrift.bind.host</name>
       <value>zyd-db-m</value>
     </property>
     <property>
       <name>hive.server2.enable.doAs</name>
       <value>true</value>
     </property>
     <property>
       <name>hive.metastore.uris</name>
       <value>thrift://zyd-db-m:9083</value>
     </property>
      // 加锁 
     <property>
       <name>hive.support.concurrency</name>
       <value>true</value>
     </property>
    <property>
       <name>hive.zookeeper.quorum</name>
       <value>zyd-db-m:2181,zyd-db-02:2181,zyd-db-01:2181</value>
     </property>
   </configuration>
   ```

   3. schematool -dbType mysql -initSchema  //初始化元数据
   4. 重启hive
   5. hive -hiveconf hive.root.logger=debug,console    //dubug启动

   ### 配置 hive-site.xml

   ```java
   <property>
       <name>datanucleus.schema.autoCreateAll</name>
       <value>true</value> 
   </property>
   // 验证
   <property>
       <name>hive.metastore.schema.verification</name>
       <value>false</value>
    </property>
    # false则，yarn作业获取到的hiveserver2用户都为hive用户。设置成true则为实际的用户名
    <property>
       <name>hive.server2.enable.doAs</name>
       <value>true</value>
     </property>
   <property>
       <name>hive.support.concurrency</name>
       <value>true</value>
     </property>
     // 开启本地模式 小数据文件在本机处理
     <property>
       <name>hive.exec.mode.local.auto</name>
       <value>true</value>
     </property>
     // 最小工作线程数
     <property>
       <name>hive.server2.thrift.min.worker.threads</name>
       <value>100</value>
     </property>
     
     // 并行度
       <property>
       <name>hive.exec.parallel</name>
       <value>true</value>
     </property>
     <property>
       <name>hive.exec.parallel.thread.number</name>
       <value>16</value>
     </property>
   
     // groupby key 随机分发 
     <property>
       <name>hive.groupby.skewindata</name>
       <value>true</value>
     </property>
     
     // reduce 输出合并
     <property>
       <name>hive.merge.mapredfiles</name>
       <value>true</value>
     </property>
     
     //  mapred内存
       <property>
           <name>mapred.child.java.opts</name>
           <value>-Xmx2048m</value>
        </property>
   ```

### 开远程连接

```
http://10.10.10.221:8088/ws/v1/cluster/apps/application_1584368766102_0067/state
```

nohup hive --service hiveserver2 &

**nohup hive --service metastore &**

```bash
!connect jdbc:hive2://zyd-hd-01:10000 root root
```

org.apache.hadoop.security.authorize.AuthorizationException): User: root is not allowed to impersonate root (state=08S01,code=0)

1. 关闭hadoop集群

2. 修改core-site.xml文件，增加如下内容：

3. hdfs-site.xml

   ```java
   <property>
         <name>hadoop.proxyuser.root.groups</name>
         <value>*</value>
   </property>
   <property>
         <name>hadoop.proxyuser.root.hosts</name>
         <value>*</value>
   </property>
   ```

注意所有节点的core-site.xml都修改。

1. 重启hadoop集群
2. 启动metastore和hiveserver2,重新连接hiveserver2。

### 问题

1. **hive-site.xml  文件的<value></value> 必须在一行**

   > FAILED: SemanticException org.apache.hadoop.hive.ql.metadata.HiveException: java.lang.RuntimeException: Unable to instantiate org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient

   - schematool -dbType mysql -initSchema  //初始化元数据

2. **Return Code 2** **jvm 内存溢出**   

   yarn-site.xml

   ```jav
   <property>
   	<name>yarn.scheduler.maximum-allocation-mb</name>
   	<value>2048</value>
   </property>
   <property>
     	<name>yarn.scheduler.minimum-allocation-mb</name>
     	<value>2048</value>
   </property>
   <property>
   	<name>yarn.nodemanager.vmem-pmem-ratio</name>
   	<value>2.1</value>
   </property>
   <property>
   	<name>mapred.child.java.opts</name>
   	<value>-Xmx1024m</value>
   </property>
   ```

   **hive 日志位置:** /tmp/root/hive.log

   hive  server2 后台运行日志 

   通过 hive  server2 后台运行日志  找到hive任务ID 去/tmp/root/hive.log中查找

3. **hive 执行卡主不动**

   ```java
   // yarn.nodemanager 内存 yarn-site.xml
   <property>
       <name>yarn.nodemanager.resource.memory-mb</name>
       <value>20480</value>
   </property>
   
   // mapred内存 hive-site.xml
   <property>
       <name>mapred.child.java.opts</name>
       <value>-Xmx2048m</value>
   </property>
   ```

4. Exception in thread "HiveServer2-Handler-Pool: Thread-72" java.lang.OutOfMemoryError: GC overhead limit exceeded(HiveServer2 关闭了)

    ```JAVA
   // hive-env.sh
   export HADOOP_HEAPSIZE=2048
    ```

   jstat -gcutil [pid] 5000  // 5 秒 打印一次内存使用情况 