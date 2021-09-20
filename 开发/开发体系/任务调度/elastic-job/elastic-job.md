# 1 E-Job

## 1.1 任务调度高级需求

**Quartz 的不足：**

1. 作业只能通过 DB 抢占随机负载，无法协调 。
2. 任务不能分片——单个任务数据太多了跑不完，消耗线程，负载不均 。
3. 作业日志可视化监控、统计。

## 1.2 E-job 简介

Elastic-Job 是 ddframe 中的 dd-job 作业模块分离出来的作业框架，基于 Quartz 和 Curator 开发，在 2015 年开源。它是一个无中心化的分布式调度框架。因为数据库缺少分布式协调功能（比如选主），替换为 Zookeeper 后，增加了弹性扩容和数据分片的功能。

**轻量级，无中心化解决方案。**

为什么说是去中心化呢？因为没有统一的调度中心。集群的每个节点都是对等的， 节点之间通过注册中心进行分布式协调。E-Job 存在主节点的概念，但是主节点没有调度的功能，而是用于处理一些集中式任务，如分片，清理运行时信息等。

**如果 ZK 挂了怎么办？**

每个任务有独立的线程池

<img src="D:\study\github\StudyNote\开发\开发体系\任务调度\img\image-20210908140016705.png" alt="image-20210908140016705" style="zoom:67%;" />

**从官网开始**

https://shardingsphere.apache.org/elasticjob/current/cn/overview/

Elastic-Job 最开始只有一个 elastic-job-core 的项目，在 2.X 版本以后主要分为 Elastic-Job-Lite 和 Elastic-Job-Cloud 两个子项目。其中，Elastic-Job-Lite 定位为轻量 级 无 中 心 化 解 决 方 案 ， 使 用 jar 包 的 形 式 提 供 分 布 式 任 务 的 协 调 服 务 。 而 Elastic-Job-Cloud 使用 Mesos + Docker 的解决方案，额外提供资源治理、应用分发以及进程隔离等服务（跟 Lite 的区别只是部署方式不同，他们使用相同的 API，只要开发 一次）。

## 1.3 功能特性

- 分布式调度协调：用 ZK 实现注册中心 。
- 错过执行作业重触发（Misfire） 。
- 支持并行调度（任务分片）。
-  作业分片一致性，保证同一分片在分布式环境中仅一个执行实例 。
- 弹性扩容缩容：将任务拆分为 n 个任务项后，各个服务器分别执行各自分配到的 任务项。一旦有新的服务器加入集群，或现有服务器下线，elastic-job 将在保留 本次任务执行不变的情况下，下次任务开始前触发任务重分片。
- 失效转移 failover：弹性扩容缩容在下次作业运行前重分片，但本次作业执行的过 程中，下线的服务器所分配的作业将不会重新被分配。失效转移功能可以在本次 作业运行中用空闲服务器抓取孤儿作业分片执行。同样失效转移功能也会牺牲部 分性能。  支持作业生命周期操作（Listener）。
-  丰富的作业类型（Simple、DataFlow、Script） 。
-  Spring 整合以及命名空间提供 。
-  运维平台。

## 1.4 项目架构

应用在各自的节点执行任务，通过 ZK 注册中心协调。节点注册、节点选举、任务分片、监听都在 E-Job 的代码中完成。

<img src="D:\study\github\StudyNote\开发\开发体系\任务调度\img\image-20210908150510861.png" alt="image-20210908150510861" style="zoom:67%;" />

## 1.5 Java 开发

### 1.5.1 pom 依赖

```java
<dependency>
	<groupId>com.dangdang</groupId>
	<artifactId>elastic-job-lite-core</artifactId>
	<version>2.1.5</version>
</dependency>
```

### 1.5.2 任务类型

#### 1.5.2.1 SimpleJob

SimpleJob: 简单实现，未经任何封装的类型。需实现 SimpleJob 接口

```java
public class MyElasticJob implements SimpleJob {
	public void execute(ShardingContext context) {
			System.out.println(String.format("Item: %s | Time: %s | Thread: %s ", context.getShardingItem(), new 			 SimpleDateFormat("HH:mm:ss").format(new Date()), Thread.currentThread().getId()));
		}
}
```

#### 1.5.2.2 DataFlowJob

DataFlowJob：Dataflow 类型用于处理数据流，必须实现 fetchData()和 processData()的方法，一个用来获取数据，一个用来处理获取到的数据。

```java
public class MyDataFlowJob implements DataflowJob<String> {
	@Override
	public List<String> fetchData(ShardingContext shardingContext) {
	// 获取到了数据
	return Arrays.asList("qingshan","jack","seven");
  }
	@Override
	public void processData(ShardingContext shardingContext, List<String> data) {
	data.forEach(x-> System.out.println("开始处理数据："+x));
	}
}	
```

#### 1.5.2.3 ScriptJob

Script：Script 类型作业意为脚本类型作业，支持 shell，python，perl 等所有类型 脚本。D 盘下新建 1.bat，内容

```java
@echo ------【脚本任务】Sharding Context: %*
```

### 1.5.3 E-Job 配置

1. ZK 注册中心配置（后面继续分析） 
2. 作业配置（从底层往上层：Core——Type——Lite）

| 配置级别 | 配置级别 | 配置内容 |
| -------- | -------- | -------- |
| 配置内容 |          |          |
|          |          |          |
|          |          |          |

