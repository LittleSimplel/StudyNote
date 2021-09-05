# 1 redis

## 1.1 概述

## 1.2 对比Nosql

## 1.3 对比缓存

## 1.4 数据结构和其使用场景

1. string (k/v)

   场景：计数器

2. list (k/列表)重复

   场景：

3. hash(k/对象)

   场景：

4. set(k/无序不重复集合)

   场景：

5. zset(k/有序不重复集合)

   场景：排行榜

## 1.5 三种特殊数据结构和其使用场景

## 1.6 事务

## 1.7 三种Java客户端

- jedis

- lettuce

- redisson

## 1.8 持久化

## 1.9 发布订阅

## 1.10 主从复制

## 1.11 缓存

为了系统性能的提升，我们一般都会将部分数据放入缓存中，加速访问，而 db 承担数据落盘工作

**哪些数据适合放入缓存？**

- **即时性、数据一致性要求不高的**
- **访问量大且更新频率不高的数据（读多、写少）**

### 1.11.1 缓存击穿，穿透，雪崩

高并发下**读**缓存存在的失效问题

- **缓存穿透**

  <img src="D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201031163704355.png" alt="image-20201031163704355" style="zoom:67%;" />

- **缓存雪崩**

  <img src="D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201031163949881.png" alt="image-20201031163949881" style="zoom:67%;" />

- **缓存击穿**（下图为缓存击穿）

  解决方式：单体项目本地锁，分布式项目分布式锁。
  
  <img src="D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201031164021131.png" alt="image-20201031164021131" style="zoom:67%;" />

### 1.11.2 缓存一致性

#### 1.11.2.1 **缓存数据一致性 - 双写模式**

两个线程写 最终只有一个线程写成功，后写成功的会把之前写的数据给覆盖，这就会造成脏数据

<img src="D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201101053613373.png" alt="image-20201101053613373" style="zoom:67%;" />



#### 1.11.2.2 **缓存数据一致性 - 双写模式**

  三个连接:

- 一号连接 写数据库 然后删缓存。

- 二号连接 写数据库时网络连接慢，还没有写入成功。

- 三号链接 直接读取数据，读到的是一号连接写入的数据，此时 二号链接写入数据成功并删除了缓存，三号开始更新缓存发现更新的是二号的缓存。

<img src="D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201101053834126.png" alt="image-20201101053834126" style="zoom:67%;" />

#### 1.11.2.3 缓存数据一致性解决方案

无论是双写模式还是失效模式，都会到这缓存不一致的问题，即多个实力同时更新会出事，怎么办？

- 1、如果是用户纯度数据（订单数据、用户数据），这并发几率很小，几乎不用考虑这个问题，缓存数据加上过期时间，每隔一段时间触发读的主动更新即可。
- 2、如果是菜单，商品介绍等基础数据，也可以去使用 canal 订阅，binlog 的方式。
- 3、缓存数据 + 过期时间也足够解决大部分业务对缓存的要求。
- 4、通过加锁保证并发读写，写写的时候按照顺序排好队，读读无所谓，所以适合读写锁，（业务不关心脏数据，允许临时脏数据可忽略）

**总结:**

- 我们能放入缓存的数据本来就不应该是实时性、一致性要求超高的。所以缓存数据的时候加上过期时间，保证每天拿到当前的最新值即可。
- 我们不应该过度设计，增加系统的复杂性。
- 遇到实时性、一致性要求高的数据，就应该查数据库，即使慢点。

### 1.11.3 Spring Cache

#### 1.11.3.1 基础概念

从3.1版本开始，Spring 框架就支持透明地向现有 Spring 应用程序添加缓存。与事务支持类似，缓存抽象允许在对代码影响最小的情况下一致地使用各种缓存解决方案。从 Spring 4.1 开始，缓存抽象在JSR-107注释和更多定制选项的支持下得到了显著扩展。

