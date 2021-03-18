### 集群准备工作

| 主机名    | ip           | 内存 |
| --------- | ------------ | ---- |
| zyd-hd-01 | 10.10.10.221 | 16G  |
| zyd-hd-02 | 10.10.10.222 | 4G   |
| zyd-hd-03 | 10.10.10.223 | 4G   |

1. **关闭防火墙 (远程连接)**

   systemctl stop firewalld      //当前关闭

   systemctl disable firewalld  //  永久关闭

   systemctl status firewalld

2. **免密登录**

   ssh-keygen 回车

   ssh-copy-id zyd-hd-01 回车 

   ssh-copy-id zyd-hd-02 回车

   ssh-copy-id zyd-hd-03 回车

   ```java
   // 出现权限问题
   chmod 600 authorized_keys
   // 若无法改变权限
   chattr -ia authorized_keys
   chmod 700 .ssh     // 所有机器权限必须一样  不然会出现有的可以免密，有的任需密码登录
   // 清除ssh
   ssh-keygen -R hostname
   ```

3. **设置主机名**

   修改 vi  /etc/hostname

   `local 改为 zyd-hd-01`

   重启 reboot

   查看 cat /etc/hostname

   另外两台机器重复以上操作 主机名 改为 zyd-hd-02 和 zyd-hd-03

4. **配置映射**

   vi /etc/hosts   

   ```
   10.10.10.221 zyd-hd-01
   10.10.10.222 zyd-hd-02
   10.10.10.223 zyd-hd-03
   ```

   复制到其他机器

   ```
   scp -r /etc/hosts zyd-hd-01:/etc/
   ```


### 安装jdk 1.8

1.  上传到/opt/hd/文件下  解压

2. 环境变量 

   vi /etc/profile

   ```
   export JAVA_HOME=/opt/hd/jdk1.8.0_141/
   export CLASS_PATH=$JAVA_HOME/lib
   export PATH=$JAVA_HOME/bin:$PATH
   ```

   加载： source /etc/profile

   复制到其他机器：

   ```
   scp -r jdk1.8.0_212/ zyd-hd-01:$PWD
   scp -r jdk1.8.0_212/ zyd-hd-02:$PWD
   // $PWD 为相同路径下
   ```

   加载： source /etc/profile

### 安装HDFS集群

1. **下载 上传/opt/hd/文件下 解压 改名为hadoop**

2. **修改 hadoop目录下配置文件 ect/hadoop下**

   `vi  hadoop-evn.sh`

   ```
   export JAVA_HOME=/opt/hd/jdk1.8.0_212/
   ```

   `vi core-site.xml` 核心配置文件,**configuration标签中插入**

   ```
   <configuration>
     <!--指定namenode的地址 默认HDFS文件地址-->
     <property>
                  <name>fs.defaultFS</name>
                  <value>hdfs://zyd-hd-01:9000</value>
     </property>
     <property>
       <!--root 搭建hadoop的用户-->
       <name>hadoop.proxyuser.root.groups</name>
       <value>*</value>
     </property>
     <property>
       <name>hadoop.proxyuser.root.hosts</name>
       <value>*</value>
     </property>
     <property>
           <!-- hadoop的临时存储目录 -->
           <name>hadoop.tmp.dir</name>
           <value>/opt/hd/hadoop/dfs</value>
     </property>
   </configuration>
   ```

   `vi hdfs-site.xml` 路径自己指定

   ```
   <property>
           <!--配置元数据贮存位置 自建-->
   		<name>dfs.namenode.name.dir</name>
   		<value>/opt/hd/hadoop/dfs/data</value>
   </property>
   <property>
           <!--配置数据贮存位置 自建-->
   		<name>dfs.datanode.data.dir</name>
   		<value>/opt/hd/hadoop/dfs/datanode</value>
   </property>
   <property>  
       <!--hdfsweb页 50070-->
       <name>dfs.webhdfs.enabled</name>  
       <value>true</value>  
     </property> 
   <property>  
     <!--关闭用户权限验证-->
     <name>dfs.permissions</name>  
     <value>false</value>  
   </property>
   
   ```

3. **配置Hadoop 环境变量**

   `vi /etc/profile`

   ```
   export HADOOP_HOME=/opt/hd/hadoop
   # 在原来的export PATH上追加
   export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
   ```

   加载： source /etc/profile

   hadoop包,环境配置 发送到其他机器

   ```
   scp -r hadoop/ zyd-hd-01:$PWD
   scp -r /etc/profile zyd-hd-01:/ect/
   ```

4. **格式化元数据信息  (就是创建第四步指定的路径(集群扩充时要清理))**

   cd /hadoop/bin

   ```
   hadoop namenode -format
   ```

