### 类加载

#### jvm架构图

![第02章_JVM架构-中](D:\study\github\StudyNote\jvm\img\JVM上篇配图\第02章_JVM架构-中.jpg)

#### 类加载器子系统

**作用：**

1. **类加载器子系统负责从文件系统或者网络中加载Class文件**，class文件在文件开头有特定的文件标识。
2. ClassLoader只负责class文件的加载，至于它是否可以运行，则由Execution Engine决定。
3. **加载的类信息存放于一块称为方法区的内存空间**。除了类的信息外，方法区中还会存放运行时常量池信息，可能还包括字符串字面量和数字常量（这部分常量信息是Class文件中常量池部分的内存映射

#### 类加载过程

```java
public class HelloLoader {
    public static void main(String[] args) {
        System.out.println("谢谢ClassLoader加载我....");
        System.out.println("你的大恩大德，我下辈子再报！");
    }
}
```

![第02章_类的加载过程](D:\study\github\StudyNote\jvm\img\JVM上篇配图\第02章_类的加载过程.jpg)

完整的流程图如下所示：**加载 --> 链接（验证 --> 准备 --> 解析） --> 初始化**

![类加载验证初始化](D:\study\github\StudyNote\jvm\img\JVM上篇配图\类加载验证初始化.png)

##### 加载

1. **通过一个类的全限定名获取定义此类的二进制字节流**
2. 将这个字节流所代表的静态存储结构转化为**方法区的运行时数据结构**
3. **在内存中生成一个代表这个类的java.lang.Class对象**，作为方法区这个类的各种数据的访问入口

> **加载class文件的方式**

1. 从本地系统中直接加载
2. 通过网络获取，典型场景：Web Applet
3. 从zip压缩包中读取，成为日后jar、war格式的基础
4. 运行时计算生成，使用最多的是：动态代理技术
5. 由其他文件生成，典型场景：JSP应用从专有数据库中提取.class文件，比较少见
6. 从加密文件中获取，典型的防Class文件被反编译的保护措施

##### 链接

- **链接分为三个子阶段：验证 --> 准备 --> 解析**

  > **验证**

  1. **目的在于确保Class文件的字节流中包含信息符合当前虚拟机要求，保证被加载类的正确性，不会危害虚拟机自身安全**
  2. 主要包括四种验证，文件格式验证，元数据验证，字节码验证，符号引用验证。

  > **准备**

  1. **为类变量分配内存并且设置该类变量的默认初始值**
  2. 这里不包含用final修饰的static，因为final在编译的时候就会分配好了默认值，准备阶段会显式初始化
  3. 注意：这里不会为实例变量分配初始化，类变量会分配在方法区中，而实例变量是会随着对象一起分配到Java堆中

  > **解析**

  1. **将常量池内的符号引用转换为直接引用的过程**
  2. 事实上，解析操作往往会伴随着JVM在执行完初始化之后再执行
  3. 符号引用就是一组符号来描述所引用的目标。符号引用的字面量形式明确定义在《java虚拟机规范》的class文件格式中。直接引用就是直接指向目标的指针、相对偏移量或一个间接定位到目标的句柄
  4. 解析动作主要针对类或接口、字段、类方法、接口方法、方法类型等。对应常量池中的CONSTANT Class info、CONSTANT Fieldref info、CONSTANT Methodref info等

  > **初始化阶段**

  1. **初始化阶段就是执行类构造器方法`<clinit>()`的过程**
  2. 此方法不需定义，是javac编译器自动收集类中的**所有类变量的赋值动作和静态代码块中的语句合并而来**，**当我们代码中包含static变量和静态代码块的时候，就会有clinit方法**
  3. **`<clinit>()`方法中的指令按语句在源文件中出现的顺序执行**
  4. `<clinit>()`不同于类的构造器。（关联：构造器是虚拟机视角下的`<init>()`）
  5. **若该类具有父类，JVM会保证子类的`<clinit>()`执行前，父类的`<clinit>()`已经执行完毕**
  6. **虚拟机必须保证一个类的`<clinit>()`方法在多线程下被同步加锁（一个class同时只会被一个线程加载）**

  ```java
  public class ClassInitTest {
      private static int num = 1;
      private static int number = 10;      //linking之prepare: number = 0 --> initial: 10 --> 20
  
      static {
          num = 2;
          number = 20;
          System.out.println(num);
          //System.out.println(number);    //报错：非法的前向引用（可以赋值，但不能调用）
      }
  
      public static void main(String[] args) {
          System.out.println(ClassInitTest.num);//2
          System.out.println(ClassInitTest.number);//10
      }
  }
  ```

  **IDEA 中安装 JClassLib 插件**

#### 类加载器分类