```java
/**
 *  8、整合SpringCache简化缓存开发
 *      1、引入依赖
 *          spring-boot-starter-cache
 *      2、写配置
 *          1、自动配置了那些
 *              CacheAutoConfiguration会导入 RedisCacheConfiguration
 *              自动配置好了缓存管理器，RedisCacheManager
 *          2、配置使用redis作为缓存
 *          Spring.cache.type=redis
 *
 *       4、原理
 *       CacheAutoConfiguration ->RedisCacheConfiguration ->
 *       自动配置了 RedisCacheManager ->初始化所有的缓存 -> 每个缓存决定使用什么配置
 *       ->如果redisCacheConfiguration有就用已有的，没有就用默认的
 *       ->想改缓存的配置，只需要把容器中放一个 RedisCacheConfiguration 即可
 *       ->就会应用到当前 RedisCacheManager管理所有缓存分区中
 */
```

#### 1.11.3.2 注解

对于缓存声明，Spring的缓存抽象提供了一组Java注解

```java
/**
@Cacheable: Triggers cache population:触发将数据保存到缓存的操作
@CacheEvict: Triggers cache eviction: 触发将数据从缓存删除的操作
@CachePut: Updates the cache without interfering with the method execution:不影响方法执行更新缓存
@Caching: Regroups multiple cache operations to be applied on a method:组合以上多个操作
@CacheConfig: Shares some common cache-related settings at class-level:在类级别共享缓存的相同配置
**/
```

注解使用

```java
/**
     * 1、每一个需要缓存的数据我们都需要指定放到那个名字的缓存【缓存分区的划分【按照业务类型划分】】
     * 2、@Cacheable({"category"})
     *      代表当前方法的结果需要缓存，如果缓存中有，方法不调用
     *      如果缓存中没有，调用方法，最后将方法的结果放入缓存
     * 3、默认行为:
     *      1、如果缓存中有，方法不用调用
     *      2、key默自动生成，缓存的名字:SimpleKey[](自动生成的key值)
     *      3、缓存中value的值，默认使用jdk序列化，将序列化后的数据存到redis
     *      3、默认的过期时间，-1
     *
     *    自定义操作
     *      1、指定缓存使用的key     key属性指定，接收一个SpEl
     *      2、指定缓存数据的存活时间  配置文件中修改ttl
     *      3、将数据保存为json格式
     * @return
     */
	//value 缓存的别名
     // key redis中key的名称，默认是方法名称
    @Cacheable(value = {"category"},key = "#root.method.name")
    @Override
    public List<CategoryEntity> getLevel1Categorys() {
        long l = System.currentTimeMillis();
        // parent_cid为0则是一级目录
        List<CategoryEntity> categoryEntities = baseMapper.selectList(new QueryWrapper<CategoryEntity>().eq("parent_cid", 0));
        System.out.println("耗费时间：" + (System.currentTimeMillis() - l));
        return categoryEntities;
    }
```

#### 1.11.3.3 配置

MyCacheConfig

```java
import org.springframework.boot.autoconfigure.cache.CacheProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;
/**
 * @author gcq
 * @Create 2020-11-01
 */
@EnableConfigurationProperties(CacheProperties.class)
@EnableCaching
@Configuration
public class MyCacheConfig {

    /**
     * 配置文件中的东西没有用上
     * 1、绑定的配置类是这样的
     *      CacheProperties.class中
     *      @ConfigurationProperties(prefix = "Spring.cache")
     * 2、要让配置文件中的（Spring.cache）配置生效
     *      @EnableConfigurationProperties(CacheProperties.class)
     * @param cacheProperties
     * @return
     */
    @Bean
    RedisCacheConfiguration redisCacheConfiguration(CacheProperties cacheProperties) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig();
        // 设置key的序列化
        config = config.serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(new StringRedisSerializer()));
        // 设置value序列化 ->JackSon
        config = config.serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(new GenericJackson2JsonRedisSerializer()));

        CacheProperties.Redis redisProperties = cacheProperties.getRedis();
        if (redisProperties.getTimeToLive() != null) {
            config = config.entryTtl(redisProperties.getTimeToLive());
        }
        if (redisProperties.getKeyPrefix() != null) {
            config = config.prefixKeysWith(redisProperties.getKeyPrefix());
        }
        if (!redisProperties.isCacheNullValues()) {
            config = config.disableCachingNullValues();
        }
        if (!redisProperties.isUseKeyPrefix()) {
            config = config.disableKeyPrefix();
        }
        return config;
    }

}
```

