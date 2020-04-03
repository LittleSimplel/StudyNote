### 配置结构

![nginx配置文件结构.png](http://ww1.sinaimg.cn/large/0062TeRXgy1gdgoybe5yhj30ns0b0jrt.jpg)

**全局块**：配置影响nginx全局的指令

**events块：**配置影响nginx服务器或与用户的网络连接

**http块：**可以嵌套多个server，配置代理，缓存，日志定义等绝大多数功能和第三方模块的配置

​	**upstream**：指令主要用于负载均衡，设置一系列的后端服务器

​	**server**：指令主要用于指定主机和端口，一个http中可以有多个serve

​		**location**：用于匹配网页位置



### 部分详解

#### 全局块

```java
user www www;

worker_processes 8;

error_log /usr/local/nginx/logs/error.log info;

pid /usr/local/nginx/logs/nginx.pid;

worker_rlimit_nofile 65535;
```

- **user**  定义Nginx运行的用户和用户组  不指定 nobody nobody
- **worker_processes** nginx进程数，建议设置为等于CPU总核心数
- **error_log**  全局错误日志定义类型，[ debug | info | notice | warn | error | crit ]
- **pid**  进程pid文件
- **worker_rlimit_nofile**

