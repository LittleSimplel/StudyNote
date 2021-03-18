### spark

1. 单独装三台新服务

2. 装备工作（hadoop安装）

3. 安装jdk

4. 官网下载 上传  解压

5. 修改配置文件 conf

   `mv spark-env.sh.template spark-env.sh`

   `vi spark-env.sh`

   ```
   export JAVA_HOME=/xxx
   export SPARK_MASTER_HOST=hostname
   export SPARK_MASTER_PORT=7077
   ```

   `vi slavse.template slavse`

   `vi slavse`  加入从节点

   ```
    hostname1
    hostname2
   ```

6. 发送到从节点

   scp -r  /xxx/spark/ host2:$PWD

7. 启动 sbin/start-all.sh

8. webui   hostname:8080