yaml 

```java
Spring:
  cache:
    type: redis
    redis:
      time-to-live: 3600000           # 过期时间
      key-prefix: CACHE_              # key前缀
      use-key-prefix: true            # 是否使用写入redis前缀
      cache-null-values: true         # 是否允许缓存空值
```

#### 1.11.3.4缓存使用

```java
@Cacheable(value = {"category"},key = "#root.method.name",sync = true)
@Override
public List<CategoryEntity> getLevel1Categorys() {
    long l = System.currentTimeMillis();
    // parent_cid为0则是一级目录
    List<CategoryEntity> categoryEntities = baseMapper.selectList(new QueryWrapper<CategoryEntity>().eq("parent_cid", 0));
    System.out.println("耗费时间：" + (System.currentTimeMillis() - l));
    return categoryEntities;
}
```

#### 1.11.3.5缓存更新

```java
    /**
     * 级联更新所有的关联数据
     * @CacheEvict 失效模式
     * 1、同时进行多种缓存操作 @Caching
     * 2、指定删除某个分区下的所有数据 @CacheEvict(value = {"category"},allEntries = true)
     * 3、存储同一类型的数据，都可以指定成同一分区，分区名默认就是缓存的前缀
     *
     * @param category
     */
    @Caching(evict = {
            @CacheEvict(value = {"category"},key = "'getLevel1Categorys'"),
            @CacheEvict(value = {"category"},key = "'getCatelogJson'")
    })
    //    @CacheEvict(value = {"category"},allEntries = true)
    @Transactional
    @Override
    public void updateCascate(CategoryEntity category) {
        // 更新自己表对象
        this.updateById(category);
        // 更新关联表对象
        categoryBrandRelationService.updateCategory(category.getCatId(), category.getName());
}
```

#### 1.11.3.6 缓存穿透问题解决

```java
/**
 * 1、每一个需要缓存的数据我们都需要指定放到那个名字的缓存【缓存分区的划分【按照业务类型划分】】
 * 2、@Cacheable({"category"})
 *      代表当前方法的结果需要缓存，如果缓存中有，方法不调用
 *      如果缓存中没有，调用方法，最后将方法的结果放入缓存
 * 3、默认行为:
 *      1、如果缓存中有，方法不用调用
 *      2、key默自动生成，缓存的名字:SimpleKey[](自动生成的key值)
 *      3、缓存中value的值，默认使用jdk序列化，将序列化后的数据存到redis
 *      3、默认的过期时间，-1
 *
 *    自定义操作
 *      1、指定缓存使用的key     key属性指定，接收一个SpEl
 *      2、指定缓存数据的存活时间  配置文件中修改ttl
 *      3、将数据保存为json格式
 * 4、Spring-Cache的不足：
 *      1、读模式：
 *          缓存穿透:查询一个null数据，解决 缓存空数据：ache-null-values=true
 *          缓存击穿:大量并发进来同时查询一个正好过期的数据，解决:加锁 ？ 默认是无加锁
 *          缓存雪崩:大量的key同时过期，解决：加上随机时间，Spring-cache-redis-time-to-live
 *       2、写模式：（缓存与数据库库不一致）
 *          1、读写加锁
 *          2、引入canal，感知到MySQL的更新去更新数据库
 *          3、读多写多，直接去数据库查询就行
 *
 *    总结：
 *      常规数据（读多写少，即时性，一致性要求不高的数据）完全可以使用SpringCache 写模式（ 只要缓存数据有过期时间就足够了）
```

