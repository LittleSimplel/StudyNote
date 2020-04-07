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

#### events块

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

- **open_file_cache_valid** 这个是指多长时间检查一次缓存的有效信息。默认值: 60s 使用字段:http, server, location 这个指令指定了何时需要检查open_file_cache中缓存项目的有效信息

- **open_file_cache_min_uses** open_file_cache指令中的inactive参数时间内文件的最少使用次数，如果超过这个数字，文件描述符一直是在缓存中打开的，如上例，如果有一个文件在inactive时间内一次没被使用，它将被移除。 默认值:open_file_cache_min_uses 1 使用字段:http, server, location  这个指令指定了在open_file_cache指令无效的参数中一定的时间范围内可以使用的最小文件数,如果使用更大的值,文件描述符在cache中总是打开状态

- **open_file_cache_errors **open_file_cache_errors on | off 默认值:open_file_cache_errors off 使用字段:http, server, location 这个指令指定是否在搜索一个文件是记录cache错误

#### http块

##### http全局块

```sh
http
{
    #文件扩展名与文件类型映射表
    include mime.types;

    #默认文件类型
    default_type application/octet-stream; 

    #默认编码
    #charset utf-8; 

    #服务器名字的hash表大小
    #保存服务器名字的hash表是由指令server_names_hash_max_size 和server_names_hash_bucket_size所控制的。参数hash bucket size总是等于hash表的大小，并且是一路处理器缓存大小的倍数。在减少了在内存中的存取次数后，使在处理器中加速查找hash表键值成为可能。如果hash bucket size等于一路处理器缓存的大小，那么在查找键的时候，最坏的情况下在内存中查找的次数为2。第一次是确定存储单元的地址，第二次是在存储单元中查找键 值。因此，如果Nginx给出需要增大hash max size 或 hash bucket size的提示，那么首要的是增大前一个参数的大小.
    server_names_hash_bucket_size 128;

    #客户端请求头部的缓冲区大小。这个可以根据你的系统分页大小来设置，一般一个请求的头部大小不会超过1k，不过由于一般系统分页都要大于1k，所以这里设置为分页大小。分页大小可以用命令getconf PAGESIZE取得。
    client_header_buffer_size 32k; 

    #客户请求头缓冲大小。nginx默认会用client_header_buffer_size这个buffer来读取header值，如果header过大，它会使用large_client_header_buffers来读取。
    large_client_header_buffers 4 64k;

    #设定通过nginx上传文件的大小
    client_max_body_size 8m; 

    #开启高效文件传输模式，sendfile指令指定nginx是否调用sendfile函数来输出文件，对于普通应用设为 on，如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络I/O处理速度，降低系统的负载。注意：如果图片显示不正常把这个改成off。
    #sendfile指令指定 nginx 是否调用sendfile 函数（zero copy 方式）来输出文件，对于普通应用，必须设为on。如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络IO处理速度，降低系统uptime。 
    sendfile on; 

    #开启目录列表访问，合适下载服务器，默认关闭。
    autoindex on; 

    #此选项允许或禁止使用socke的TCP_CORK的选项，此选项仅在使用sendfile的时候使用
    tcp_nopush on; 
      
    tcp_nodelay on; 

    #长连接超时时间，单位是秒
    keepalive_timeout 120; 

    #FastCGI相关参数是为了改善网站的性能：减少资源占用，提高访问速度。下面参数看字面意思都能理解。
    fastcgi_connect_timeout 300; 
    fastcgi_send_timeout 300; 
    fastcgi_read_timeout 300; 
    fastcgi_buffer_size 64k; 
    fastcgi_buffers 4 64k; 
    fastcgi_busy_buffers_size 128k; 
    fastcgi_temp_file_write_size 128k; 

    #gzip模块设置
    gzip on; #开启gzip压缩输出
    gzip_min_length 1k;       #最小压缩文件大小
    gzip_buffers 4 16k;       #压缩缓冲区
    gzip_http_version 1.0;    #压缩版本（默认1.1，前端如果是squid2.5请使用1.0）
    gzip_comp_level 2;    #压缩等级
    gzip_types text/plain application/x-javascript text/css application/xml;   
    #压缩类型，默认就已经包含textml，所以下面就不用再写了，写上去也不会有问题，但是会有一个warn。
    gzip_vary on;

    #开启限制IP连接数的时候需要使用
    #limit_zone crawler $binary_remote_addr 10m;
```

##### upstream块

