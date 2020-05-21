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

3. 安装./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.4.1/elasticsearch-analysis-ik-7.4.1.zip

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