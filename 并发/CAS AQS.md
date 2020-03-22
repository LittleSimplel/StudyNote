### CAS

#### 前言

​	在JDK 5之前Java语言是靠synchronized关键字保证同步的，这会导致有锁

   锁机制存在以下问题：

（1）在多线程竞争下，加锁、释放锁会导致比较多的上下文切换和调度延时，引起性能问题。

（2）一个线程持有锁会导致其它所有需要此锁的线程挂起。

（3）如果一个优先级高的线程等待一个优先级低的线程释放锁会导致优先级倒置，引起性能风险。

​	volatile是不错的机制，但是volatile不能保证原子性。因此对于同步最终还是要回到锁机制上来。

​	**独占锁是一种悲观锁，synchronized就是一种独占锁，会导致其它所有需要锁的线程挂起，等待持有锁的线程释放锁。而另一个更加有效的锁就是乐观锁。所谓乐观锁就是，每次不加锁而是假设没有冲突而去完成某项操作，如果因为冲突失败就重试，直到成功为止。乐观锁用到的机制就是CAS，Compare and Swap。**

#### 概念

> CAS （compareAndSwap），中文叫比较交换，一种无锁原子算法。**用于实现多线程同步的原子指令**。过程是这样：它包含 3 个参数 CAS（V，E，N），V表示要更新变量的值，E表示预期值，N表示新值。仅当 V值等于E值时，才会将V的值设为N，如果V值和E值不同，则说明已经有其他线程做两个更新，则当前线程则什么都不做。最后，CAS 返回当前V的真实值。CAS 操作时抱着乐观的态度进行的（乐观锁），它总是认为自己可以成功完成操作。

> CAS的全称为Compare And Swap，直译就是比较交换。是一条CPU的原子指令，其作用是让CPU先进行比较两个值是否相等，然后原子地更新某个位置的值，其实现方式是基于硬件平台的汇编指令，在intel的CPU中，使用的是cmpxchg指令，就是说CAS是靠硬件实现的，从而在硬件层面提升效率。

> 当多个线程同时使用CAS 操作一个变量时，只有一个会胜出，并成功更新，其余均会失败。失败的线程不会挂起，仅是被告知失败，并且允许再次尝试，当然也允许实现的线程放弃操作。基于这样的原理，CAS 操作即使没有锁，也可以发现其他线程对当前线程的干扰。

> 与锁相比，使用CAS会使程序看起来更加复杂一些，但由于其非阻塞的，它对死锁问题天生免疫，并且，线程间的相互影响也非常小。更为重要的是，使用无锁的方式完全没有锁竞争带来的系统开销，也没有线程间频繁调度带来的开销，因此，他要比基于锁的方式拥有更优越的性能。

> 简单的说，CAS 需要你额外给出一个期望值，也就是你认为这个变量现在应该是什么样子的。如果变量不是你想象的那样，哪说明它已经被别人修改过了。你就需要重新读取，再次尝试修改就好了。

#### 底层原理

​	这样归功于硬件指令集的发展，实际上，我们可以使用同步将这两个操作变成原子的，但是这么做就没有意义了。所以我们只能靠硬件来完成，硬件保证一个从语义上看起来需要多次操作的行为只通过一条处理器指令就能完成。这类指令常用的有： 

1. 测试并设置（Tetst-and-Set） 

2. 获取并增加（Fetch-and-Increment） 

3. 交换（Swap） 

4. 比较并交换（Compare-and-Swap） 

5. 加载链接/条件存储（Load-Linked/Store-Conditional）

CPU 实现原子指令有2种方式： 

**1. 通过总线锁定来保证原子性。** 

​	总线锁定其实就是处理器使用了总线锁，所谓总线锁就是使用处理器提供的一个 LOCK# 信号，当一个处理器在总线上输出此信号时，其他处理器的请求将被阻塞住，那么该处理器可以独占共享内存。但是该方法成本太大。因此有了下面的方式。

**2、通过缓存锁定来保证原子性。** 

​	所谓 缓存锁定 是指内存区域如果被缓存在处理器的缓存行中，并且在Lock 操作期间被锁定，那么当他执行锁操作写回到内存时，处理器不在总线上声言 LOCK# 信号，而时修改内部的内存地址，并允许他的缓存一致性机制来保证操作的原子性，因为缓存一致性机制会阻止同时修改两个以上处理器缓存的内存区域数据（这里和 volatile 的可见性原理相同），当其他处理器回写已被锁定的缓存行的数据时，会使缓存行无效。

