### docker mysql 安装

1. 拉取镜像 docker pull mysql

2. 建立映射文件

   ```shell
   mkdir -p /root/docker/mysql/conf && mkdir -p /root/docker/mysql/data
   mkdir -p /root/docker/mysql/mysql-files
   ```

3. 创建自定义bridge模式指定网段(为docker容器内部通信)

   `docker network create --driver bridge --subnet=172.18.0.0/16 --gateway=172.18.0.1 zoonet`

4. 启动容器

   ```shell
   // 不指定IP
   // docker run --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 -v ///root/docker/mysql/data/:/var/lib/mysql -v ///root/docker/mysql/conf/my.cnf:/etc/mysql/my.cnf -v //root/docker/mysql/mysql-files:/var/lib/mysql-files/ -itd mysql
```
   
   ```java
   // 指定IP
   docker run --name mysql3 -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root --network zoonet --ip 172.18.0.2 -v /root/docker/mysql/data/:/var/lib/mysql -v /root/docker/mysql/conf/my.cnf:/etc/mysql/my.cnf -v /root/docker/mysql/mysql-files:/var/lib/mysql-files/ -itd mysql
   ```
   
   - -e MYSQL_ROOT_PASSWORD=root  指定root账户密码
   - --network zoonet  指定自定义的网络模式
   - --ip 172.18.0.2 为容器指定ip

**修改容器内配置文件：**

1. 做了配置文件挂载，直接修改宿主机挂载的配置文件，重启容器

2. 没做配置文件挂载(容器又未启动)，通过docker cp 命令将容器内配置文件复制出来，修改后，再复制进容器，重启容器

   ```
   docker cp 1e1aa8dcbfb9:/etc/mysql/my.cnf /root/docker/mysql/conf/my.cnf 
   docker cp /root/docker/mysql/conf/my.cnf 1e1aa8dcbfb9:/etc/mysql/my.cnf 
   ```

**修改group by 未指定无法查询问题:**

修改配置文件

```
[mysqld]
sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'
```

**容器里连接mysql：**

`mysql -h localhost -uroot -p`

**注意：**

```hava
1. 宿主的数据挂载文件第一次启动容器时要干净，再将备份的文件放到宿主的数据挂载文件（my.cnf不能为空）
2. --net=host 将会和主机共用一个ip   ，并和主机端口冲突。
3. 每个容器都是一个小型linux
4. 注意：host网络模式，不用指定端口, docker ps 查看也不会显示端口号。
```

