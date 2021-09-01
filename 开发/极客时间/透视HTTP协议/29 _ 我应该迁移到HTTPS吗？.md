<audio title="29 _ 我应该迁移到HTTPS吗？" src="https://static001.geekbang.org/resource/audio/00/fe/0066de60d6234eee65329be1555eb2fe.mp3" controls="controls"></audio> 
<p>今天是“安全篇”的最后一讲，我们已经学完了HTTPS、TLS相关的大部分知识。不过，或许你心里还会有一些困惑：</p><p>“HTTPS这么复杂，我是否应该迁移到HTTPS呢？它能带来哪些好处呢？具体又应该怎么实施迁移呢？”</p><p>这些问题不单是你，也是其他很多人，还有当初的我的真实想法，所以今天我就来跟你聊聊这方面的事情。</p><h2>迁移的必要性</h2><p>如果你做移动应用开发的话，那么就一定知道，Apple、Android、某信等开发平台在2017年就相继发出通知，要求所有的应用必须使用HTTPS连接，禁止不安全的HTTP。</p><p>在台式机上，主流的浏览器Chrome、Firefox等也早就开始“强推”HTTPS，把HTTP站点打上“不安全”的标签，给用户以“心理压力”。</p><p>Google等搜索巨头还利用自身的“话语权”优势，降低HTTP站点的排名，而给HTTPS更大的权重，力图让网民只访问到HTTPS网站。</p><p>这些手段都逐渐“挤压”了纯明文HTTP的生存空间，<span class="orange">“迁移到HTTPS”已经不是“要不要做”的问题，而是“要怎么做”的问题了</span>。HTTPS的大潮无法阻挡，如果还是死守着HTTP，那么无疑会被冲刷到互联网的角落里。</p><p>目前国内外的许多知名大站都已经实现了“全站HTTPS”，打开常用的某宝、某东、某浪，都可以在浏览器的地址栏里看到“小锁头”，如果你正在维护的网站还没有实施HTTPS，那可要抓点紧了。</p><!-- [[[read_end]]] --><h2>迁移的顾虑</h2><p>据我观察，阻碍HTTPS实施的因素还有一些这样那样的顾虑，我总结出了三个比较流行的观点：“<span class="orange">慢、贵、难</span>”。</p><p>所谓“<span class="orange">慢</span>”，是指惯性思维，拿以前的数据来评估HTTPS的性能，认为HTTPS会增加服务器的成本，增加客户端的时延，影响用户体验。</p><p>其实现在服务器和客户端的运算能力都已经有了很大的提升，性能方面完全没有担心的必要，而且还可以应用很多的优化解决方案（参见<a href="https://time.geekbang.org/column/article/111287">第28讲</a>）。根据Google等公司的评估，在经过适当优化之后，HTTPS的额外CPU成本小于1%，额外的网络成本小于2%，可以说是与无加密的HTTP相差无几。</p><p>所谓“<span class="orange">贵</span>”，主要是指证书申请和维护的成本太高，网站难以承担。</p><p>这也属于惯性思维，在早几年的确是个问题，向CA申请证书的过程不仅麻烦，而且价格昂贵，每年要交几千甚至几万元。</p><p>但现在就不一样了，为了推广HTTPS，很多云服务厂商都提供了一键申请、价格低廉的证书，而且还出现了专门颁发免费证书的CA，其中最著名的就是“<strong>Let’s Encrypt</strong>”。</p><p>所谓的“<span class="orange">难</span>”，是指HTTPS涉及的知识点太多、太复杂，有一定的技术门槛，不能很快上手。</p><p>这第三个顾虑比较现实，HTTPS背后关联到了密码学、TLS、PKI等许多领域，不是短短几周、几个月就能够精通的。但实施HTTPS也并不需要把这些完全掌握，只要抓住少数几个要点就好，下面我就来帮你逐个解决一些关键的“难点”。</p><h2>申请证书</h2><p>要把网站从HTTP切换到HTTPS，首先要做的就是为网站申请一张证书。</p><p>大型网站出于信誉、公司形象的考虑，通常会选择向传统的CA申请证书，例如DigiCert、GlobalSign，而中小型网站完全可以选择使用“Let’s Encrypt”这样的免费证书，效果也完全不输于那些收费的证书。</p><p>“<strong>Let’s Encrypt</strong>”一直在推动证书的自动化部署，为此还实现了专门的ACME协议（RFC8555）。有很多的客户端软件可以完成申请、验证、下载、更新的“一条龙”操作，比如Certbot、acme.sh等等，都可以在“Let’s Encrypt”网站上找到，用法很简单，相关的文档也很详细，几分钟就能完成申请，所以我在这里就不细说了。</p><p>不过我必须提醒你几个注意事项。</p><p>第一，申请证书时应当同时申请RSA和ECDSA两种证书，在Nginx里配置成双证书验证，这样服务器可以自动选择快速的椭圆曲线证书，同时也兼容只支持RSA的客户端。</p><p>第二，如果申请RSA证书，私钥至少要2048位，摘要算法应该选用SHA-2，例如SHA256、SHA384等。</p><p>第三，出于安全的考虑，“Let’s Encrypt”证书的有效期很短，只有90天，时间一到就会过期失效，所以必须要定期更新。你可以在crontab里加个每周或每月任务，发送更新请求，不过很多ACME客户端会自动添加这样的定期任务，完全不用你操心。</p><h2>配置HTTPS</h2><p>搞定了证书，接下来就是配置Web服务器，在443端口上开启HTTPS服务了。</p><p>这在Nginx上非常简单，只要在“listen”指令后面加上参数“ssl”，再配上刚才的证书文件就可以实现最基本的HTTPS。</p><pre><code>listen                443 ssl;

