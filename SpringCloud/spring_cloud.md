### pom文件

### 模块

| 模块名                     | 端口 | 说明                  |
| -------------------------- | ---- | --------------------- |
| cloud-provider-payment8001 | 8001 | 支付                  |
| cloud-provider-payment8002 | 8002 | 支付                  |
| cloud-consumer-order80     | 80   | 消费                  |
| cloud-eureka-server7001    | 7001 | eureka服务端          |
| cloud-eureka-server7002    | 7002 | eureka服务端          |
| cloud-provider-payment8004 | 8004 | 支付  注册到zookeeper |

### 注册中心

- zookeeper （cp）

  查看zookeeper 注册的服务信息

  ```shell
  [zk: localhost:2181(CONNECTED) 7] ls
  ls [-s] [-w] [-R] path
  [zk: localhost:2181(CONNECTED) 8] ls /services 
  [cloud-provider-payment]
  [zk: localhost:2181(CONNECTED) 9] ls /services/cloud-provider-payment
  [4455f707-999b-476a-878a-0432a979a1bb]
  [zk: localhost:2181(CONNECTED) 10] get /services/cloud-provider-payment/4455f707-999b-476a-878a-0432a979a1bb
  {"name":"cloud-provider-payment","id":"4455f707-999b-476a-878a-0432a979a1bb","address":"localhost","port":8004,"sslPort":null,"payload":{"@class":"org.springframework.cloud.zookeeper.discovery.ZookeeperInstance","id":"application-1","name":"cloud-provider-payment","metadata":{}},"registrationTimeUTC":1601380498720,"serviceType":"DYNAMIC","uriSpec":{"parts":[{"value":"scheme","variable":true},{"value":"://","variable":false},{"value":"address","variable":true},{"value":":","variable":false},{"value":"port","variable":true}]}}
  [zk: localhost:2181(CONNECTED) 11] 
  ```

  当手动停止服务，zookeeper一段时间收不到心跳后，会删除节点，所以注册的服务节点是临时节点。

  重启服务后，注册到zookeeper，会重新生成节点和新的序列id

- consul  （CP）

- eureka  （Ap）

  

### Ribbon

1. restTemplate+负载均衡。
2. 随机轮询   取余数（cas+自旋）。

### OpenFeign

1. 面向接口（接口（动态代理）+注解）
2. 超时：默认1s。（连接超时和读超时）

#### Hystrix

1. 降级
2. 熔断
3. 限流