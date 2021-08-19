#### windos

1. 本地包导到本地仓库
mvn install:install-file -Dfile=dbtech-taobao-sms-1.0.jar -DgroupId=com.taobao.sdk -DartifactId=dbtech-taobao-sms -Dversion=1.0 -Dpackaging=jar

#### linux

1. 导出jar包

2. 使用一下命令将jar包加入到maven仓库中

   ```sh
   mvn install:install-file -Dfile=goeasy-sdk-0.3.8.jar -DgroupId=io.goeasy -DartifactId=goeasy-sdk -Dversion=0.3.8 -Dpackaging=jar
   ```

   其中： -Dfile： 对于你的jar包的位置   -DgroupId -DartifactId -Dversion三个参数分别对于pom.xml文件中的配置参数选项：如下所示：

```
<dependency>
            <groupId>io.goeasy</groupId>
            <artifactId>goeasy-sdk</artifactId>
            <version>0.3.8</version>
</dependency>

<dependency>
            <groupId>org.csource</groupId>
            <artifactId>fastdfs-client-java</artifactId>
            <version>1.27</version>
</dependency>
mvn install:install-file -Dfile=fastdfs-client-java-1.27.jar -DgroupId=org.csource -DartifactId=fastdfs-client-java -Dversion=1.27 -Dpackaging=jar
```

3. 如上在pom.xml中配置即可。