ssl_certificate       xxx_rsa.crt;  #rsa2048 cert
ssl_certificate_key   xxx_rsa.key;  #rsa2048 private key

ssl_certificate       xxx_ecc.crt;  #ecdsa cert
ssl_certificate_key   xxx_ecc.key;  #ecdsa private ke
</code></pre><p>为了提高HTTPS的安全系数和性能，你还可以强制Nginx只支持TLS1.2以上的协议，打开“Session Ticket”会话复用：</p><pre><code>ssl_protocols               TLSv1.2 TLSv1.3;

ssl_session_timeout         5m;
ssl_session_tickets         on;
ssl_session_ticket_key      ticket.key;
</code></pre><p>密码套件的选择方面，我给你的建议是以服务器的套件优先。这样可以避免恶意客户端故意选择较弱的套件、降低安全等级，然后密码套件向TLS1.3“看齐”，只使用ECDHE、AES和ChaCha20，支持“False Start”。</p><pre><code>ssl_prefer_server_ciphers   on;


ssl_ciphers   ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-CHACHA20-POLY1305:ECDHE+AES128:!MD5:!SHA1;
</code></pre><p>如果你的服务器上使用了OpenSSL的分支BorringSSL，那么还可以使用一个特殊的“等价密码组”（Equal preference cipher groups）特性，它可以让服务器配置一组“等价”的密码套件，在这些套件里允许客户端优先选择，比如这么配置：</p><pre><code>ssl_ciphers 
[ECDHE-ECDSA-AES128-GCM-SHA256|ECDHE-ECDSA-CHACHA20-POLY1305];
</code></pre><p>如果客户端硬件没有AES优化，服务器就会顺着客户端的意思，优先选择与AES“等价”的ChaCha20算法，让客户端能够快一点。</p><p>全部配置完成后，你可以访问“<a href="https://www.ssllabs.com/">SSLLabs</a>”网站，测试网站的安全程度，它会模拟多种客户端发起测试，打出一个综合的评分。</p><p>下图就是GitHub网站的评分结果：</p><p><img src="https://static001.geekbang.org/resource/image/a6/1b/a662d410dfdaa8ab44b36cbb68ab8d1b.png" alt=""></p><h2>服务器名称指示</h2><p>配置HTTPS服务时还有一个“虚拟主机”的问题需要解决。</p><p>在HTTP协议里，多个域名可以同时在一个IP地址上运行，这就是“虚拟主机”，Web服务器会使用请求头里的Host字段（参见<a href="https://time.geekbang.org/column/article/100513">第9讲</a>）来选择。</p><p>但在HTTPS里，因为请求头只有在TLS握手之后才能发送，在握手时就必须选择“虚拟主机”对应的证书，TLS无法得知域名的信息，就只能用IP地址来区分。所以，最早的时候每个HTTPS域名必须使用独立的IP地址，非常不方便。</p><p>那么怎么解决这个问题呢？</p><p>这还是得用到TLS的“扩展”，给协议加个<strong>SNI</strong>（Server Name Indication）的“补充条款”。它的作用和Host字段差不多，客户端会在“Client Hello”时带上域名信息，这样服务器就可以根据名字而不是IP地址来选择证书。</p><pre><code>Extension: server_name (len=19)
    Server Name Indication extension
        Server Name Type: host_name (0)
        Server Name: www.chrono.com
