### Docker安装

#### es

1. `docker pull elasticsearch:7.4.1`

2. `docker run --name=es -d -p 9200:9200 -p 9300:9300 docker.io/elasticsearch:7.4.1`

#### head

1. `docker pull mobz/elasticsearch-head:5`

2. `docker run -d -p 9100:9100 docker.io/mobz/elasticsearch-head:5`

##### **es 跨域配置**

1. 进入es容器：`docker exec -it es /bin/bash`

2. 修改 `vi elasticsearch.yml`

   ```java
   http.cors.enabled: true     //开启跨域
   http.cors.allow-origin: "*" // 如果 http.cors.enabled 的值为 true，可以指定允许的访问IP
   ```

3. 重启es容器 `docker restart es`

##### 修改系统max_map_count数

```java
1.切换到root用户，执行命令：

　　sysctl -w vm.max_map_count=262144

2.查看结果：

　　sysctl -a|grep vm.max_map_count

3.显示：

　　vm.max_map_count = 262144

永久解决办法

　　在/etc/sysctl.conf文件最后添加一行：vm.max_map_count=262144

　　重启虚拟机
```

##### head 访问错误

status：406 

error msg : "Content-Type header [application/x-www-form-urlencoded] is not supported"

1.  进入es-head 容器`docker exec -it es-head /bin/bash`

2. 安装 vim 命令

   ```java
   apt-get update
   apt-get install vim
   ```

3. `vim _site/vendor.js`

   6886行: /contentType: “application/x-www-form-urlencoded改成

   ```java
   contentType: "application/json;charset=UTF-8"
   ```

   7573行: var inspectData = s.contentType === “application/x-www-form-urlencoded” && 改成

​	var inspectData = s.contentType === "application/json;charset=UTF-8" &&

4. 重启es_head容器 `docker restart es_head`

#### ik中文分词器

1.  查看ik 和es 对应版本 <https://github.com/medcl/elasticsearch-analysis-ik/releases>

2. 进入es-head 容器`docker exec -it es-head /bin/bash`

3. 安装./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.4.0/elasticsearch-analysis-ik-6.4.0.zip

4. 查看 plugin 目录下 是否有 analysis-ik

5. 重启es容器 `docker restart es`

6. 验证

   ```java
   POST _nanlyze
   {
     "analyzer": "ik_max_word",
     "text":"中华人民共和国"
   }
   ```

##### 分类

- ik_max_word 最少切分
- ik_smart 最细粒度划分

##### 自定义分词

#### 文档（pdf,doc）检索

1. 安装 ingest-attachment插件

   `./bin/elasticsearch-plugin install ingest-attachment`

2. 新建管道

   ```java
   PUT _ingest/pipeline/attachment
   {
     "description": "pdf测试管道",
     "processors": [
       {
         "attachment": {
           "field": "data"
         }
         "remove": {    
          "field": "data"  // 导入后删除
         }
         
       }
     ]
   }
   ```

3. 使用管道

   ```java
   PUT my_index/_doc/my_id?pipeline=attachment
   //base64数据
   {
     "data": "e1xydGYxXGFuc2kNCkxvcmVtIGlwc3VtIGRvbG9yIHNpdCBhbWV0DQpccGFyIH0=" ,
     "url":"www.dsdff.cn"  // 自定义字段 文档路径
   }
   ```

4. 生成的数据

   ```java
   {
     "attachment": {
       "content_type": "application/rtf",
       "language": "ro",
       "content": "Lorem ipsum dolor sit amet",
       "content_length": 28
     }
   }
   ```

5.  查询

   ```java
   GET pdf_index/_doc/_search/
   {
     "query": {
       "match": {
         "attachment.content": "dolor "
       }
     }
   }
   ```

   

