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

### events块

```sh
events
{
    use epoll;

    worker_connections 65535;

    keepalive_timeout 60;

    client_header_buffer_size 4k;

    open_file_cache max=65535 inactive=60s;
    
    open_file_cache_valid 80s;

    open_file_cache_min_uses 1;
    
    open_file_cache_errors on;
}
```

- **use **事件模型，use [ kqueue | rtsig | epoll | /dev/poll | select | poll ] ,linux建议epoll
- **worker_connections**  单个进程最大连接数（最大连接数=连接数*进程数） 理论上每台nginx服务器的最大连接数为 65535

- **keepalive_timeout**  keepalive超时时间

- **client_header_buffer_size ** 客户端请求头部的缓冲区大小,根据你的系统分页大小(命令：getconf PAGESIZE)来设置,设置为“系统分页大小”的整倍数。

- **open_file_cache_valid** 这个将为打开文件指定缓存，默认是没有启用的，max指定缓存数量，建议和打开文件数一致，inactive是指经过多长时间文件没被请求后删除缓存

- **open_file_cache_valid** 这个是指多长时间检查一次缓存的有效信息。默认值: 60s 使用字段:http, server, location 这个指令指定了何时需要检查open_file_cache中缓存项目的有效信息.

- **open_file_cache_min_uses** open_file_cache指令中的inactive参数时间内文件的最少使用次数，如果超过这个数字，文件描述符一直是在缓存中打开的，如上例，如果有一个文件在inactive时间内一次没被使用，它将被移除。 默认值:open_file_cache_min_uses 1 使用字段:http, server, location  这个指令指定了在open_file_cache指令无效的参数中一定的时间范围内可以使用的最小文件数,如果使用更大的值,文件描述符在cache中总是打开状态.

- **open_file_cache_errors **open_file_cache_errors on | off 默认值:open_file_cache_errors off 使用字段:http, server, location 这个指令指定是否在搜索一个文件是记录cache错误