</code></pre><p>Nginx很早就基于SNI特性支持了HTTPS的虚拟主机，但在OpenResty里可还以编写Lua脚本，利用Redis、MySQL等数据库更灵活快速地加载证书。</p><h2>重定向跳转</h2><p>现在有了HTTPS服务，但原来的HTTP站点也不能马上弃用，还是会有很多网民习惯在地址栏里直接敲域名（或者是旧的书签、超链接），默认使用HTTP协议访问。</p><p>所以，我们就需要用到第18讲里的“重定向跳转”技术了，把不安全的HTTP网址用301或302“重定向”到新的HTTPS网站，这在Nginx里也很容易做到，使用“return”或“rewrite”都可以。</p><pre><code>return 301 https://$host$request_uri;             #永久重定向
rewrite ^  https://$host$request_uri permanent;   #永久重定向
</code></pre><p>但这种方式有两个问题。一个是重定向增加了网络成本，多出了一次请求；另一个是存在安全隐患，重定向的响应可能会被“中间人”窜改，实现“会话劫持”，跳转到恶意网站。</p><p>不过有一种叫“<strong>HSTS</strong>”（HTTP严格传输安全，HTTP Strict Transport Security）的技术可以消除这种安全隐患。HTTPS服务器需要在发出的响应头里添加一个“<strong>Strict-Transport-Security</strong>”的字段，再设定一个有效期，例如：</p><pre><code>Strict-Transport-Security: max-age=15768000; includeSubDomains
</code></pre><p>这相当于告诉浏览器：我这个网站必须严格使用HTTPS协议，在半年之内（182.5天）都不允许用HTTP，你以后就自己做转换吧，不要再来麻烦我了。</p><p>有了“HSTS”的指示，以后浏览器再访问同样的域名的时候就会自动把URI里的“http”改成“https”，直接访问安全的HTTPS网站。这样“中间人”就失去了攻击的机会，而且对于客户端来说也免去了一次跳转，加快了连接速度。</p><p>比如，如果在实验环境的配置文件里用“add_header”指令添加“HSTS”字段：</p><pre><code>add_header Strict-Transport-Security max-age=15768000; #182.5days
</code></pre><p>那么Chrome浏览器只会在第一次连接时使用HTTP协议，之后就会都走HTTPS协议。</p><h2>小结</h2><p>今天我介绍了一些HTTPS迁移的技术要点，掌握了它们你就可以搭建出一个完整的HTTPS站点了。</p><p>但想要实现大型网站的“全站HTTPS”还是需要有很多的细枝末节的工作要做，比如使用CSP（Content Security Policy）的各种指令和标签来配置安全策略，使用反向代理来集中“卸载”SSL。</p><p>简单小结一下今天的内容：</p><ol>
<li><span class="orange">从HTTP迁移到HTTPS是“大势所趋”，能做就应该尽早做；</span></li>
<li><span class="orange">升级HTTPS首先要申请数字证书，可以选择免费好用的“Let’s Encrypt”；</span></li>
<li><span class="orange">配置HTTPS时需要注意选择恰当的TLS版本和密码套件，强化安全；</span></li>
<li><span class="orange">原有的HTTP站点可以保留作为过渡，使用301重定向到HTTPS。</span></li>
</ol><h2>课下作业</h2><ol>
<li>结合你的实际工作，分析一下迁移HTTPS的难点有哪些，应该如何克服？</li>
<li>参考上一讲，你觉得配置HTTPS时还应该加上哪些部分？</li>
</ol><p>欢迎你把自己的学习体会写在留言区，与我和其他同学一起讨论。如果你觉得有所收获，也欢迎把文章分享给你的朋友。</p><p><img src="https://static001.geekbang.org/resource/image/db/ec/dbe386f94df8f69fc0b32d2b52e3b3ec.png" alt="unpreview"></p><p><img src="https://static001.geekbang.org/resource/image/56/63/56d766fc04654a31536f554b8bde7b63.jpg" alt="unpreview"></p>