```java
#负载均衡配置
    upstream piao.jd.com {
     
        #upstream的负载均衡，weight是权重，可以根据机器配置定义权重。weigth参数表示权值，权值越高被分配到的几率越大。
        server 192.168.80.121:80 weight=3;
        server 192.168.80.122:80 weight=2;
        server 192.168.80.123:80 weight=3;

        #nginx的upstream目前支持4种方式的分配
        #1、轮询（默认）
        #每个请求按时间顺序逐一分配到不同的后端服务器，如果后端服务器down掉，能自动剔除。
        #2、weight
        #指定轮询几率，weight和访问比率成正比，用于后端服务器性能不均的情况。
        #例如：
        #upstream bakend {
        #    server 192.168.0.14 weight=10;
        #    server 192.168.0.15 weight=10;
        #}
        #2、ip_hash
        #每个请求按访问ip的hash结果分配，这样每个访客固定访问一个后端服务器，可以解决session的问题。
        #例如：
        #upstream bakend {
        #    ip_hash;
        #    server 192.168.0.14:88;
        #    server 192.168.0.15:80;
        #}
        #3、fair（第三方）
        #按后端服务器的响应时间来分配请求，响应时间短的优先分配。
        #upstream backend {
        #    server server1;
        #    server server2;
        #    fair;
        #}
        #4、url_hash（第三方）
        #按访问url的hash结果来分配请求，使每个url定向到同一个后端服务器，后端服务器为缓存时比较有效。
        #例：在upstream中加入hash语句，server语句中不能写入weight等其他的参数，hash_method是使用的hash算法
        #upstream backend {
        #    server squid1:3128;
        #    server squid2:3128;
        #    hash $request_uri;
        #    hash_method crc32;
        #}

        #tips:
        #upstream bakend{#定义负载均衡设备的Ip及设备状态}{
        #    ip_hash;
        #    server 127.0.0.1:9090 down;
        #    server 127.0.0.1:8080 weight=2;
        #    server 127.0.0.1:6060;
        #    server 127.0.0.1:7070 backup;
        #}
        #在需要使用负载均衡的server中增加 proxy_pass http://bakend/;

        #每个设备的状态设置为:
        #1.down表示单前的server暂时不参与负载
        #2.weight为weight越大，负载的权重就越大。
        #3.max_fails：允许请求失败的次数默认为1.当超过最大次数时，返回proxy_next_upstream模块定义的错误
        #4.fail_timeout:max_fails次失败后，暂停的时间。
        #5.backup： 其它所有的非backup机器down或者忙的时候，请求backup机器。所以这台机器压力会最轻。

        #nginx支持同时设置多组的负载均衡，用来给不用的server来使用。
        #client_body_in_file_only设置为On 可以讲client post过来的数据记录到文件中用来做debug
        #client_body_temp_path设置记录文件的目录 可以设置最多3层目录
        #location对URL进行匹配.可以进行重定向或者进行新的代理 负载均衡
    }
```

##### server块

```sh
#虚拟主机的配置
server
    {
        #监听端口
        listen 80;
        
        #域名可以有多个，用空格隔开
        server_name www.jd.com jd.com;
        
        index index.html index.htm index.php;
        root /data/www/jd;     
    }
```

###### location

- `=` 开头表示精确匹配

- `^~` 开头表示uri以某个常规字符串开头，理解为匹配 url路径即可。nginx不对url做编码，因此请求为/static/20%/aa，可以被规则^~ /static/ /aa匹配到（注意是空格）。以xx开头

- `~` 开头表示区分大小写的正则匹配                     以xx结尾

- `~*` 开头表示不区分大小写的正则匹配                以xx结尾

- `!~`和`!~*`分别为区分大小写不匹配及不区分大小写不匹配 的正则

- `/` 通用匹配，任何请求都会匹配到

  ```sh
  location = / {
     #规则A
  }
  location = /login {
     #规则B
  }
  location ^~ /static/ {
     #规则C
  }
  location ~ \.(gif|jpg|png|js|css)$ {
     #规则D，注意：是根据括号内的大小写进行匹配。括号内全是小写，只匹配小写
  }
  location ~* \.png$ {
     #规则E
  }
  location !~ \.xhtml$ {
     #规则F
  }
  location !~* \.xhtml$ {
     #规则G
  }
  location / {
     #规则H
  }
  ```

**规则：从前缀最长的开始找**，按以下顺序

1. 首先精确匹配 =
2. 以xx开头匹配^~
3. 按文件中顺序的正则匹配
4. / 通用匹配。

当有匹配成功时候，停止匹配，按当前匹配规则处理请求

**常用**

```sh
#直接匹配网站根，通过域名访问网站首页比较频繁，使用这个会加速处理，官网如是说。
#这里是直接转发给后端应用服务器了，也可以是一个静态首页
# 第一个必选规则
location = / {
    proxy_pass http://tomcat:8080/index
}
 
# 第二个必选规则是处理静态文件请求，这是nginx作为http服务器的强项
# 有两种配置模式，目录匹配或后缀匹配,任选其一或搭配使用
location ^~ /static/ {                              //以xx开头
    root /webroot/static/;
}
location ~* \.(gif|jpg|jpeg|png|css|js|ico)$ {     //以xx结尾
    root /webroot/res/;
}
 
#第三个规则就是通用规则，用来转发动态请求到后端应用服务器
#非静态文件请求就默认是动态请求，自己根据实际把握
location / {
    proxy_pass http://tomcat:8080/
}
```

指令：

- **root** 会将 location 匹配的路径缀在 root 参数的后面
- **index**  首页
- **proxy_pass ** 跨域  proxy_pass后面的url加/，表示绝对根路径(不加location后的路径)；如果没有/，表示相对路径
- **alias**  则是将 location 匹配的路径的目录部分，替换为 alias 的参数

### 全局变量

```sh
$args： #这个变量等于请求行中的参数，同$query_string

$content_length： 请求头中的Content-length字段。

$content_type： 请求头中的Content-Type字段。

$document_root： 当前请求在root指令中指定的值。

$host： 请求主机头字段，否则为服务器名称。

$http_user_agent： 客户端agent信息

$http_cookie： 客户端cookie信息

$limit_rate： 这个变量可以限制连接速率。

$request_method： 客户端请求的动作，通常为GET或POST。

$remote_addr： 客户端的IP地址。

$remote_port： 客户端的端口。

$remote_user： 已经经过Auth Basic Module验证的用户名。

$request_filename： 当前请求的文件路径，由root或alias指令与URI请求生成。

$scheme： HTTP方法（如http，https）。

$server_protocol： 请求使用的协议，通常是HTTP/1.0或HTTP/1.1。

$server_addr： 服务器地址，在完成一次系统调用后可以确定这个值。

$server_name： 服务器名称。

$server_port： 请求到达服务器的端口号。

$request_uri： 包含请求参数的原始URI，不包含主机名，如：”/foo/bar.php?arg=baz”。

$uri： 不带请求参数的当前URI，$uri不包含主机名，如”/foo/bar.html”。

$document_uri： 与$uri相同。

```