## 1.12 分布式锁

本地锁只能锁住当前进程，所以需要分布式锁。

**分布式锁的演进：**

**阶段一：**

![image-20201031123441336](D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201031123441336.png)

**代码：**

```java
 Boolean lock = redisTemplate.opsForValue().setIfAbsent("lock", "0");
        if (lock) {
            // 加锁成功..执行业务
            Map<String,List<Catelog2Vo>> dataFromDb = getDataFromDB();
            redisTemplate.delete("lock"); // 删除锁
            return dataFromDb;
        } else {
            // 加锁失败，重试 synchronized()
            // 休眠100ms重试
            return getCatelogJsonFromDbWithRedisLock();
    }
```

**阶段二：**

![image-20201031123640746](D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201031123640746.png)

**代码：**

```java
 Boolean lock = redisTemplate.opsForValue().setIfAbsent()
        if (lock) {
            // 加锁成功..执行业务
            // 设置过期时间
            redisTemplate.expire("lock",30,TimeUnit.SECONDS);
            Map<String,List<Catelog2Vo>> dataFromDb = getDataFromDB();
            redisTemplate.delete("lock"); // 删除锁
            return dataFromDb;
        } else {
            // 加锁失败，重试 synchronized()
            // 休眠100ms重试
            return getCatelogJsonFromDbWithRedisLock();
 }
```

**阶段三：**

![image-20201031124210112](D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201031124210112.png)

**代码：**

```java
// 设置值同时设置过期时间
Boolean lock = redisTemplate.opsForValue().setIfAbsent("lock","111",300,TimeUnit.SECONDS);
if (lock) {
    // 加锁成功..执行业务
    // 设置过期时间,必须和加锁是同步的，原子的
    redisTemplate.expire("lock",30,TimeUnit.SECONDS);
    Map<String,List<Catelog2Vo>> dataFromDb = getDataFromDB();
    redisTemplate.delete("lock"); // 删除锁
    return dataFromDb;
} else {
    // 加锁失败，重试 synchronized()
    // 休眠100ms重试
    return getCatelogJsonFromDbWithRedisLock();
}
```

**阶段四：**

![image-20201031124615670](D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201031124615670.png)

**代码：**

```java
String uuid = UUID.randomUUID().toString();
        // 设置值同时设置过期时间
        Boolean lock = redisTemplate.opsForValue().setIfAbsent("lock",uuid,300,TimeUnit.SECONDS);
        if (lock) {
            // 加锁成功..执行业务
            // 设置过期时间,必须和加锁是同步的，原子的
//            redisTemplate.expire("lock",30,TimeUnit.SECONDS);
            Map<String,List<Catelog2Vo>> dataFromDb = getDataFromDB();
//            String lockValue = redisTemplate.opsForValue().get("lock");
//            if (lockValue.equals(uuid)) {
//                // 删除我自己的锁
//                redisTemplate.delete("lock"); // 删除锁
//            }
// 通过使用lua脚本进行原子性删除
            String script = "if redis.call('get',KEYS[1]) == ARGV[1] then return redis.call('del',KEYS[1]) else return 0 end";
                //删除锁
                Long lock1 = redisTemplate.execute(new DefaultRedisScript<Long>(script, Long.class), Arrays.asList("lock"), uuid);

            return dataFromDb;
        } else {
            // 加锁失败，重试 synchronized()
            // 休眠100ms重试
            return getCatelogJsonFromDbWithRedisLock();
        }
```

**阶段五：最终阶段**

![image-20201031130201609](D:\study\github\StudyNote\开发\开发体系\开发规范\img\image-20201031130201609.png)

**代码：**