5. **启动集群（一台namenode 多台datanode）**

   - (主机)启动namenode：hadoop-daemon.sh start namenode

     jsp 查看是否启动

   - (其他机器)datanode：hadoop-daemon.sh start datanode

     jsp 查看是否启动

     关闭（hadoop-daemon.sh stop）

6. **webUI  ip:50070**

7. **一键启动HDFS** 

   hadoop目录下 cd  etc/hadooop

   vi slaves  写入datanode 节点主机名

   ```
   zyd-hd-01
   zyd-hd-02
   ```

   关闭 namenode：hadoop-daemon.sh stop namenode

   关闭 datanode：hadoop-daemon.sh stop datanode

   全部启动：start-dfs.sh (stop-dfs.sh)

   jps  查看会多出一个副本

8. **副本配置 vi hdfs-site.xml**

   ```
   <property>
   		<name>dfs.namenode.secondary.http-address</name>
   		<value>zyd-db-m:50090</value>
   </property>
   //hostname 存留备份的机器
   ```

   发送到其他机器

   scp -r  hdfs-site.xml hostname:$PWD

   重启：

   start-dfs.sh 

   stop-dfs.sh

   jsp查看

9. **yarn jobhistory**

   ```java
   <property>
       <name>mapreduce.jobhistory.address</name>
       <value>zyd-db-m:10020</value>
   </property>
   <property>
       <name>mapreduce.jobhistory.webapp.address</name>
       <value>zyd-db-m:19888</value>
   </property>
   ```

    手动开启：mr-jobhistory-daemon.sh start historyserver

### 其他配置

- hdfs-site.xml

  ```java
  <property>
      <!--设置数据块应该被复制的份数-->
      <name>dfs.replication</name>
      <value>3</value>
  </property>
  <!--ALWAYS：当一个存在的DataNode被删除时，总是添加一个新的DataNode-->
  <!--NEVER：永远不添加新的DataNode-->
  <!--DEFAULT：副本数是r，DataNode的数时n，只要r >= 3时，或者floor(r/2)大于等于n时，r>n时再添加一个新的DataNode，并且这个块是hflushed/appended-->
  <property>
  	<name>dfs.client.block.write.replace-datanode-on-failure.enable</name>
  	<value>true</value>
  </property>
  <property>
      <name>dfs.client.block.write.replace-datanode-on-failure.policy</name>
      <value>NEVER</value>
  </property>
  ```

- mapreduce  mapred-site.xml

  ```java
  <!--当 任务调度不在yarn上 job.tracker和task.tracker自定义端口，不然默认随机-->
  <property>
          <name>mapred.job.tracker</name>
          <value>zyd-db-m:9001</value>
  </property>
  <property>
          <name>mapred.job.tracker.http.address</name>
          <value>0.0.0.0:50030</value>
  </property>
  <property>
          <name>mapred.task.tracker.http.address</name>
          <value>0.0.0.0:50060</value>
  </property>
  ```

### 问题

1.  **生产环境 hdfsClient写入数据时，namenode返回的是datanode的内网ip**

​    查看日志：

```java
12:54:59.382 [Thread-3] DEBUG org.apache.hadoop.hdfs.DFSClient - pipeline = 192.168.11.3:50010
12:54:59.382 [Thread-3] DEBUG org.apache.hadoop.hdfs.DFSClient - pipeline = 192.168.11.6:50010
12:54:59.382 [Thread-3] DEBUG org.apache.hadoop.hdfs.DFSClient - pipeline = 192.168.11.5:50010
12:54:59.382 [Thread-3] DEBUG org.apache.hadoop.hdfs.DFSClient - Connecting to datanode 192.168.11.3:50010   
# 192.168.11.3 为内网ip
```

```java
12:54:59.382 [Thread-3] DEBUG org.apache.hadoop.hdfs.DFSClient - pipeline = 192.168.11.3:50010
12:54:59.382 [Thread-3] DEBUG org.apache.hadoop.hdfs.DFSClient - pipeline = 192.168.11.6:50010
12:54:59.382 [Thread-3] DEBUG org.apache.hadoop.hdfs.DFSClient - pipeline = 192.168.11.5:50010
12:54:59.382 [Thread-3] DEBUG org.apache.hadoop.hdfs.DFSClient - Connecting to datanode zyd-db-03:50010
```

线上 hdfs-site.xml 加上

```java
<property>
　　<name>dfs.client.use.datanode.hostname</name>
　　<value>true</value>
</property>
<property>
　　<name>dfs.datanode.use.datanode.hostname</name>
　　<value>true</value>
</property>
```

若无效 在客户端代码中加

```java
conf.set("dfs.client.use.datanode.hostname", "true");
```

2. 端口问题

### 命令

- 开启防火墙 端口

  `firewall-cmd --zone=public --add-port=10020/tcp --permanent;firewall-cmd --reload`

- 清除log日志

  `echo /dev/null > filename`