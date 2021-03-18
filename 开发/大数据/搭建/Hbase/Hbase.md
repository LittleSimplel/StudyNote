### hbase

1. 官网下载 上传 解压

2. 先安装hadoop zookeep 集群

3. 修改配置文件

   vi hbase-env.sh

   ```
   export JAVA_HOME=/xx
   # 不用hbase自带的
   export HBASE_MNAGES_ZK=false
   ```

   vi hbase-site.xml

   ```
   <property>
       # 设置namenode位置
       <name>hbase.rootdir</name>
       <value>hdfs://zyd-hd-01:9000/hbase</value>
   </property>
        # 是否开启集群
       <name>hbase.cluster.distributed</name>
       <value>true</value>
   </property>
   <property>
        #0.98 版本后新改动  之前没有.port 默认为60000
       <name>hbase.master.port</name>
       <value>hdfs://zyd-hd-01:16000</value>
   </property>
   
   <property>
        # zookeep 集群
       <name>hbase.zookeeper.quorum</name>
       <value>zyd-hd-01:2181,zyd-hd-02:2181,zyd-hd-03:2181</value>
   </property>
   <property>
       # zookeep 数据存放目录  自建（用安装zookeep时建的）
       <name>hbase.zookeeper.property.dataDir</name>
       <value>/opt/hd/zookeep/Zkdata</value>
   </property>
    ///本机
    <property>
       <name>hbase.rootdir</name>
       <value>hdfs://zyd-hd-01:9000/hbase</value>
      </property>
     <property>
       <name>hbase.cluster.distributed</name>
       <value>true</value>
     </property>
     <property>
       <name>hbase.master</name>
       <value>zyd-hd-01:16000</value>
     </property>
     <property>
       <name>hbase.zookeeper.quorum</name>
       <value>zyd-hd-01:2181,zyd-hd-02:2181,zyd-hd-03:2181</value>
     </property>
     <property>
       <name>hbase.zookeeper.property.dataDir</name>
       <value>/opt/hd/zookeep/Zkdata</value>
     </property>
   
   ```

    vi regionservers 

   加上从节点主机名

   ```
   zyd-hd-02
   zyd-hd-03
   ```

   4. 版本适配问题

       不适配 删除 lib下 `rm -rf  hadoop-*.jar`hadoop 和zookeep的jar 

       换上相关版本的

   5. 软连接 hadoop配置 

      ln -s /opt/hd/hadoop/etc/hadoop/core-site.xml /opt/hd/hbase/conf/

​              ln -s /opt/hd/hadoop/etc/hadoop/hdfs-site.xml /opt/hd/hbase/conf/

   6. 发送hbase整个包到其他机器

      scp -r /xxx/xx/hbase/ hostname1:$PWD

          7. 启动  启动zookeep 和hadoop
            
             bin/hbase-daemon.sh start master   //主节点
            
             bin/hbase-daemon.sh start  regionserver //从节点
            
          8. 验证：bin/hbase shell

**问题:**

java.lang.RuntimeException: HRegionServer Aborted 

KeeperErrorCode = Session expired for /hbase/replication/rs

各节点时间未同步



ERROR: KeeperErrorCode = NoNode for /hbase/master

master 崩了

Caused by: java.io.IOException: Meta region is in state OPENING

重启



hbase shell

> status

ERROR: org.apache.hadoop.hbase.PleaseHoldException: Master is initializing

检查时间同步

删除zookeep下的hbase元数据

zkCli.sh 

rmr /hbase

删除zookeep 存放数据的文件下的版本  zkData/version-2

删除 hdfs   /hbase

重启zookeep 和 hbase

端口

16000

16020

192.168.0.188

kafka-console-consumer.sh --bootstrap-server 192.168.0.188:9092 --topic buryPointDataPvUvAnalyse

kafka-console-producer.sh --broker-list 192.168.0.188:9092 --topic buryPointDataPvUvAnalyse



kafka-topics.sh --describe --zookeeper 192.168.0.188:2181