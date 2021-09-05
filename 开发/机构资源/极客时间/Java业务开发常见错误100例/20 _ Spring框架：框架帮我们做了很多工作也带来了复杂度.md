<audio title="20 _ Spring框架：框架帮我们做了很多工作也带来了复杂度" src="https://static001.geekbang.org/resource/audio/e1/d6/e1fd22aa528fd1a2971d5e5e2199a7d6.mp3" controls="controls"></audio> 
<p>你好，我是朱晔。今天，我们聊聊Spring框架给业务代码带来的复杂度，以及与之相关的坑。</p><p>在上一讲，通过AOP实现统一的监控组件的案例，我们看到了IoC和AOP配合使用的威力：当对象由Spring容器管理成为Bean之后，我们不但可以通过容器管理配置Bean的属性，还可以方便地对感兴趣的方法做AOP。</p><p>不过，前提是对象必须是Bean。你可能会觉得这个结论很明显，也很容易理解啊。但就和上一讲提到的Bean默认是单例一样，理解起来简单，实践的时候却非常容易踩坑。其中原因，一方面是，理解Spring的体系结构和使用方式有一定曲线；另一方面是，Spring多年发展堆积起来的内部结构非常复杂，这也是更重要的原因。</p><p>在我看来，Spring框架内部的复杂度主要表现为三点：</p><ul>
<li>第一，Spring框架借助IoC和AOP的功能，实现了修改、拦截Bean的定义和实例的灵活性，因此真正执行的代码流程并不是串行的。</li>
<li>第二，Spring Boot根据当前依赖情况实现了自动配置，虽然省去了手动配置的麻烦，但也因此多了一些黑盒、提升了复杂度。</li>
<li>第三，Spring Cloud模块多版本也多，Spring Boot 1.x和2.x的区别也很大。如果要对Spring Cloud或Spring Boot进行二次开发的话，考虑兼容性的成本会很高。</li>
</ul><!-- [[[read_end]]] --><p>今天，我们就通过配置AOP切入Spring Cloud Feign组件失败、Spring Boot程序的文件配置被覆盖这两个案例，感受一下Spring的复杂度。我希望这一讲的内容，能帮助你面对Spring这个复杂框架出现的问题时，可以非常自信地找到解决方案。</p><h2>Feign AOP切不到的诡异案例</h2><p>我曾遇到过这么一个案例：使用Spring Cloud做微服务调用，为方便统一处理Feign，想到了用AOP实现，即使用within指示器匹配feign.Client接口的实现进行AOP切入。</p><p>代码如下，通过@Before注解在执行方法前打印日志，并在代码中定义了一个标记了@FeignClient注解的Client类，让其成为一个Feign接口：</p><pre><code>//测试Feign
@FeignClient(name = &quot;client&quot;)
public interface Client {
    @GetMapping(&quot;/feignaop/server&quot;)
    String api();
}

//AOP切入feign.Client的实现
@Aspect
@Slf4j
@Component
public class WrongAspect {
    @Before(&quot;within(feign.Client+)&quot;)
    public void before(JoinPoint pjp) {
        log.info(&quot;within(feign.Client+) pjp {}, args:{}&quot;, pjp, pjp.getArgs());
    }
}

