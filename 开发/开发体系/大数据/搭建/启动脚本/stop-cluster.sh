#! /bin/bash
echo "------正在关闭spark------"
source /etc/profile
cd /opt/hd/spark-2.3.3-bin-hadoop2.7/sbin
./stop-all.sh   
echo "------spark 关闭成功------"

echo "------正在关闭Hbase------"
cd /opt/hd/hbase
./bin/hbase-daemon.sh stop master
ssh root@zyd-db-01 "source /etc/profile;
cd /opt/hd/hbase;
./bin/hbase-daemon.sh stop  regionserver"
ssh root@zyd-db-02 "source /etc/profile;
cd /opt/hd/hbase;
./bin/hbase-daemon.sh stop  regionserver"
echo "------Hbase 关闭成功------"

echo "------正在关闭kafka------"
cd /opt/hd/kafka
./bin/kafka-server-stop.sh
ssh root@zyd-db-01 "source /etc/profile;
cd /opt/hd/kafka;
./bin/kafka-server-stop.sh"
ssh root@zyd-db-02 "source /etc/profile;
cd /opt/hd/kafka;
./bin/kafka-server-stop.sh"
echo "------kafka 关闭成功------"

echo "------正在关闭Hadoop------"
stop-all.sh
echo "------Hadoop 关闭成功------"

echo "------正在关闭集群------"
echo "------正在关闭Zookeeper------"
zkServer.sh stop
ssh root@zyd-db-01 "source /etc/profile;zkServer.sh stop"
ssh root@zyd-db-02 "source /etc/profile;zkServer.sh stop"
echo "------Zookeeper关闭成功------"