**注意：**有两种情况下处理器不会使用缓存锁定。 

1. 当操作的数据不能被缓存在处理器内部，或操作的数据跨多个缓存行时，则处理器会调用总线锁定。 

2. 有些处理器不支持缓存锁定，对于 Intel 486 和 Pentium 处理器，就是锁定的内存区域在处理器的缓存行也会调用总线锁定。

#### **CAS算法在JDK中的应用**

​	在原子类变量中，如java.util.concurrent.atomic中的AtomicXXX（而整个JUC都是建立在CAS之上的），都使用了这些底层的JVM支持为数字类型的引用类型提供一种高效的CAS操作，而在java.util.concurrent中的大多数类在实现时都直接或间接的使用了这些原子变量类。

分析concurrent包的源代码实现，会发现一个通用化的实现模式：

1. 首先，声明共享变量为volatile；
2. 然后，使用CAS的原子条件更新来实现线程之间的同步；
3. 同时，配合以volatile的读/写和CAS所具有的volatile读和写的内存语义来实现线程之间的通信。

concurrent包的实现示意图

![juc.png](http://ww1.sinaimg.cn/large/0062TeRXgy1gd2lm9qvv7j30mh0gbwf4.jpg)



#### CAS存在的问题

- 循环时间太长

  如果CAS一直不成功呢？这种情况绝对有可能发生，如果自旋CAS长时间地不成功，则会给CPU带来非常大的开销。在JUC中有些地方就限制了CAS自旋的次数，例如BlockingQueue的SynchronousQueue。

- 只能保证一个共享变量原子操作

  当对一个共享变量执行操作时，我们可以使用循环CAS的方式来保证原子操作，但是对多个共享变量操作时，循环CAS就无法保证操作的原子性，这个时候就可以用锁，或者有一个取巧的办法，就是把多个共享变量合并成一个共享变量来操作。比如有两个共享变量i＝2,j=a，合并一下ij=2a，然后用CAS来操作ij。从Java1.5开始JDK提供了**AtomicReference类来保证引用对象之间的原子性，你可以把多个变量放在一个对象里来进行CAS操作。**

- ABA问题

  CAS需要检查操作值有没有发生改变，如果没有发生改变则更新。但是存在这样一种情况：如果一个值原来是A，变成了B，然后又变成了A，那么在CAS检查的时候会发现没有改变，但是实质上它已经发生了改变，这就是所谓的ABA问题。对于ABA问题其解决方案是加上版本号，即在每个变量都加上一个版本号，每次改变时加1，即A —> B —> A，变成1A —> 2B —> 3A。

### AQS

#### 概念

​	aqs全称为AbstractQueuedSynchronizer，它提供了一个FIFO队列，可以看成是一个用来实现同步锁以及其他涉及到同步功能的核心组件，常见的有:ReentrantLock、CountDownLatch等。
​	AQS是一个抽象类，主要是通过继承的方式来使用，它本身没有实现任何的同步接口，仅仅是定义了同步状态的获取以及释放的方法来提供自定义的同步组件。
​	可以这么说，只要搞懂了AQS，那么J.U.C中绝大部分的api都能轻松掌握。

**AQS的核心思想**是，如果被请求的共享资源空闲，则将当前请求资源的线程设置为有效的工作线程，并将共享资源设置为锁定状态，如果被请求的共享资源被占用，那么就需要一套线程阻塞等待以及被唤醒时锁分配的机制，这个机制AQS是用CLH队列锁实现的，即将暂时获取不到锁的线程加入到队列中。
CLH（Craig，Landin，and Hagersten）队列是一个虚拟的双向队列，虚拟的双向队列即不存在队列实例，仅存在节点之间的关联关系。
**AQS是将每一条请求共享资源的线程封装成一个CLH锁队列的一个结点（Node），来实现锁的分配。**

用大白话来说，AQS就是基于CLH队列，用volatile修饰共享变量state，线程通过CAS去改变状态符，成功则获取锁成功，失败则进入等待队列，等待被唤醒。

**注意：AQS是自旋锁：**在等待唤醒的时候，经常会使用自旋（while(!cas())）的方式，不停地尝试获取锁，直到被其他线程获取成功

**实现了AQS的锁有：自旋锁、互斥锁、读锁写锁、条件产量、信号量、栅栏都是AQS的衍生物**

#### 功能

- 独占锁，每次只能有一个线程持有锁，比如前面给大家演示的ReentrantLock就是以独占方式实现的互斥锁
- 共享锁，允许多个线程同时获取锁，并发访问共享资源，比如ReentrantReadWriteLock

#### 使用

AQS底层使用了模板方法模式

同步器的设计是基于模板方法模式的，如果需要自定义同步器一般的方式是这样（模板方法模式很经典的一个应用）：

1. 使用者继承AbstractQueuedSynchronizer并重写指定的方法。（这些重写方法很简单，无非是对于共享资源state的获取和释放）

2. 将AQS组合在自定义同步组件的实现中，并调用其模板方法，而这些模板方法会调用使用者重写的方法。
   这和我们以往通过实现接口的方式有很大区别，这是模板方法模式很经典的一个运用。

   自定义同步器在实现的时候只需要实现共享资源state的获取和释放方式即可，至于具体线程等待队列的维护，AQS已经在顶层实现好了。自定义同步器实现的时候主要实现下面几种方法：
   **isHeldExclusively()：**该线程是否正在独占资源。只有用到condition才需要去实现它。
   **tryAcquire(int)：**独占方式。尝试获取资源，成功则返回true，失败则返回false。
   **tryRelease(int)：**独占方式。尝试释放资源，成功则返回true，失败则返回false。
   **tryAcquireShared(int)：**共享方式。尝试获取资源。负数表示失败；0表示成功，但没有剩余可用资源；正数表示成功，且有剩余资源。
   **tryReleaseShared(int)**：共享方式。尝试释放资源，如果释放后允许唤醒后续等待结点返回true，否则返回false。

ReentrantLock为例，（可重入独占式锁）：state初始化为0，表示未锁定状态，A线程lock()时，会调用tryAcquire()独占锁并将state+1.之后其他线程再想tryAcquire的时候就会失败，直到A线程unlock（）到state=0为止，其他线程才有机会获取该锁。A释放锁之前，自己也是可以重复获取此锁（state累加），这就是可重入的概念。
注意：获取多少次锁就要释放多少次锁，保证state是能回到零态的。

以CountDownLatch为例，任务分N个子线程去执行，state就初始化 为N，N个线程并行执行，每个线程执行完之后countDown（）一次，state就会CAS减一。当N子线程全部执行完毕，state=0，会unpark()主调用线程，主调用线程就会从await()函数返回，继续之后的动作。

```java
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
public class FightQueryDemo {

    private static List<String> company= Arrays.asList("东方航空","南方航空","海南航空");
    private static List<String> fightList=new ArrayList<>();

    public static void main(String[] args) throws InterruptedException{
        String origin="BJ";
        String dest="SH";
        Thread[] threads=new Thread[company.size()];
        CountDownLatch latch=new CountDownLatch(company.size());

        for (int i = 0; i < threads.length; i++) {
            String name=company.get(i);
            threads[i]=new Thread(()->{
                System.out.printf("%s 查询从%s到%s的机票\n",name,origin,dest);
                //随机产生票数
                int val=new Random().nextInt(10);
                try {
                    TimeUnit.SECONDS.sleep(val);
                    fightList.add(name+"--"+val);
                    System.out.printf("%s公司查询成功！\n",name);
                    latch.countDown();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            });
            threads[i].start();
        }
        latch.await();
        System.out.println("==============查询结果如下：================");
        fightList.forEach(System.out::println);
    }
}
```

CyclicBarrier 为例

```java
import java.util.Random;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.TimeUnit;

public class RaceDemo {

    public static void main(String[] args) {
        CyclicBarrier barrier=new CyclicBarrier(8);
        Thread[] play=new Thread[8];
        for (int i = 0; i < 8; i++) {
            play[i]=new Thread(()->{
                try {
                    TimeUnit.SECONDS.sleep(new Random().nextInt(10));
                    System.out.println(Thread.currentThread().getName()+"准备好了");
                    barrier.await();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                System.out.println("选手"+Thread.currentThread().getName()+"起跑");
            },"play["+i+"]");
            play[i].start();
        }
    }
}
```

Semaphore 信号量

一般来说，自定义同步器要么是独占方法，要么是共享方式，他们也只需实现tryAcquire-tryRelease、tryAcquireShared-tryReleaseShared中的一种即可。但AQS也支持自定义同步器同时**实现独占和共享两种方式，如ReentrantReadWriteLock。**
　在acquire() acquireShared()两种方式下，线程在等待队列中都是忽略中断的，**acquireInterruptibly()/acquireSharedInterruptibly()是支持响应中断**的。

