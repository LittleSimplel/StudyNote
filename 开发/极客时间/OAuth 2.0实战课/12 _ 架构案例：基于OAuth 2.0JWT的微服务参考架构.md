<audio title="12 _ 架构案例：基于OAuth 2.0JWT的微服务参考架构" src="https://static001.geekbang.org/resource/audio/dc/e4/dc057e8d3e588b410eee57fb9aa9c5e4.mp3" controls="controls"></audio> 
<blockquote>
<p>你好，我是王新栋。</p>
</blockquote><blockquote>
<p>在前面几讲，我们一起学习了OAuth 2.0 在开放环境中的使用过程。那么OAuth 2.0 不仅仅可以用在开放的场景中，它可以应用到我们任何需要授权/鉴权的地方，包括微服务。</p>
</blockquote><blockquote>
<p>因此今天，我特别邀请了我的朋友杨波，来和你分享一个基于OAuth 2.0/JWT的微服务参考架构。杨波，曾先后担任过携程框架部的研发总监和拍拍贷基础架构部的研发总监，在微服务和OAuth 2.0有非常丰富的实践经验。</p>
</blockquote><blockquote>
<p>其中，在携程工作期间，他负责过携程的API网关产品的研发工作，包括它和携程的令牌服务的集成；在拍拍贷工作期间，他负责过拍拍贷的令牌服务的研发和运维工作。这两家公司的令牌服务和OAuth 2.0类似，但要更简单些。</p>
</blockquote><blockquote>
<p>接下来，我们就开始学习杨波老师给我们带来的内容吧。</p>
</blockquote><p>你好，我是杨波。</p><p>从单体到微服务架构的演进，是当前企业数字化转型的一大趋势。<a href="https://oauth.net/2/">OAuth 2.0</a>是当前业界标准的授权协议，它的核心是若干个针对不同场景的令牌颁发和管理流程；而<a href="https://jwt.io/">JWT</a>是一种轻量级、自包含的令牌，可用于在微服务间安全地传递用户信息。</p><p>据我目前了解到的情况，虽然有不少企业已经部分或全部转型到微服务架构，但是在授权认证机制方面，它们一般都是定制自研的，比方说携程和拍拍贷的令牌服务。之所以定制自研，主要原因在于标准的OAuth 2.0协议相对比较复杂，门槛也比较高。定制自研固然可以暂时解决企业的问题，但是不具备通用性，也可能有很多潜在的安全风险。</p><!-- [[[read_end]]] --><p>那么，到底应该如何将行业标准的OAuth 2.0/JWT和微服务集成起来呢，又有没有可落地的参考架构呢？</p><p>针对这个问题，今天我就和你分享一种可落地的参考架构。不过，我要提前说明的是，这个架构的思想源于<a href="https://www.kaper.com/cloud/micro-services-architecture-with-oauth2-and-jwt-part-1-overview/">MICRO-SERVICES ARCHITECTURE WITH OAUTH2 AND JWT – PART 1 – OVERVIEW</a>这篇文章。根据原作者Thijs的描述，他提出的架构已经在企业落地架构了。如果你还想获得关于原架构的更多细节，建议进一步参考“<a href="https://dzone.com/articles/what-is-pkce">What is PKCE？</a>”这篇文章。</p><p>我认为，Thijs给出的架构确实具有可落地性和参考价值，但是他的架构里面对某些微服务层次的命名，例如BFF和Facade层，和目前主流的微服务架构不符，还有他的架构应该是手绘，不够清晰，也不容易理解。为此，我专门用今天这一讲，来改进Thijs给出的架构，并补充针对不同场景的流程。</p><p>为了方便理解，在接下来的讲述中，我会假定有这样一家叫ACME的新零售公司，它已经实现了数字化转型，微服务电商平台是支持业务运作的核心基础设施。</p><p>在业务架构方面，ACME有近千家线下门店，这些门店通过POS系统和电商平台对接。公司还有一些物流发货中心，拣选（Order Picking）系统也要和电商平台对接。另外，公司还有很多送货司机，通过App和电商平台对接。当然，ACME还有一些电商网站，做线上营销和销售，这些网站是电商平台的主要流量源。</p><p>虽然支持ACME公司业务运作的技术平台很复杂，但是它的核心可以用一个简化的微服务架构图来描述：</p><p><img src="https://static001.geekbang.org/resource/image/22/ff/228199yya6051f1f62f23547a88be4ff.jpg" alt=""></p><p>可以看出，这个微服务架构是运行在Kubernetes集群中的。当然了，这个架构实际上并不一定需要Kubernetes环境，用传统数据中心也可以。另外，它的整体认证授权架构是基于OAuth 2.0/JWT实现的。</p><p>接下来，我按这个微服务架构的分层方式，依次和你分析下它的每一层，以及应用认证/授权和服务调用的相关流程。这样，你不仅可以理解一个典型的微服务架构该如何分层，还可以弄清楚OAuth 2.0/JWT该如何与微服务进行集成。</p><h2>微服务分层架构</h2><p>ACME公司的微服务架构，大致可以分为Nginx反向代理层、Web应用层、Gateway网关层、BEF层和领域服务层，还包括一个IDP服务。总体上讲，这是一种目前主流的微服务架构分层方式，每一层职责单一、清晰。</p><p>接下来，我们具体看看每一层的主要功能。</p><h3>Nginx反向代理层</h3><p>首先，Nginx集群是整个平台的流量入口。Nginx是7层HTTP反向代理，主要功能是实现反向路由，也就是将外部流量根据HOST主机头或者PATH，路由到不同的后端，比方说路由到Web应用，或者直接到网关Gateway。</p><p>在Kubernetes体系中，Nginx是和Ingress Controller（入口控制器）配合工作的（总称为Nginx Ingress），Ingress Controller支持通过Ingress Rules，配置Nginx的路由规则。</p><h3>Web应用层</h3><p>这一层主要是一些Web应用，html/css/js等资源就住在这一层。</p><p>Web服务层通常采用传统的Web MVC + 模版引擎方式处理，可以实现服务器端渲染，也可以采用单页SPA方式。这一层主要由公司的前端团队负责，通常会使用Node.js技术栈来实现，也可以采用Spring MVC技术栈实现。具体怎么实现，要看公司的前端团队更擅长哪种技术。当这一层需要后台数据时，可以通过网关调用后台服务获取数据。</p><h3>Gateway网关层</h3><p>这一层是微服务调用流量的入口。网关的主要职责是反向路由，也就是将前端请求根据HOST主机头、或者PATH、或者查询参数，路由到后端目标微服务（比如，图中的IDP/BFF或者直接到领域服务)。</p><p>另外，网关还承担两个重要的安全职责：</p><ul>
<li>一个是令牌的校验和转换，将前端传递过来的OAuth 2.0访问令牌，通过调用IDP进行校验，并转换为包含用户和权限信息的JWT令牌，再将JWT令牌向后台微服务传递。</li>
<li>另外一个是权限校验，网关的路由表可以和OAuth 2.0的Scope进行关联。这样，网关根据请求令牌中的权限范围Scope，就可以判断请求是否具有调用后台服务的权限。</li>
</ul><p>关于安全相关的场景和流程，我会在下一章节做进一步解释。</p><p>另外，网关还需承担集中式限流、日志监控，以及支持CORS等功能。</p><p>对于网关层的技术选型，当前主流的API网关产品，像Netflix开源的Zuul、Spring Cloud Gateway等，都可以考虑。</p><h3>IDP服务</h3><p>IDP是Identity Provider的简称，主要负责OAuth 2.0授权协议处理，OAuth 2.0和JWT令牌颁发和管理，以及用户认证等功能。IDP使用后台的Login-Service进行用户认证。</p><p>对于IDP的技术选型，当前主流的Spring Security OAuth，或者RedHat开源的KeyCloak，都可以考虑。其中，Spring Security OAuth是一个OAuth 2.0的开发框架，适合企业定制。KeyCloak则是一个开箱即用的OAuth 2.0/OIDC产品。</p><h3>BFF层</h3><p>BFF是Backend for Frontend的简称，主要实现对后台领域服务的聚合（Aggregation，有点类似数据库的Join）功能，同时为不同的前端体验（PC/Mobile/开放平台等）提供更友好的API和数据格式。</p><p>BFF中可以包含一些业务逻辑，甚至还可以有自己的数据库存储。通常，BFF要调用两个或两个以上的领域服务，甚至还可能调用其它的BFF（当然一般并不建议这样调用，因为这样会让调用关系变得错综复杂，无法理解）。</p><p>如果BFF需要获取调用用户或者OAuth 2.0 Scope相关信息，它可以从传递过来的JWT令牌中直接获取。</p><p>BFF服务可以用Node.js开发，也可以用Java/Spring等框架开发。</p><h3>领域服务层</h3><p>领域服务层在整个微服务架构的底层。这些服务包含业务逻辑，通常有自己独立的数据库存储，还可以根据需要调用外部的服务。</p><p>根据微服务分层原则，领域服务禁止调用其它的领域服务，更不允许反向调用BFF服务。这样做是为了保持微服务职责单一（Single Responsibility）和有界上下文（Bounded Context），避免复杂的领域依赖。领域服务是独立的开发、测试和发布单位。在电商领域，常见的领域服务有用户服务、商品服务、订单服务和支付服务等。</p><p>和BFF一样，如果领域服务需要获取调用用户或者OAuth 2.0 Scope相关信息，它可以从传递过来的JWT令牌中直接获取。</p><p>可以看到，领域服务和BFF服务都是无状态的，它们本身并不存储用户状态，而是通过传递过来的JWT数据获取用户信息。所以在整个架构中，微服务都是无状态、可以按需水平扩展的，状态要么存在用户端（浏览器或者手机App中），要么存在集中的数据库中。</p><h2>OAuth 2.0/JWT如何与微服务进行集成？</h2><p>以上，就是ACME公司的整个微服务架构的层次了。这个分层架构，对于大部分的互联网业务系统场景都适用。因此，如果你是一家企业的架构师，需要设计一套微服务架构，完全可以参考它来设计。接下来，我再演示几个典型的应用认证场景，以及相应的服务调用流程，来帮助你理解OAuth 2.0/JWT是如何和微服务进行集成的。</p><h3>场景1：第一方Web应用+资源拥有者凭据模式</h3><p>这个场景是用户访问ACME公司自己的电商网站，假设这个电商网站是用Spring MVC开发的。考虑到这是一个第一方场景（也就是公司自己开发的网站应用），我们可以选OAuth 2.0的资源拥有者凭据许可（Resource Owner Password Credentials Grant），也可以选更安全的授权码许可（Authorization Code Grant）。因为这里没有第三方的概念，所以我们就选相对简单的资源拥有者凭据许可。</p><p>下面是一个认证授权流程样例。注意，这个只是突出了关键步骤，实际生产的话，还有很多需要完善和优化的地方。另外，为描述简单，这里假定一个成功流程。</p><p><img src="https://static001.geekbang.org/resource/image/b6/bd/b658befe1da937fa3685b55522487dbd.jpg" alt=""></p><p>在上面的图中，用户对应OAuth 2.0中的资源拥有者，ACME IDP对应OAuth 2.0中的授权服务。另外，前面架构图中的后台微服务（包括BFF和基础领域服务），对应OAuth 2.0中的受保护资源。</p><p>下面是流程说明：</p><ol>
<li>用户通过浏览器访问ACME公司的电商网站，点击登录链接。</li>
<li>Web应用返回登录界面（这个登录页可以是网站自己定制开发）。</li>
<li>用户输入用户名、密码进行认证。</li>
<li>Web应用将用户名、密码，通过网关转发到IDP的令牌获取端点（POST /oauth2/token，grant_type=password）。</li>
<li>IDP通过Login Service对用户进行认证。</li>
<li>IDP认证通过，返回有效访问令牌（根据需要也可以返回刷新令牌）。</li>
<li>Web应用接收到访问令牌，创建用户Session，并将OAuth 2.0令牌保存其中，然后返回登录成功到用户端。</li>
<li>用户浏览器中记录Session Cookie，登录成功。</li>
</ol><p>那接下来，我们再来看看认证授权之后的服务调用流程。同样，这里也只是突出了关键步骤，并假定是一个成功流程。</p><p><img src="https://static001.geekbang.org/resource/image/c8/4a/c88e46dd26deb76d6yy8f42f83066f4a.jpg" alt=""></p><ol>
<li>用户登录后，在网站上点击查看自己的购物历史记录。</li>
<li>Web应用通过网关调用后台API（查询用户的购物历史记录），请求HTTP header中带上OAuth 2.0令牌（来自用户Session）。</li>
<li>网关截取OAuth 2.0令牌，去IDP进行校验。</li>
<li>IDP校验令牌通过，再通过令牌查询用户和Scope信息，构建JWT令牌，返回。</li>
<li>网关获得JWT令牌，校验Scope是否有权限调用API，如果有就转发到后台API进行调用。</li>
<li>后台BFF（或者领域服务）通过传递过来的JWT获取用户信息，根据用户ID查询购物历史记录，返回。</li>
<li>Web应用获得用户的购物历史数据，可以根据需要缓存在Session中，再返回用户端。</li>
<li>购物历史数据返回到用户浏览器端。</li>
</ol><p>注意，这个服务调用流程，也可以应用在其他场景中，比如我们接下来要学习的“第一方移动应用+授权码许可模式”和“第三方Web应用+授权码许可模式”。基本上只要你理解了这个流程原理，就可以根据实际场景灵活套用。</p><h3>场景2：第一方移动应用+授权码许可模式</h3><p>第二个场景是用户通过手机访问ACME公司自己的电商App。这是第一方的原生应用（Native App）场景，通常考虑选用OAuth 2.0的用户名密码模式，但是并不安全（参考<a href="https://www.kaper.com/cloud/micro-services-architecture-with-oauth2-and-jwt-part-3-idp/">MICRO-SERVICES ARCHITECTURE WITH OAUTH2 AND JWT – PART 3 – IDP</a>的Security Consideration部分），所以业界建议采用授权码模式，而且是要支持<a href="https://dzone.com/articles/what-is-pkce">PKCE</a>扩展的授权码模式。</p><p>那接下来，我们来看看这个认证授权的流程。同样，这里只是突出了关键步骤，并假定是一个成功流程。</p><p><img src="https://static001.geekbang.org/resource/image/44/93/443dab973274d8d13c76b2ef4cd1d393.jpg" alt=""></p><ol>
<li>用户访问电商App，点击登录。</li>
<li>App生成PKCE相关的code verifier + challenge。</li>
<li>App以内嵌方式启动手机浏览器，访问IDP的统一认证页(GET /authorize)，请求带上PKCE的code challenge相关参数。</li>
<li>IDP返回统一认证页。</li>
<li>用户认证和授权。</li>
<li>IDP通过Login Service对用户进行认证。</li>
<li>IDP返回授权码到App浏览器。</li>
<li>App截取浏览器带回的授权码，将授权码+PKCE code verifer，通过网关转发到IDP的令牌获取端点（POST /oauth2/token, grant_type=authorization-code）。</li>
<li>IDP校验PKCE和授权码，校验通过则返回有效访问令牌。</li>
<li>App获取令牌，本地存储，登录成功。</li>
</ol><p>之后，App如果需要和后台交互，可直接通过网关调用后台微服务，请求HTTP header中带上OAuth 2.0访问令牌即可。后续的服务调用流程，和“第一方应用+资源拥有者凭据模式”类似。</p><h3>场景3：第三方Web应用+授权码模式</h3><p>第三个场景是某第三方合作厂商开发了一个Web网站，要访问ACME公司的电商开放平台API。这是一个第三方Web应用场景，通常选用OAuth 2.0的授权码许可模式。</p><p>那接下来，我们来看看这个认证授权的流程。同样，这里只是突出了关键步骤，并假设是一个成功流程。</p><p><img src="https://static001.geekbang.org/resource/image/02/57/02affbdf32f005af65454f3acc4cd957.jpg" alt=""></p><ol>
<li>
<p>用户访问这个第三方Web应用，点击登录链接。</p>
</li>
<li>
<p>Web应用后台向ACME公司的IDP服务发送申请授权码请求（GET /authorize）。</p>
</li>
<li>
<p>用户被重定向到ACME公司的IDP统一登录页面。</p>
</li>
<li>
<p>用户进行认证和授权。</p>
</li>
<li>
<p>IDP通过Login Service对用户进行认证。</p>
</li>
<li>
<p>认证和授权通过，IDP返回授权码。</p>
</li>
<li>
<p>Web应用获得授权码，再向IDP服务的令牌获取端点发起请求（POST /oauth2/token, grant_type=authorization-code）。</p>
</li>
<li>
<p>IDP校验授权码，校验通过则返回有效OAuth 2.0令牌（根据需要也可以返回刷新令牌）。</p>
</li>
<li>
<p>Web应用创建用户Session，将OAuth 2.0令牌保存在Session中，然后返回登录成功到用户端。</p>
</li>
<li>
<p>用户浏览器中记录Session Cookie，登录成功。</p>
</li>
</ol><p>之后，第三方Web应用如果需要和ACME电商平台交互，可直接通过网关调用微服务，请求HTTP header中带上OAuth 2.0访问令牌即可。后续的服务调用流程，和前面的“第一方应用+资源拥有者凭据模式”类似。</p><h3>额外说明</h3><p>除了上面的三个主要场景和流程，我还要和你分享6点。这6点是对上面基本流程的补充，也是企业级的OAuth 2.0应用要额外考虑的。</p><p><strong>第一点是，IDP的API要支持从OAuth 2.0访问令牌到JWT令牌的互转</strong>。今天我们提到的集成架构采用OAuth 2.0 访问令牌 + JWT令牌的混合模式，中间需要实现OAuth 2.0访问令牌到JWT令牌的互转。这个互转API并非OAuth 2.0的标准，有些IDP产品（比方Spring Security OAuth）可能并不支持，因此需要用户定制扩展。</p><p><strong>第二点是，关于单页SPA应用场景</strong>。关于单页SPA应用场景，简单做法是采用隐式许可，但是这个模式是OAuth 2.0中比较不安全的，所以一般不建议采用。对于纯单页SPA应用，业界推荐的做法是：</p><ul>
<li>如果浏览器支持Web Crypto for PKCE，则可以考虑使用类似“第一方移动应用”场景下的授权码许可+PKCE扩展流程；</li>
<li>否则，考虑SPA+传统Web混合（hybrid）模式，前端页面可以住在客户浏览器端中，但登录认证还是由后台Web站点配合实现，走类似“第一方Web应用”场景的资源拥有者凭据模式，或者“第三方Web应用”场景下的授权码许可模式。</li>
</ul><p><strong>第三点是，关于SSO单点登录场景</strong>。为了简化描述，上面的流程没有考虑SSO单点登录场景。如果要支持Web SSO，那么各种应用场景都必须通过浏览器+IDP登录页集中登录，并且IDP要支持Session，用于维护登录态。如果IDP以集群方式部署的话，还要考虑粘性Sticky Session或者集中式Session。</p><p>这样，当用户通过一个Web应用登录后，后续如果再用其它Web应用登录的话，只要IDP上的Session还存在，那么这个登录就可以自动完成，相当于单点登录。</p><p>当然，如果要支持SSO，IDP的Session Cookie要种在Web应用的根域上，也就是说不同Web应用的根域必须相同，否则会有跨域问题。</p><p><strong>第四点是关于IDP和网关的部署方式</strong>。前面的几张架构图中，IDP虽然躲在网关后面，但实际上IDP可以直接通过Nginx对外暴露，不经过网关。或者，IDP的登录授权页面，可以通过Nginx直接暴露，API接口则走网关。</p><p><strong>第五点是关于刷新令牌</strong>。为了简化描述，上面的流程没有详细说明刷新令牌的集成方式。企业根据场景需要，可以启用刷新令牌，来延长用户的登录时间，具体的集成方式需要考虑安全性的需求。</p><p><strong>第六点是关于Web Session</strong>。为了简化描述，在上面的流程中，Web应用登录成功后假设启用Web Session，也就是服务器端Session。在实际场景中，Web Session并非唯一选择，也可以采用简单的客户端Session方式，也称无状态Session，也就是在客户端浏览器Cookie中保存OAuth 2.0访问令牌。</p><h2>小结</h2><p>好了，以上就是今天的主要内容了。今天，我和你分享了如何将行业标准的OAuth 2.0/JWT和微服务集成起来，你需要记住以下四点。</p><p>第一，目前主流的微服务架构大致可以分为5层，分别是：Nginx流量接入层-&gt;Web应用层-&gt;API网关层-&gt;BFF聚合层-&gt;领域服务层。这个架构可以住在云原生的Kubernetes环境中，也可以住在传统数据中心里头。</p><p>第二，API网关是微服务调用的入口，承担重要的安全认证和鉴权功能。主要的安全操作包括：一，通过IDP校验OAuth 2.0访问令牌，并获取带用户和权限信息的JWT令牌；二，基于OAuth 2.0的Scope对API调用进行鉴权。</p><p>第三，在微服务架构体系下，通常需要一个集中的IDP服务，它相当于一个Authentication &amp; Authorization as a Service角色，负责令牌颁发/校验/管理，还有用户认证。</p><p>第四，在今天这一讲提出的架构中，Web应用层（网关之前）的安全机制主要基于OAuth 2.0访问令牌实现（它是一种<strong>透明令牌</strong>或者称<strong>引用令牌</strong>），微服务层（网关之后）的安全机制主要基于JWT令牌实现（它是一种<strong>不透明</strong>的<strong>自包含令牌</strong>）。网关层在中间实现两种令牌的转换。这是一种OAuth 2.0访问令牌+JWT令牌的混合模式。</p><p>之所以这样设计，是因为Web层靠近用户端，如果采用JWT令牌，会暴露用户信息，有一定的安全风险，所以采用OAuth 2.0访问令牌，它是一个无意义随机字符串。而在网关之后，安全风险相对低，同时很多服务需要用户信息，所以采用自包含用户信息的JWT令牌更合适。</p><p>当然，如果企业内网没有特别的安全考量，也可以直接传递完全透明的用户信息（例如使用JSON格式）。</p><h2>思考题</h2><ol>
<li>除了今天我们讲到的OAuth 2.0访问令牌+JWT令牌的混合模式，实践中也可以全程采用OAuth 2.0访问令牌，或者全程采用JWT令牌。对比混合模式，如果全程采用OAuth 2.0访问令牌，或者全程采用JWT令牌，你觉得有哪些利弊呢？</li>
<li>你可以说说自己对基于传统Web应用的认证授权机制的理解吗？并对比今天讲到的现代微服务的认证授权机制，你可以说说它们之间的本质差异和相似点吗？</li>
</ol><p>欢迎你在留言区分享你的观点，也欢迎你把今天的内容分享给其他朋友，我们一起交流。</p>