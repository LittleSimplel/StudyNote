### Maven坐标主要组成
- groupId：定义当前Maven项目隶属项目
- artifactId：定义实际项目中的一个模块
- version：定义当前项目的当前版本
- packaging：定义该项目的打包方式

### 依赖范围
依赖范围scope用来控制依赖和编译、测试、运行的classpath的关系
**compile**：**默认**编译依赖范围。对于编译、测试、运行三种classpath都有效。
**test**：测试依赖范围。只对于测试classpath有效。如 junit
**provided**：对于编译、测试的classpath有效，但对于运行无效，因为容器已经提供，如: servlet-api
**runtime**：运行时提供。如jdbc驱动。