```JAVA
 String uuid = UUID.randomUUID().toString();
        // 设置值同时设置过期时间
        Boolean lock = redisTemplate.opsForValue().setIfAbsent("lock",uuid,300,TimeUnit.SECONDS);
        if (lock) {
            System.out.println("获取分布式锁成功");
            // 加锁成功..执行业务
            // 设置过期时间,必须和加锁是同步的，原子的
//            redisTemplate.expire("lock",30,TimeUnit.SECONDS);
            Map<String,List<Catelog2Vo>> dataFromDb;
//            String lockValue = redisTemplate.opsForValue().get("lock");
//            if (lockValue.equals(uuid)) {
//                // 删除我自己的锁
//                redisTemplate.delete("lock"); // 删除锁
//            }
            try {
                dataFromDb = getDataFromDB();
            } finally {
                String script = "if redis.call('get',KEYS[1]) == ARGV[1] then return redis.call('del',KEYS[1]) else return 0 end";
                //删除锁
                Long lock1 = redisTemplate.execute(new DefaultRedisScript<Long>(script, Long.class), Arrays.asList("lock"), uuid);
            }
            return dataFromDb;
        } else {
            // 加锁失败，重试 synchronized()
            // 休眠200ms重试
            System.out.println("获取分布式锁失败，等待重试");
            try { TimeUnit.MILLISECONDS.sleep(200); } catch (InterruptedException e) { e.printStackTrace(); }
            return getCatelogJsonFromDbWithRedisLock();
        }
```

- 分布式加锁解锁都是这两套代码，可以封装成工具类
- 分布式锁有更专业的框架

### 1.12.1 分布式锁 - Redisson

1. pom

   ```JAVA
   <dependency>
       <groupId>org.redisson</groupId>
       <artifactId>redisson</artifactId>
       <version>3.12.0</version>
   </dependency>
   ```

2. Redisson - Lock 锁测试 & Redisson - Lock 看门狗原理 - Redisson 如何解决死锁

   ```java
   @RequestMapping("/hello")
   @ResponseBody
   public String hello(){
       // 1、获取一把锁，只要锁得名字一样，就是同一把锁
       RLock lock = redission.getLock("my-lock");
   
       // 2、加锁
       lock.lock(); // 阻塞式等待，默认加的锁都是30s时间
       // 1、锁的自动续期，如果业务超长，运行期间自动给锁续上新的30s，不用担心业务时间长，锁自动过期后被删掉
       // 2、加锁的业务只要运行完成，就不会给当前锁续期，即使不手动解锁，锁默认会在30s以后自动删除
   
       lock.lock(10, TimeUnit.SECONDS); //10s 后自动删除
       //问题 lock.lock(10, TimeUnit.SECONDS) 在锁时间到了后，不会自动续期
       // 1、如果我们传递了锁的超时时间，就发送给 redis 执行脚本，进行占锁，默认超时就是我们指定的时间
       // 2、如果我们为指定锁的超时时间，就是用 30 * 1000 LockWatchchdogTimeout看门狗的默认时间、
       //      只要占锁成功，就会启动一个定时任务，【重新给锁设置过期时间，新的过期时间就是看门狗的默认时间】,每隔10s就自动续期
       //      internalLockLeaseTime【看门狗时间】 /3,10s
   
       //最佳实践
       // 1、lock.lock(10, TimeUnit.SECONDS);省掉了整个续期操作，手动解锁
   
       try {
           System.out.println("加锁成功，执行业务..." + Thread.currentThread().getId());
           Thread.sleep(3000);
       } catch (Exception e) {
   
       } finally {
           // 解锁 将设解锁代码没有运行，reidsson会不会出现死锁
           System.out.println("释放锁...." + Thread.currentThread().getId());
           lock.unlock();
       }
   
       return "hello";
   }
   ```

