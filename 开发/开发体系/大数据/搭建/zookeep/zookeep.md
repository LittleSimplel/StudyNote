### zookeep

1. **官网下载 上传 解压**

2. **修改配置文件  conf**

   重命名： mv zoo-sample.cfg zoo.cfg

   `vi zoo.cfg`

   ```
   dataDir=/opt/hd/zookeep/Zkdata           
   ```

   创建/xxx 文件夹  一般创建再 zookeep包下

3. **启动  :** `bin/zkServer.sh start`

   jps 查看是否启动   :QuoeumPeerMain

   zookeep状态 : `bin/zkServer.sh status`

   standalone 单机

4. **启动客户端** `bin/zkCli.sh` 

5. **分布式安装**

    `vi zoo.cfg`

   ```
   server.1=zyd-hd-01:2888:3888
   server.2=zyd-hd-02:2888:3888
   server.3=zyd-hd-03:2888:3888
   ```

   在2步创建的文件夹下 创建文件

​       `touch myid`

​        `vi  myid`    加一个数字 1

​        发送到其他机器

​         scp -r zookeep/ hostname:$PWD

​         vi  myid`    1改成 2

​         vi  myid`    1改成 3

6. **配置环境变量**

   ```
   export ZOOKEEP_HOME=/opt/hd/zookeep
   export PATH=$PATH:$ZOOKEEP_HOME/bin
   ```

   发送到其他机器

   `scp -r /etc/profile hostname:/etc/`

   加载：`source /etc/profile`

   7. **启动集群：每台机器都启动**

      zkServer.sh start   

​       zookeep状态 : `bin/zkServer.sh status

问题：

ZooKeeper JMX enabled by default
Using config: /opt/hd/zookeep/bin/../conf/zoo.cfg
Error contacting service. It is probably not running.

防火墙没关

