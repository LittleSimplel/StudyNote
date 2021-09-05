一：确保tomcat 在点击bin\startup 文件可以正常启动访问；

二：本机安装有JDK；

三：本机环境变量配置：JAVA_HOME：C:\Java\jdk1.7.0_17;

四：本机Tomcat环境变量配置：CATALINA_HOME：D:\work\apache-tomcat-7.0.72;     

五：找到Tomcat目前中bin目前下的service.bat并编辑；搜索：”JvmMx 256“ 后面加空格 增加：Startup=auto

![img](D:\study\github\StudyNote\开发\java\tomcat\img\Center)

六：找到service.bat，打开搜索”SERVICE_NAME“ 可以看到服务名称；

​          						   ![img](D:\study\github\StudyNote\开发\java\tomcat\img\Center1)

七：启动：cmd窗口进入到tomcat的bin目录下：执行命令：service.bat install iatoms-activiti

八：删除：cmd窗口进入到tomcat的bin目录下：执行命令：service.bat remove iatoms-activiti

九：设置开机启动，以后就可以随机启动了，配图如下：


![img](D:\study\github\StudyNote\开发\java\tomcat\img\Center2)