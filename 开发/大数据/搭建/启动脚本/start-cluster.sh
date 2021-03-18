#! /bin/bash
echo "------正在启动集群------"
echo "------正在启动Zookeeper------"
zkServer.sh start
ssh root@zyd-db-01 "source /etc/profile;zkServer.sh start"
ssh root@zyd-db-02 "source /etc/profile;zkServer.sh start"
echo "------Zookeeper启动成功------"
sleep 1
echo "------正在启动Hadoop------"
start-all.sh
echo "------Hadoop 启动成功------"
sleep 1
echo "------正在启动kafka------"
cd /opt/hd/kafka
nohup ./bin/kafka-server-start.sh config/server.properties > /dev/null 2>&1 &
ssh root@zyd-db-01 "source /etc/profile;
cd /opt/hd/kafka;
nohup ./bin/kafka-server-start.sh config/server.properties > /dev/null 2>&1 &"
ssh root@zyd-db-02 "source /etc/profile;
cd /opt/hd/kafka;
nohup ./bin/kafka-server-start.sh config/server.properties > /dev/null 2>&1 &"
echo "------kafka 启动成功------"
sleep 1
echo "------正在启动Hbase------"
cd /opt/hd/hbase
./bin/hbase-daemon.sh start master
ssh root@zyd-db-01 "source /etc/profile;
cd /opt/hd/hbase;
./bin/hbase-daemon.sh start  regionserver"
ssh root@zyd-db-02 "source /etc/profile;
cd /opt/hd/hbase;
./bin/hbase-daemon.sh start  regionserver"
echo "------Hbase 启动成功------"
sleep 1
echo "------正在启动hive------"
source /etc/profile
nohup hive --service metastore > /dev/null 2>&1 &
nohup hive --service hiveserver2 > /dev/null 2>&1 &    
echo "------hive 启动成功------"
sleep 1
echo "------正在启动spark------"
source /etc/profile
cd /opt/hd/spark-2.3.3-bin-hadoop2.7/sbin
./start-all.sh   
echo "------spark 启动成功------"
