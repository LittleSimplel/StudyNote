### kafka

1. 官网 下载 上传 解压

2. 修改配置文件

   vi server.propertise

   ```
   broker.id=0
   # 允许删除topic
   delete.topic.enable=true
   log.dirs=/opt/hd/kafka/datalog  //日志路径  自建
   zookeep.connection=zyd-hd-01:2181,zyd-hd-02:2181,zyd-hd-03:2181
   ```

3. 环境变量

   ```
   epport KAFKA_HOME=/opt/hd/kafka
   export PATH=$PATH:$KAFKA_HOME/bin
   ```

   source /etc/profile

4. 发送到其他机器

   scp -r /xxx/kafka/ hostname:$PWD

   scp -r /etc/profile hostname:/etc/

5. 在从节点 vi server.properties

   ```
   broker.id=1
   ---
   broker.id=2
   ```

6. 启动： bin/kafka-server-start.sh config/server.properties &

   后台启动:  nohup ./bin/kafka-server-start.sh config/server.properties > /dev/null 2>&1 &

​    