3. 进入到 `Redisson` Lock 源码

   - 进入 `Lock` 的实现 发现 他调用的也是 `lock` 方法参数  时间为 -1

     ```java
     public void lock() {
             try {
                 this.lock(-1L, (TimeUnit)null, false);
             } catch (InterruptedException var2) {
                 throw new IllegalStateException();
             }
      }
     ```

   - 再次进入 `lock` 方法,发现他调用了 tryAcquire

     ```java
      private void lock(long leaseTime, TimeUnit unit, boolean interruptibly) throws InterruptedException {
             long threadId = Thread.currentThread().getId();
          	// 调用了 tryAcquire
             Long ttl = this.tryAcquire(leaseTime, unit, threadId);
             if (ttl != null) {
                 RFuture<RedissonLockEntry> future = this.subscribe(threadId);
                 if (interruptibly) {
                     this.commandExecutor.syncSubscriptionInterrupted(future);
                 } else {
                     this.commandExecutor.syncSubscription(future);
                 }
     
                 try {
                     while(true) {
                         // 调用了 tryAcquire
                         ttl = this.tryAcquire(leaseTime, unit, threadId);
                         if (ttl == null) {
                             return;
                  }
     ```

   - 进入 tryAcquire

     ```java
     private Long tryAcquire(long leaseTime, TimeUnit unit, long threadId) {
             return (Long)this.get(this.tryAcquireAsync(leaseTime, unit, threadId));
     }
     ```

   - 里头调用了 tryAcquireAsync,这里判断 laseTime != -1 就与刚刚的第一步传入的值有关系

     ```java
     private <T> RFuture<Long> tryAcquireAsync(long leaseTime, TimeUnit unit, long threadId) {
             if (leaseTime != -1L) {
                 return this.tryLockInnerAsync(leaseTime, unit, threadId, RedisCommands.EVAL_LONG);
             } else {
                 RFuture<Long> ttlRemainingFuture = this.tryLockInnerAsync(this.commandExecutor.getConnectionManager().getCfg().getLockWatchdogTimeout(), TimeUnit.MILLISECONDS, threadId, RedisCommands.EVAL_LONG);
                 ttlRemainingFuture.onComplete((ttlRemaining, e) -> {
                     if (e == null) {
                         if (ttlRemaining == null) {
                             this.scheduleExpirationRenewal(threadId);
                         }
     
                     }
                 });
                 return ttlRemainingFuture;
             }
         }
     ```

   - 进入到 `tryLockInnerAsync` 方法,执行lua脚本

     ```java
     <T> RFuture<T> tryLockInnerAsync(long leaseTime, TimeUnit unit, long threadId, RedisStrictCommand<T> command) {
             internalLockLeaseTime = unit.toMillis(leaseTime);
     
             return evalWriteAsync(getName(), LongCodec.INSTANCE, command,
                     "if (redis.call('exists', KEYS[1]) == 0) then " +
                             "redis.call('hincrby', KEYS[1], ARGV[2], 1); " +
                             "redis.call('pexpire', KEYS[1], ARGV[1]); " +
                             "return nil; " +
                             "end; " +
                             "if (redis.call('hexists', KEYS[1], ARGV[2]) == 1) then " +
                             "redis.call('hincrby', KEYS[1], ARGV[2], 1); " +
                             "redis.call('pexpire', KEYS[1], ARGV[1]); " +
                             "return nil; " +
                             "end; " +
                             "return redis.call('pttl', KEYS[1]);",
                     Collections.singletonList(getName()), internalLockLeaseTime, getLockName(threadId));
         }
     ```

   - `internalLockLeaseTime` 这个变量是锁的默认时间,**internalLockLeaseTime/3**时间检测锁有没有释放。

     ```java
       public RedissonLock(CommandAsyncExecutor commandExecutor, String name) {
             super(commandExecutor, name);
             this.commandExecutor = commandExecutor;
             this.id = commandExecutor.getConnectionManager().getId();
             // 锁的默认时间 getLockWatchdogTimeout()
             this.internalLockLeaseTime = commandExecutor.getConnectionManager().getCfg().getLockWatchdogTimeout();
             this.entryName = id + ":" + name;
             this.pubSub = commandExecutor.getConnectionManager().getSubscribeService().getLockPubSub();
         }
     ```

     ```java
      public long getLockWatchdogTimeout() {
             return lockWatchdogTimeout;
         }
     ```

     ```java
     // 默认30秒 
     private long lockWatchdogTimeout = 30 * 1000;
     ```