//配置扫描Feign
@Configuration
@EnableFeignClients(basePackages = &quot;org.geekbang.time.commonmistakes.spring.demo4.feign&quot;)
public class Config {
}
</code></pre><p>通过Feign调用服务后可以看到日志中有输出，的确实现了feign.Client的切入，切入的是execute方法：</p><pre><code>[15:48:32.850] [http-nio-45678-exec-1] [INFO ] [o.g.t.c.spring.demo4.WrongAspect        :20  ] - within(feign.Client+) pjp execution(Response feign.Client.execute(Request,Options)), args:[GET http://client/feignaop/server HTTP/1.1

Binary data, feign.Request$Options@5c16561a]
</code></pre><p>一开始这个项目使用的是客户端的负载均衡，也就是让Ribbon来做负载均衡，代码没啥问题。后来因为后端服务通过Nginx实现服务端负载均衡，所以开发同学把@FeignClient的配置设置了URL属性，直接通过一个固定URL调用后端服务：</p><pre><code>@FeignClient(name = &quot;anotherClient&quot;,url = &quot;http://localhost:45678&quot;)
public interface ClientWithUrl {
    @GetMapping(&quot;/feignaop/server&quot;)
    String api();
}
</code></pre><p>但这样配置后，之前的AOP切面竟然失效了，也就是within(feign.Client+)无法切入ClientWithUrl的调用了。</p><p>为了还原这个场景，我写了一段代码，定义两个方法分别通过Client和ClientWithUrl这两个Feign进行接口调用：</p><pre><code>@Autowired
private Client client;

@Autowired
private ClientWithUrl clientWithUrl;

@GetMapping(&quot;client&quot;)
public String client() {
    return client.api();
}

@GetMapping(&quot;clientWithUrl&quot;)
public String clientWithUrl() {
    return clientWithUrl.api();
}
</code></pre><p>可以看到，调用Client后AOP有日志输出，调用ClientWithUrl后却没有：</p><pre><code>[15:50:32.850] [http-nio-45678-exec-1] [INFO ] [o.g.t.c.spring.demo4.WrongAspect        :20  ] - within(feign.Client+) pjp execution(Response feign.Client.execute(Request,Options)), args:[GET http://client/feignaop/server HTTP/1.1

Binary data, feign.Request$Options@5c16561
</code></pre><p>这就很费解了。难道为Feign指定了URL，其实现就不是feign.Clinet了吗？</p><p>要明白原因，我们需要分析一下FeignClient的创建过程，也就是分析FeignClientFactoryBean类的getTarget方法。源码第4行有一个if判断，当URL没有内容也就是为空或者不配置时调用loadBalance方法，在其内部通过FeignContext从容器获取feign.Client的实例：</p><pre><code>&lt;T&gt; T getTarget() {
	FeignContext context = this.applicationContext.getBean(FeignContext.class);
	Feign.Builder builder = feign(context);
	if (!StringUtils.hasText(this.url)) {
		...
		return (T) loadBalance(builder, context,
				new HardCodedTarget&lt;&gt;(this.type, this.name, this.url));
	}
	...
	String url = this.url + cleanPath();
	Client client = getOptional(context, Client.class);
	if (client != null) {
		if (client instanceof LoadBalancerFeignClient) {
			// not load balancing because we have a url,
			// but ribbon is on the classpath, so unwrap
			client = ((LoadBalancerFeignClient) client).getDelegate();
		}
		builder.client(client);
	}
	...
}
protected &lt;T&gt; T loadBalance(Feign.Builder builder, FeignContext context,
		HardCodedTarget&lt;T&gt; target) {
	Client client = getOptional(context, Client.class);
	if (client != null) {
		builder.client(client);
		Targeter targeter = get(context, Targeter.class);
		return targeter.target(this, builder, context, target);
	}
...
}
protected &lt;T&gt; T getOptional(FeignContext context, Class&lt;T&gt; type) {
	return context.getInstance(this.contextId, type);
}
</code></pre><p>调试一下可以看到，client是LoadBalanceFeignClient，已经是经过代理增强的，明显是一个Bean：</p><p><img src="https://static001.geekbang.org/resource/image/05/fd/0510e28cd764aaf7f1b4b4ca03049ffd.png" alt=""></p><p>所以，没有指定URL的@FeignClient对应的LoadBalanceFeignClient，是可以通过feign.Client切入的。</p><p>在我们上面贴出来的源码的16行可以看到，当URL不为空的时候，client设置为了LoadBalanceFeignClient的delegate属性。其原因注释中有提到，因为有了URL就不需要客户端负载均衡了，但因为Ribbon在classpath中，所以需要从LoadBalanceFeignClient提取出真正的Client。断点调试下可以看到，这时client是一个ApacheHttpClient：</p><p><img src="https://static001.geekbang.org/resource/image/1b/30/1b872a900be7327f74bc09bde4c54230.png" alt=""></p><p>那么，这个ApacheHttpClient是从哪里来的呢？这里，我教你一个小技巧：如果你希望知道一个类是怎样调用栈初始化的，可以在构造方法中设置一个断点进行调试。这样，你就可以在IDE的栈窗口看到整个方法调用栈，然后点击每一个栈帧看到整个过程。</p><p>用这种方式，我们可以看到，是HttpClientFeignLoadBalancedConfiguration类实例化的ApacheHttpClient：</p><p><img src="https://static001.geekbang.org/resource/image/7b/9a/7b712acf6d7062ae82f1fd04b954ff9a.png" alt=""></p><p>进一步查看HttpClientFeignLoadBalancedConfiguration的源码可以发现，LoadBalancerFeignClient这个Bean在实例化的时候，new出来一个ApacheHttpClient作为delegate放到了LoadBalancerFeignClient中：</p><pre><code>@Bean
@ConditionalOnMissingBean(Client.class)
public Client feignClient(CachingSpringLoadBalancerFactory cachingFactory,
      SpringClientFactory clientFactory, HttpClient httpClient) {
   ApacheHttpClient delegate = new ApacheHttpClient(httpClient);
   return new LoadBalancerFeignClient(delegate, cachingFactory, clientFactory);
}

public LoadBalancerFeignClient(Client delegate,
      CachingSpringLoadBalancerFactory lbClientFactory,
      SpringClientFactory clientFactory) {
   this.delegate = delegate;
   this.lbClientFactory = lbClientFactory;
   this.clientFactory = clientFactory;
}
</code></pre><p>显然，ApacheHttpClient是new出来的，并不是Bean，而LoadBalancerFeignClient是一个Bean。</p><p>有了这个信息，我们再来捋一下，为什么within(feign.Client+)无法切入设置过URL的@FeignClient ClientWithUrl：</p><ul>
<li>表达式声明的是切入feign.Client的实现类。</li>
<li>Spring只能切入由自己管理的Bean。</li>
<li><strong>虽然LoadBalancerFeignClient和ApacheHttpClient都是feign.Client接口的实现，但是HttpClientFeignLoadBalancedConfiguration的自动配置只是把前者定义为Bean，后者是new出来的、作为了LoadBalancerFeignClient的delegate，不是Bean</strong>。</li>
<li>在定义了FeignClient的URL属性后，我们获取的是LoadBalancerFeignClient的delegate，它不是Bean。</li>
</ul><p>因此，定义了URL的FeignClient采用within(feign.Client+)无法切入。</p><p>那，如何解决这个问题呢？有一位同学提出，修改一下切点表达式，通过@FeignClient注解来切：</p><pre><code>@Before(&quot;@within(org.springframework.cloud.openfeign.FeignClient)&quot;)
public void before(JoinPoint pjp){
    log.info(&quot;@within(org.springframework.cloud.openfeign.FeignClient) pjp {}, args:{}&quot;, pjp, pjp.getArgs());
}
</code></pre><p>修改后通过日志看到，AOP的确切成功了：</p><pre><code>[15:53:39.093] [http-nio-45678-exec-3] [INFO ] [o.g.t.c.spring.demo4.Wrong2Aspect       :17  ] - @within(org.springframework.cloud.openfeign.FeignClient) pjp execution(String org.geekbang.time.commonmistakes.spring.demo4.feign.ClientWithUrl.api()), args:[]
</code></pre><p>但仔细一看就会发现，<strong>这次切入的是ClientWithUrl接口的API方法，并不是client.Feign接口的execute方法，显然不符合预期</strong>。</p><p>这位同学犯的错误是，没有弄清楚真正希望切的是什么对象。@FeignClient注解标记在Feign Client接口上，所以切的是Feign定义的接口，也就是每一个实际的API接口。而通过feign.Client接口切的是客户端实现类，切到的是通用的、执行所有Feign调用的execute方法。</p><p>那么问题来了，ApacheHttpClient不是Bean无法切入，切Feign接口本身又不符合要求。怎么办呢？</p><p>经过一番研究发现，ApacheHttpClient其实有机会独立成为Bean。查看HttpClientFeignConfiguration的源码可以发现，当没有ILoadBalancer类型的时候，自动装配会把ApacheHttpClient设置为Bean。</p><p>这么做的原因很明确，如果我们不希望做客户端负载均衡的话，应该不会引用Ribbon组件的依赖，自然没有LoadBalancerFeignClient，只有ApacheHttpClient：</p><pre><code>@Configuration
@ConditionalOnClass(ApacheHttpClient.class)
@ConditionalOnMissingClass(&quot;com.netflix.loadbalancer.ILoadBalancer&quot;)
@ConditionalOnMissingBean(CloseableHttpClient.class)
@ConditionalOnProperty(value = &quot;feign.httpclient.enabled&quot;, matchIfMissing = true)
protected static class HttpClientFeignConfiguration {
	@Bean
	@ConditionalOnMissingBean(Client.class)
	public Client feignClient(HttpClient httpClient) {
		return new ApacheHttpClient(httpClient);
	}
}
</code></pre><p>那，把pom.xml中的ribbon模块注释之后，是不是可以解决问题呢？</p><pre><code>&lt;dependency&gt;
  &lt;groupId&gt;org.springframework.cloud&lt;/groupId&gt;
  &lt;artifactId&gt;spring-cloud-starter-netflix-ribbon&lt;/artifactId&gt;
&lt;/dependency&gt;
</code></pre><p>但，问题并没解决，启动出错误了：</p><pre><code>Caused by: java.lang.IllegalArgumentException: Cannot subclass final class feign.httpclient.ApacheHttpClient
	at org.springframework.cglib.proxy.Enhancer.generateClass(Enhancer.java:657)
	at org.springframework.cglib.core.DefaultGeneratorStrategy.generate(DefaultGeneratorStrategy.java:25)
</code></pre><p>这里，又涉及了Spring实现动态代理的两种方式：</p><ul>
<li>JDK动态代理，通过反射实现，只支持对实现接口的类进行代理；</li>
<li>CGLIB动态字节码注入方式，通过继承实现代理，没有这个限制。</li>
</ul><p><strong>Spring Boot 2.x默认使用CGLIB的方式，但通过继承实现代理有个问题是，无法继承final的类。因为，ApacheHttpClient类就是定义为了final</strong>：</p><pre><code>public final class ApacheHttpClient implements Client {
</code></pre><p>为解决这个问题，我们把配置参数proxy-target-class的值修改为false，以切换到使用JDK动态代理的方式：</p><pre><code>spring.aop.proxy-target-class=false
</code></pre><p>修改后执行clientWithUrl接口可以看到，通过within(feign.Client+)方式可以切入feign.Client子类了。以下日志显示了@within和within的两次切入：</p><pre><code>[16:29:55.303] [http-nio-45678-exec-1] [INFO ] [o.g.t.c.spring.demo4.Wrong2Aspect       :16  ] - @within(org.springframework.cloud.openfeign.FeignClient) pjp execution(String org.geekbang.time.commonmistakes.spring.demo4.feign.ClientWithUrl.api()), args:[]
[16:29:55.310] [http-nio-45678-exec-1] [INFO ] [o.g.t.c.spring.demo4.WrongAspect        :15  ] - within(feign.Client+) pjp execution(Response feign.Client.execute(Request,Options)), args:[GET http://localhost:45678/feignaop/server HTTP/1.1


Binary data, feign.Request$Options@387550b0]
</code></pre><p>这下我们就明白了，Spring Cloud使用了自动装配来根据依赖装配组件，组件是否成为Bean决定了AOP是否可以切入，在尝试通过AOP切入Spring Bean的时候要注意。</p><p>加上上一讲的两个案例，我就把IoC和AOP相关的坑点和你说清楚了。除此之外，我们在业务开发时，还有一个绕不开的点是，Spring程序的配置问题。接下来，我们就具体看看吧。</p><h2>Spring程序配置的优先级问题</h2><p>我们知道，通过配置文件application.properties，可以实现Spring Boot应用程序的参数配置。但我们可能不知道的是，Spring程序配置是有优先级的，即当两个不同的配置源包含相同的配置项时，其中一个配置项很可能会被覆盖掉。这，也是为什么我们会遇到些看似诡异的配置失效问题。</p><p>我们来通过一个实际案例，研究下配置源以及配置源的优先级问题。</p><p>对于Spring Boot应用程序，一般我们会通过设置management.server.port参数，来暴露独立的actuator管理端口。这样做更安全，也更方便监控系统统一监控程序是否健康。</p><pre><code>management.server.port=45679
</code></pre><p>有一天程序重新发布后，监控系统显示程序离线。但排查下来发现，程序是正常工作的，只是actuator管理端口的端口号被改了，不是配置文件中定义的45679了。</p><p>后来发现，运维同学在服务器上定义了两个环境变量MANAGEMENT_SERVER_IP和MANAGEMENT_SERVER_PORT，目的是方便监控Agent把监控数据上报到统一的管理服务上：</p><pre><code>MANAGEMENT_SERVER_IP=192.168.0.2
MANAGEMENT_SERVER_PORT=12345
</code></pre><p>问题就是出在这里。MANAGEMENT_SERVER_PORT覆盖了配置文件中的management.server.port，修改了应用程序本身的端口。当然，监控系统也就无法通过老的管理端口访问到应用的health端口了。如下图所示，actuator的端口号变成了12345：</p><p><img src="https://static001.geekbang.org/resource/image/b2/e6/b287b7ad823a39bb604fa69e02c720e6.png" alt=""></p><p>到这里坑还没完，为了方便用户登录，需要在页面上显示默认的管理员用户名，于是开发同学在配置文件中定义了一个user.name属性，并设置为defaultadminname：</p><pre><code>user.name=defaultadminname
</code></pre><p>后来发现，程序读取出来的用户名根本就不是配置文件中定义的。这，又是咋回事？</p><p>带着这个问题，以及之前环境变量覆盖配置文件配置的问题，我们写段代码看看，从Spring中到底能读取到几个management.server.port和user.name配置项。</p><p>要想查询Spring中所有的配置，我们需要以环境Environment接口为入口。接下来，我就与你说说Spring通过环境Environment抽象出的Property和Profile：</p><ul>
<li>针对Property，又抽象出各种PropertySource类代表配置源。一个环境下可能有多个配置源，每个配置源中有诸多配置项。在查询配置信息时，需要按照配置源优先级进行查询。</li>
<li>Profile定义了场景的概念。通常，我们会定义类似dev、test、stage和prod等环境作为不同的Profile，用于按照场景对Bean进行逻辑归属。同时，Profile和配置文件也有关系，每个环境都有独立的配置文件，但我们只会激活某一个环境来生效特定环境的配置文件。</li>
</ul><p><img src="https://static001.geekbang.org/resource/image/2c/c0/2c68da94d31182cad34c965f878196c0.png" alt=""></p><p>接下来，我们重点看看Property的查询过程。</p><p>对于非Web应用，Spring对于Environment接口的实现是StandardEnvironment类。我们通过Spring注入StandardEnvironment后循环getPropertySources获得的PropertySource，来查询所有的PropertySource中key是user.name或management.server.port的属性值；然后遍历getPropertySources方法，获得所有配置源并打印出来：</p><pre><code>@Autowired
private StandardEnvironment env;
@PostConstruct
public void init(){
    Arrays.asList(&quot;user.name&quot;, &quot;management.server.port&quot;).forEach(key -&gt; {
         env.getPropertySources().forEach(propertySource -&gt; {
                    if (propertySource.containsProperty(key)) {
                        log.info(&quot;{} -&gt; {} 实际取值：{}&quot;, propertySource, propertySource.getProperty(key), env.getProperty(key));
                    }
                });
    });

    System.out.println(&quot;配置优先级：&quot;);
    env.getPropertySources().stream().forEach(System.out::println);
}
</code></pre><p>我们研究下输出的日志：</p><pre><code>2020-01-15 16:08:34.054  INFO 40123 --- [           main] o.g.t.c.s.d.CommonMistakesApplication    : ConfigurationPropertySourcesPropertySource {name='configurationProperties'} -&gt; zhuye 实际取值：zhuye
2020-01-15 16:08:34.054  INFO 40123 --- [           main] o.g.t.c.s.d.CommonMistakesApplication    : PropertiesPropertySource {name='systemProperties'} -&gt; zhuye 实际取值：zhuye
2020-01-15 16:08:34.054  INFO 40123 --- [           main] o.g.t.c.s.d.CommonMistakesApplication    : OriginTrackedMapPropertySource {name='applicationConfig: [classpath:/application.properties]'} -&gt; defaultadminname 实际取值：zhuye
2020-01-15 16:08:34.054  INFO 40123 --- [           main] o.g.t.c.s.d.CommonMistakesApplication    : ConfigurationPropertySourcesPropertySource {name='configurationProperties'} -&gt; 12345 实际取值：12345
2020-01-15 16:08:34.054  INFO 40123 --- [           main] o.g.t.c.s.d.CommonMistakesApplication    : OriginAwareSystemEnvironmentPropertySource {name=''} -&gt; 12345 实际取值：12345
2020-01-15 16:08:34.054  INFO 40123 --- [           main] o.g.t.c.s.d.CommonMistakesApplication    : OriginTrackedMapPropertySource {name='applicationConfig: [classpath:/application.properties]'} -&gt; 45679 实际取值：12345
配置优先级：
ConfigurationPropertySourcesPropertySource {name='configurationProperties'}
StubPropertySource {name='servletConfigInitParams'}
ServletContextPropertySource {name='servletContextInitParams'}
PropertiesPropertySource {name='systemProperties'}
OriginAwareSystemEnvironmentPropertySource {name='systemEnvironment'}
RandomValuePropertySource {name='random'}
OriginTrackedMapPropertySource {name='applicationConfig: [classpath:/application.properties]'}
MapPropertySource {name='springCloudClientHostInfo'}
MapPropertySource {name='defaultProperties'}
</code></pre><ul>
<li>有三处定义了user.name：第一个是configurationProperties，值是zhuye；第二个是systemProperties，代表系统配置，值是zhuye；第三个是applicationConfig，也就是我们的配置文件，值是配置文件中定义的defaultadminname。</li>
<li>同样地，也有三处定义了management.server.port：第一个是configurationProperties，值是12345；第二个是systemEnvironment代表系统环境，值是12345；第三个是applicationConfig，也就是我们的配置文件，值是配置文件中定义的45679。</li>
<li>第7到16行的输出显示，Spring中有9个配置源，值得关注是ConfigurationPropertySourcesPropertySource、PropertiesPropertySource、OriginAwareSystemEnvironmentPropertySource和我们的配置文件。</li>
</ul><p>那么，Spring真的是按这个顺序查询配置吗？最前面的configurationProperties，又是什么？为了回答这2个问题，我们需要分析下源码。我先说明下，下面源码分析的逻辑有些复杂，你可以结合着下面的整体流程图来理解：</p><p><img src="https://static001.geekbang.org/resource/image/3e/f9/3e6dc6456f6d1354da58fb260775c0f9.png" alt=""></p><p>Demo中注入的StandardEnvironment，继承的是AbstractEnvironment（图中紫色类）。AbstractEnvironment的源码如下：</p><pre><code>public abstract class AbstractEnvironment implements ConfigurableEnvironment {
	private final MutablePropertySources propertySources = new MutablePropertySources();
	private final ConfigurablePropertyResolver propertyResolver =
			new PropertySourcesPropertyResolver(this.propertySources);

	public String getProperty(String key) {
		return this.propertyResolver.getProperty(key);
	}
}
</code></pre><p>可以看到：</p><ul>
<li>MutablePropertySources类型的字段propertySources，看起来代表了所有配置源；</li>
<li>getProperty方法，通过PropertySourcesPropertyResolver类进行查询配置；</li>
<li>实例化PropertySourcesPropertyResolver的时候，传入了当前的MutablePropertySources。</li>
</ul><p>接下来，我们继续分析MutablePropertySources和PropertySourcesPropertyResolver。先看看MutablePropertySources的源码（图中蓝色类）：</p><pre><code>public class MutablePropertySources implements PropertySources {

	private final List&lt;PropertySource&lt;?&gt;&gt; propertySourceList = new CopyOnWriteArrayList&lt;&gt;();

	public void addFirst(PropertySource&lt;?&gt; propertySource) {
		removeIfPresent(propertySource);
		this.propertySourceList.add(0, propertySource);
	}
	public void addLast(PropertySource&lt;?&gt; propertySource) {
		removeIfPresent(propertySource);
		this.propertySourceList.add(propertySource);
	}
	public void addBefore(String relativePropertySourceName, PropertySource&lt;?&gt; propertySource) {
		...
		int index = assertPresentAndGetIndex(relativePropertySourceName);
		addAtIndex(index, propertySource);
	}
    public void addAfter(String relativePropertySourceName, PropertySource&lt;?&gt; propertySource) {
       ...
       int index = assertPresentAndGetIndex(relativePropertySourceName);
       addAtIndex(index + 1, propertySource);
    }
    private void addAtIndex(int index, PropertySource&lt;?&gt; propertySource) {
       removeIfPresent(propertySource);
       this.propertySourceList.add(index, propertySource);
    }
}
</code></pre><p>可以发现：</p><ul>
<li>propertySourceList字段用来真正保存PropertySource的List，且这个List是一个CopyOnWriteArrayList。</li>
<li>类中定义了addFirst、addLast、addBefore、addAfter等方法，来精确控制PropertySource加入propertySourceList的顺序。这也说明了顺序的重要性。</li>
</ul><p>继续看下PropertySourcesPropertyResolver（图中绿色类）的源码，找到真正查询配置的方法getProperty。</p><p>这里，我们重点看一下第9行代码：遍历的propertySources是PropertySourcesPropertyResolver构造方法传入的，再结合AbstractEnvironment的源码可以发现，这个propertySources正是AbstractEnvironment中的MutablePropertySources对象。遍历时，如果发现配置源中有对应的Key值，则使用这个值。因此，MutablePropertySources中配置源的次序尤为重要。</p><pre><code>public class PropertySourcesPropertyResolver extends AbstractPropertyResolver {
	private final PropertySources propertySources;
	public PropertySourcesPropertyResolver(@Nullable PropertySources propertySources) {
		this.propertySources = propertySources;
	}
	
	protected &lt;T&gt; T getProperty(String key, Class&lt;T&gt; targetValueType, boolean resolveNestedPlaceholders) {
		if (this.propertySources != null) {
			for (PropertySource&lt;?&gt; propertySource : this.propertySources) {
				if (logger.isTraceEnabled()) {
					logger.trace(&quot;Searching for key '&quot; + key + &quot;' in PropertySource '&quot; +
							propertySource.getName() + &quot;'&quot;);
				}
				Object value = propertySource.getProperty(key);
				if (value != null) {
					if (resolveNestedPlaceholders &amp;&amp; value instanceof String) {
						value = resolveNestedPlaceholders((String) value);
					}
					logKeyFound(key, propertySource, value);
					return convertValueIfNecessary(value, targetValueType);
				}
			}
		}
		...
	}
}
</code></pre><p>回到之前的问题，在查询所有配置源的时候，我们注意到处在第一位的是ConfigurationPropertySourcesPropertySource，这是什么呢？</p><p>其实，它不是一个实际存在的配置源，扮演的是一个代理的角色。但通过调试你会发现，我们获取的值竟然是由它提供并且返回的，且没有循环遍历后面的PropertySource：</p><p><img src="https://static001.geekbang.org/resource/image/73/fb/7380c93e743e3fc41d8cc58b77895bfb.png" alt=""></p><p>继续查看ConfigurationPropertySourcesPropertySource（图中红色类）的源码可以发现，getProperty方法其实是通过findConfigurationProperty方法查询配置的。如第25行代码所示，这其实还是在遍历所有的配置源：</p><pre><code>class ConfigurationPropertySourcesPropertySource extends PropertySource&lt;Iterable&lt;ConfigurationPropertySource&gt;&gt;
		implements OriginLookup&lt;String&gt; {

	ConfigurationPropertySourcesPropertySource(String name, Iterable&lt;ConfigurationPropertySource&gt; source) {
		super(name, source);
	}

	@Override
	public Object getProperty(String name) {
		ConfigurationProperty configurationProperty = findConfigurationProperty(name);
		return (configurationProperty != null) ? configurationProperty.getValue() : null;
	}
	private ConfigurationProperty findConfigurationProperty(String name) {
		try {
			return findConfigurationProperty(ConfigurationPropertyName.of(name, true));
		}
		catch (Exception ex) {
			return null;
		}
	}
	private ConfigurationProperty findConfigurationProperty(ConfigurationPropertyName name) {
		if (name == null) {
			return null;
		}
		for (ConfigurationPropertySource configurationPropertySource : getSource()) {
			ConfigurationProperty configurationProperty = configurationPropertySource.getConfigurationProperty(name);
			if (configurationProperty != null) {
				return configurationProperty;
			}
		}
		return null;
	}
}
</code></pre><p>调试可以发现，这个循环遍历（getSource()的结果）的配置源，其实是SpringConfigurationPropertySources（图中黄色类），其中包含的配置源列表就是之前看到的9个配置源，而第一个就是ConfigurationPropertySourcesPropertySource。看到这里，我们的第一感觉是会不会产生死循环，它在遍历的时候怎么排除自己呢？</p><p>同时观察configurationProperty可以看到，这个ConfigurationProperty其实类似代理的角色，实际配置是从系统属性中获得的：</p><p><img src="https://static001.geekbang.org/resource/image/95/0a/9551d5b5acada84262b7ddeae989750a.png" alt=""></p><p>继续查看SpringConfigurationPropertySources可以发现，它返回的迭代器是内部类SourcesIterator，在fetchNext方法获取下一个项时，通过isIgnored方法排除了ConfigurationPropertySourcesPropertySource（源码第38行）：</p><pre><code>class SpringConfigurationPropertySources implements Iterable&lt;ConfigurationPropertySource&gt; {

	private final Iterable&lt;PropertySource&lt;?&gt;&gt; sources;
	private final Map&lt;PropertySource&lt;?&gt;, ConfigurationPropertySource&gt; cache = new ConcurrentReferenceHashMap&lt;&gt;(16,
			ReferenceType.SOFT);

	SpringConfigurationPropertySources(Iterable&lt;PropertySource&lt;?&gt;&gt; sources) {
		Assert.notNull(sources, &quot;Sources must not be null&quot;);
		this.sources = sources;
	}

	@Override
	public Iterator&lt;ConfigurationPropertySource&gt; iterator() {
		return new SourcesIterator(this.sources.iterator(), this::adapt);
	}

	private static class SourcesIterator implements Iterator&lt;ConfigurationPropertySource&gt; {

		@Override
		public boolean hasNext() {
			return fetchNext() != null;
		}

		private ConfigurationPropertySource fetchNext() {
			if (this.next == null) {
				if (this.iterators.isEmpty()) {
					return null;
				}
				if (!this.iterators.peek().hasNext()) {
					this.iterators.pop();
					return fetchNext();
				}
				PropertySource&lt;?&gt; candidate = this.iterators.peek().next();
				if (candidate.getSource() instanceof ConfigurableEnvironment) {
					push((ConfigurableEnvironment) candidate.getSource());
					return fetchNext();
				}
				if (isIgnored(candidate)) {
					return fetchNext();
				}
				this.next = this.adapter.apply(candidate);
			}
			return this.next;
		}


		private void push(ConfigurableEnvironment environment) {
			this.iterators.push(environment.getPropertySources().iterator());
		}


		private boolean isIgnored(PropertySource&lt;?&gt; candidate) {
			return (candidate instanceof StubPropertySource
					|| candidate instanceof ConfigurationPropertySourcesPropertySource);
		}
	}
}
</code></pre><p>我们已经了解了ConfigurationPropertySourcesPropertySource是所有配置源中的第一个，实现了对PropertySourcesPropertyResolver中遍历逻辑的“劫持”，并且知道了其遍历逻辑。最后一个问题是，它如何让自己成为第一个配置源呢？</p><p>再次运用之前我们学到的那个小技巧，来查看实例化ConfigurationPropertySourcesPropertySource的地方：</p><p><img src="https://static001.geekbang.org/resource/image/f4/5d/f43c15a2f491d88a0383023a42cebd5d.png" alt=""></p><p>可以看到，ConfigurationPropertySourcesPropertySource类是由ConfigurationPropertySources的attach方法实例化的。查阅源码可以发现，这个方法的确从环境中获得了原始的MutablePropertySources，把自己加入成为一个元素：</p><pre><code>public final class ConfigurationPropertySources {
	public static void attach(Environment environment) {
		MutablePropertySources sources = ((ConfigurableEnvironment) environment).getPropertySources();
		PropertySource&lt;?&gt; attached = sources.get(ATTACHED_PROPERTY_SOURCE_NAME);
		if (attached == null) {
			sources.addFirst(new ConfigurationPropertySourcesPropertySource(ATTACHED_PROPERTY_SOURCE_NAME,
					new SpringConfigurationPropertySources(sources)));
		}
	}
}
</code></pre><p>而这个attach方法，是Spring应用程序启动时准备环境的时候调用的。在SpringApplication的run方法中调用了prepareEnvironment方法，然后又调用了ConfigurationPropertySources.attach方法：</p><pre><code>public class SpringApplication {

public ConfigurableApplicationContext run(String... args) {
		...
		try {
			ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
			ConfigurableEnvironment environment = prepareEnvironment(listeners, applicationArguments);
			...
	}
	private ConfigurableEnvironment prepareEnvironment(SpringApplicationRunListeners listeners,
			ApplicationArguments applicationArguments) {
		...
		ConfigurationPropertySources.attach(environment);
		...
    }
}
</code></pre><p>看到这里你是否彻底理清楚Spring劫持PropertySourcesPropertyResolver的实现方式，以及配置源有优先级的原因了呢？如果你想知道Spring各种预定义的配置源的优先级，可以参考<a href="https://docs.spring.io/spring-boot/docs/current/reference/html/spring-boot-features.html#boot-features-external-config">官方文档</a>。</p><h2>重点回顾</h2><p>今天，我用两个业务开发中的实际案例，带你进一步学习了Spring的AOP和配置优先级这两大知识点。现在，你应该也感受到Spring实现的复杂度了。</p><p>对于AOP切Feign的案例，我们在实现功能时走了一些弯路。Spring Cloud会使用Spring Boot的特性，根据当前引入包的情况做各种自动装配。如果我们要扩展Spring的组件，那么只有清晰了解Spring自动装配的运作方式，才能鉴别运行时对象在Spring容器中的情况，不能想当然认为代码中能看到的所有Spring的类都是Bean。</p><p>对于配置优先级的案例，分析配置源优先级时，如果我们以为看到PropertySourcesPropertyResolver就看到了真相，后续进行扩展开发时就可能会踩坑。我们一定要注意，<strong>分析Spring源码时，你看到的表象不一定是实际运行时的情况，还需要借助日志或调试工具来理清整个过程</strong>。如果没有调试工具，你可以借助<a href="https://time.geekbang.org/column/article/216830">第11讲</a>用到的Arthas，来分析代码调用路径。</p><p>今天用到的代码，我都放在了GitHub上，你可以点击<a href="https://github.com/JosephZhu1983/java-common-mistakes">这个链接</a>查看。</p><h2>思考与讨论</h2><ol>
<li>除了我们这两讲用到execution、within、@within、@annotation四个指示器外，Spring AOP还支持this、target、args、@target、@args。你能说说后面五种指示器的作用吗？</li>
<li>Spring的Environment中的PropertySources属性可以包含多个PropertySource，越往前优先级越高。那，我们能否利用这个特点实现配置文件中属性值的自动赋值呢？比如，我们可以定义%%MYSQL.URL%%、%%MYSQL.USERNAME%%和%%MYSQL.PASSWORD%%，分别代表数据库连接字符串、用户名和密码。在配置数据源时，我们只要设置其值为占位符，框架就可以自动根据当前应用程序名application.name，统一把占位符替换为真实的数据库信息。这样，生产的数据库信息就不需要放在配置文件中了，会更安全。</li>
</ol><p>关于Spring Core、Spring Boot和Spring Cloud，你还遇到过其他坑吗？我是朱晔，欢迎在评论区与我留言分享你的想法，也欢迎你把今天的内容分享给你的朋友或同事，一起交流。</p>