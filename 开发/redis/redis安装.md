### redis安装

#### Redis.conf详解

> 单位：配置文件单位对大小写不敏感。

```java
# 1k => 1000 bytes
# 1kb => 1024 bytes
# 1m => 1000000 bytes
# 1mb => 1024*1024 bytes
# 1g => 1000000000 bytes
# 1gb => 1024*1024*1024 bytes
```

> 网络

```java
bind 127.0.0.1                    # 绑定的ip
protected-mode yes                # 保护模式 默认yes
port 6379                         # 端口设置
```

> 通用

```java
# 进程
daemonize yes                     # 以守护进程的方式(后台)运行，默认是 no，我们需要自己开启为yes！
pidfile /var/run/redis_6379.pid   # 如果以后台的方式运行，我们就需要指定一个 pid 文件！
# 日志
loglevel notice                   # 日志记录级别(debug、verbose、notice、warning)，默认为verbose
logfile ""                        # 日志的文件位置名
databases 16                      # 数据库的数量，默认是 16 个数据库
always-show-logo yes              # 是否总是显示LOGO
```

> 持久化

```
# rdb
# 满足以下条件将会同步数据:
save 900 1                        # 900秒（15分钟）内有1个key更改
save 300 10                       # 300秒（5分钟）内有10个更改
save 60 10000                     # 60秒内有10000个更改
stop-writes-on-bgsave-error yes   # 持久化如果出错，是否还需要继续工作！
rdbcompression yes                # 是否压缩 rdb 文件，需要消耗一些cpu资源！
rdbchecksum yes                   # 保存rdb文件的时候，进行错误的检查校验！
dbfilename dump.rdb               # 指定本地数据库文件名，默认值为dump.rdb
dir ./                            # rdb 文件保存的目录！

# aof
appendonly no                     # 默认是不开启aof模式的，默认是使用rdb方式持久化的，在大部分所有的情况下，rdb完全够用！
appendfilename "appendonly.aof"   # 持久化的文件的名字
# appendfsync always              # 每次修改都会 sync。消耗性能（数据安全）
# appendfsync everysec            # 每秒执行一次 sync，可能会丢失这1s的数据！
# appendfsync no                  # 不执行 sync，这个时候操作系统自己同步数据，速度最快！

```

> 限制 

```java
maxclients 10000                  # 设置能连接上redis的最大客户端的数量
maxmemory <bytes>                 # redis 配置最大的内存容量
maxmemory-policy noeviction       # 内存到达上限之后的处理策略
1、volatile-lru：只对设置了过期时间的key进行LRU（默认值）
2、allkeys-lru ： 删除lru算法的key
3、volatile-random：随机删除即将过期key
4、allkeys-random：随机删除
5、volatile-ttl ： 删除即将过期的
6、noeviction ： 永不过期，返回错误
```

> 安全

```java
# 配置密码
requirepass                        #redis默认是没有密码的
# 命令设置密码
config set requirepass 123456      
```

> REPLICATION

```java
slaveof masterip masterport        #在从Redis服务器，主Redis服务器不需要做任何配置
# 新版redis 没有slaveof 改为 replicaof
replicaof  masterip masterport
```

#### redis 主从复制

```shell
[root@zyd-hd-01 redis]# wget https://download.redis.io/releases/redis-6.2.5.tar.gz
[root@zyd-hd-01 redis]# tar xzf redis-6.2.5.tar.gz
[root@zyd-hd-01 redis]# cd redis-6.2.5
[root@zyd-hd-01 redis]# make
# 启动服务端
[root@zyd-hd-01 redis]# cd src
[root@zyd-hd-01 redis]# ./redis-server ../redis.conf
# 启动客户端
[root@zyd-hd-01 redis]# cd src
[root@zyd-hd-01 redis]# ./redis-cli
# 配置主从复制
# 复制配置文件为redis1.conf然后修改对应的信息
#1.port
#2.pidfile
#3.logfile
#4.dbfilename dump.rdb 名字
#指定主节点
#replicaof  masterip masterport 
[root@zyd-hd-01 redis]# ./redis-server ../redis1.conf
```

#### redis主从复制（哨兵模式）

#### redis cluster

#### Docker-compose 主从复制（哨兵模式）

#### Docker-compose redis-cluster集群