### 1.12.2  Reidsson - 读写锁

```java
    /**
     * 保证一定能读取到最新数据，修改期间，写锁是一个排他锁（互斥锁，独享锁）读锁是一个共享锁
     * 写锁没释放读锁就必须等待
     * 读 + 读 相当于无锁，并发读，只会在 reids中记录好，所有当前的读锁，他们都会同时加锁成功
     * 写 + 读 等待写锁释放
     * 写 + 写 阻塞方式
     * 读 + 写 有读锁，写也需要等待
     * 只要有写的存在，都必须等待
     * @return String
     */
    @RequestMapping("/write")
    @ResponseBody
    public String writeValue() {

        RReadWriteLock lock = redission.getReadWriteLock("rw_lock");
        String s = "";
        RLock rLock = lock.writeLock();
        try {
            // 1、改数据加写锁，读数据加读锁
            rLock.lock();
            System.out.println("写锁加锁成功..." + Thread.currentThread().getId());
            s = UUID.randomUUID().toString();
            try { TimeUnit.SECONDS.sleep(3); } catch (InterruptedException e) { e.printStackTrace(); }
            redisTemplate.opsForValue().set("writeValue",s);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            rLock.unlock();
            System.out.println("写锁释放..." + Thread.currentThread().getId());
        }
        return s;
    }

    @RequestMapping("/read")
    @ResponseBody
    public String readValue() {
        RReadWriteLock lock = redission.getReadWriteLock("rw_lock");
        RLock rLock = lock.readLock();
        String s = "";
        rLock.lock();
        try {
            System.out.println("读锁加锁成功..." + Thread.currentThread().getId());
            s = (String) redisTemplate.opsForValue().get("writeValue");
            try { TimeUnit.SECONDS.sleep(3); } catch (InterruptedException e) { e.printStackTrace(); }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            rLock.unlock();
            System.out.println("读锁释放..." + Thread.currentThread().getId());
        }
        return s;
    }
```

### 1.12.3 Redisson - 闭锁

```java
/**
 * 放假锁门
 * 1班没人了
 * 5个班级走完，我们可以锁们了
 * @return
 */
@GetMapping("/lockDoor")
@ResponseBody
public String lockDoor() throws InterruptedException {
    RCountDownLatch door = redission.getCountDownLatch("door");
    door.trySetCount(5);
    door.await();//等待闭锁都完成

    return "放假了....";
}
@GetMapping("/gogogo/{id}")
@ResponseBody
public String gogogo(@PathVariable("id") Long id) {
    RCountDownLatch door = redission.getCountDownLatch("door");
    door.countDown();// 计数器减一

    return id + "班的人走完了.....";
}
```

和 JUC 的 CountDownLatch 一致,await()等待闭锁完成,countDown() 把计数器减掉后 await就会放行

### 1.12.3 Redisson - 信号量

```java
/**
 * 车库停车
 * 3车位
 * @return
 */
@GetMapping("/park")
@ResponseBody
public String park() throws InterruptedException {
    RSemaphore park = redission.getSemaphore("park");
    boolean b = park.tryAcquire();//获取一个信号，获取一个值，占用一个车位
    return "ok=" + b;
}

@GetMapping("/go")
@ResponseBody
public String go() {
    RSemaphore park = redission.getSemaphore("park");
    park.release(); //释放一个车位
    return "ok";
}
```

