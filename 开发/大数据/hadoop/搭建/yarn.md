

### 搭建yarn 分布式资源调用平台  hadoop提供

1. **修改配置文件 vi yarn-site.xml**

   ```
   <!-- 指定YARN的ResourceManager的地址-->
   <property>
     <name>yarn.resourcemanager.hostname</name>
     <value>hostname</value>
   </property>
   <!-- reducer获取数据的方式-->
   <property>
     <name>yarn.nodemanager.aux-services</name>
     <value>mapreduce_shuffle</value>
   </property>
   ```

   cp mapred-site.xml.template mapred-site.xml

   ```java
   <!-- 指定MapReduce的程序运行在YARN上,默认的配置运行在本地Local -->
   <property>
          <name>mapreduce.framework.name</name>
          <value>yarn</value>
   </property>
   ```

   发送到其他机器：

   scp yarn-site.xml hostname:$PWD

2. **vi slavse  加上其他机器 hostname **(hdfs已加)

3. **start-yarn.sh  (stop-yarn.sh)**

4. **日志聚合**

   vi yarn-site.xml

   ```JAVA
   <property>
           <name>yarn.log-aggregation-enable</name>
           <value>true</value>
    </property>
   # 日志保存7天（单位秒）
   <property>
                   <name>yarn.log-aggregation.retain-seconds</name>
                   <value>600000</value>
    </property>
    <property>
           <name>yarn.nodemanager.log-aggregation.roll-monitoring-interval-seconds</name>
           <value>3600</value>
    </property>
    <property>
           <name>yarn.nodemanager.remote-app-log-dir</name>
           <value>/tmp/logs</value>
    </property>
    // yarn.nodemanager 内存
   <property>
       <name>yarn.nodemanager.resource.memory-mb</name>
       <value>20480</value>
   </property>
   ```

### 问题

- 端口

  master： 8031

  从节点：  36593

  ```java
  <property>
          <name>yarn.nodemanager.address</name>
          <value>0.0.0.0:36593</value>
  </property>
  ```

- spark on yarn

  Spark的Driver和Executor之间通讯端口是随机的，Spark会随选择1024和65535（含）之间的端口