<audio title="09 _ HTTP报文是什么样子的？" src="https://static001.geekbang.org/resource/audio/fd/04/fd314ef48924d547230a89a7115b9204.mp3" controls="controls"></audio> 
<p>在上一讲里，我们在本机的最小化环境了做了两个HTTP协议的实验，使用Wireshark抓包，弄清楚了HTTP协议基本工作流程，也就是“请求-应答”“一发一收”的模式。</p><p>可以看到，HTTP的工作模式是非常简单的，由于TCP/IP协议负责底层的具体传输工作，HTTP协议基本上不用在这方面操心太多。单从这一点上来看，所谓的“超文本传输协议”其实并不怎么管“传输”的事情，有点“名不副实”。</p><p>那么HTTP协议的核心部分是什么呢？</p><p>答案就是它传输的报文内容。</p><p>HTTP协议在规范文档里详细定义了报文的格式，规定了组成部分，解析规则，还有处理策略，所以可以在TCP/IP层之上实现更灵活丰富的功能，例如连接控制，缓存管理、数据编码、内容协商等等。</p><h2>报文结构</h2><p>你也许对TCP/UDP的报文格式有所了解，拿TCP报文来举例，它在实际要传输的数据之前附加了一个20字节的头部数据，存储TCP协议必须的额外信息，例如发送方的端口号、接收方的端口号、包序号、标志位等等。</p><p>有了这个附加的TCP头，数据包才能够正确传输，到了目的地后把头部去掉，就可以拿到真正的数据。</p><p><img src="https://static001.geekbang.org/resource/image/17/95/174bb72bad50127ac84427a72327f095.png" alt=""></p><p>HTTP协议也是与TCP/UDP类似，同样也需要在实际传输的数据前附加一些头数据，不过与TCP/UDP不同的是，它是一个“<strong>纯文本</strong>”的协议，所以头数据都是ASCII码的文本，可以很容易地用肉眼阅读，不用借助程序解析也能够看懂。</p><!-- [[[read_end]]] --><p>HTTP协议的请求报文和响应报文的结构基本相同，由三大部分组成：</p><ol>
<li>起始行（start line）：描述请求或响应的基本信息；</li>
<li>头部字段集合（header）：使用key-value形式更详细地说明报文；</li>
<li>消息正文（entity）：实际传输的数据，它不一定是纯文本，可以是图片、视频等二进制数据。</li>
</ol><p>这其中前两部分起始行和头部字段经常又合称为“<strong>请求头</strong>”或“<strong>响应头</strong>”，消息正文又称为“<strong>实体</strong>”，但与“<strong>header</strong>”对应，很多时候就直接称为“<strong>body</strong>”。</p><p>HTTP协议规定报文必须有header，但可以没有body，而且在header之后必须要有一个“空行”，也就是“CRLF”，十六进制的“0D0A”。</p><p>所以，一个完整的HTTP报文就像是下图的这个样子，注意在header和body之间有一个“空行”。</p><p><img src="https://static001.geekbang.org/resource/image/62/3c/62e061618977565c22c2cf09930e1d3c.png" alt=""></p><p>说到这里，我不由得想起了一部老动画片《大头儿子和小头爸爸》，你看，HTTP的报文结构像不像里面的“大头儿子”？</p><p>报文里的header就是“大头儿子”的“大头”，空行就是他的“脖子”，而后面的body部分就是他的身体了。</p><p>看一下我们之前用Wireshark抓的包吧。</p><p><img src="https://static001.geekbang.org/resource/image/b1/df/b191c8760c8ad33acd9bb005b251a2df.png" alt="unpreview"></p><p>在这个浏览器发出的请求报文里，第一行“GET / HTTP/1.1”就是请求行，而后面的“Host”“Connection”等等都属于header，报文的最后是一个空白行结束，没有body。</p><p>在很多时候，特别是浏览器发送GET请求的时候都是这样，HTTP报文经常是只有header而没body，相当于只发了一个超级“大头”过来，你可以想象的出来：每时每刻网络上都会有数不清的“大头儿子”在跑来跑去。</p><p>不过这个“大头”也不能太大，虽然HTTP协议对header的大小没有做限制，但各个Web服务器都不允许过大的请求头，因为头部太大可能会占用大量的服务器资源，影响运行效率。</p><h2>请求行</h2><p>了解了HTTP报文的基本结构后，我们来看看请求报文里的起始行也就是<strong>请求行</strong>（request line），它简要地描述了<strong>客户端想要如何操作服务器端的资源</strong>。</p><p>请求行由三部分构成：</p><ol>
<li>请求方法：是一个动词，如GET/POST，表示对资源的操作；</li>
<li>请求目标：通常是一个URI，标记了请求方法要操作的资源；</li>
<li>版本号：表示报文使用的HTTP协议版本。</li>
</ol><p>这三个部分通常使用空格（space）来分隔，最后要用CRLF换行表示结束。</p><p><img src="https://static001.geekbang.org/resource/image/36/b9/36108959084392065f36dff3e12967b9.png" alt=""></p><p>还是用Wireshark抓包的数据来举例：</p><pre><code>GET / HTTP/1.1
</code></pre><p>在这个请求行里，“GET”是请求方法，“/”是请求目标，“HTTP/1.1”是版本号，把这三部分连起来，意思就是“服务器你好，我想获取网站根目录下的默认文件，我用的协议版本号是1.1，请不要用1.0或者2.0回复我。”</p><p>别看请求行就一行，貌似很简单，其实这里面的“讲究”是非常多的，尤其是前面的请求方法和请求目标，组合起来变化多端，后面我还会详细介绍。</p><h2>状态行</h2><p>看完了请求行，我们再看响应报文里的起始行，在这里它不叫“响应行”，而是叫“<strong>状态行</strong>”（status line），意思是<strong>服务器响应的状态</strong>。</p><p>比起请求行来说，状态行要简单一些，同样也是由三部分构成：</p><ol>
<li>版本号：表示报文使用的HTTP协议版本；</li>
<li>状态码：一个三位数，用代码的形式表示处理的结果，比如200是成功，500是服务器错误；</li>
<li>原因：作为数字状态码补充，是更详细的解释文字，帮助人理解原因。</li>
</ol><p><img src="https://static001.geekbang.org/resource/image/a1/00/a1477b903cd4d5a69686683c0dbc3300.png" alt=""></p><p>看一下上一讲里Wireshark抓包里的响应报文，状态行是：</p><pre><code>HTTP/1.1 200 OK
</code></pre><p>意思就是：“浏览器你好，我已经处理完了你的请求，这个报文使用的协议版本号是1.1，状态码是200，一切OK。”</p><p>而另一个“GET /favicon.ico HTTP/1.1”的响应报文状态行是：</p><pre><code>HTTP/1.1 404 Not Found
</code></pre><p>翻译成人话就是：“抱歉啊浏览器，刚才你的请求收到了，但我没找到你要的资源，错误代码是404，接下来的事情你就看着办吧。”</p><h2>头部字段</h2><p>请求行或状态行再加上头部字段集合就构成了HTTP报文里完整的请求头或响应头，我画了两个示意图，你可以看一下。</p><p><img src="https://static001.geekbang.org/resource/image/1f/ea/1fe4c1121c50abcf571cebd677a8bdea.png" alt=""></p><p><img src="https://static001.geekbang.org/resource/image/cb/75/cb0d1d2c56400fe9c9988ee32842b175.png" alt=""></p><p>请求头和响应头的结构是基本一样的，唯一的区别是起始行，所以我把请求头和响应头里的字段放在一起介绍。</p><p>头部字段是key-value的形式，key和value之间用“:”分隔，最后用CRLF换行表示字段结束。比如在“Host: 127.0.0.1”这一行里key就是“Host”，value就是“127.0.0.1”。</p><p>HTTP头字段非常灵活，不仅可以使用标准里的Host、Connection等已有头，也可以任意添加自定义头，这就给HTTP协议带来了无限的扩展可能。</p><p>不过使用头字段需要注意下面几点：</p><ol>
<li>字段名不区分大小写，例如“Host”也可以写成“host”，但首字母大写的可读性更好；</li>
<li>字段名里不允许出现空格，可以使用连字符“-”，但不能使用下划线“_”。例如，“test-name”是合法的字段名，而“test name”“test_name”是不正确的字段名；</li>
<li>字段名后面必须紧接着“:”，不能有空格，而“:”后的字段值前可以有多个空格；</li>
<li>字段的顺序是没有意义的，可以任意排列不影响语义；</li>
<li>字段原则上不能重复，除非这个字段本身的语义允许，例如Set-Cookie。</li>
</ol><p>我在实验环境里用Lua编写了一个小服务程序，URI是“/09-1”，效果是输出所有的请求头。</p><p>你可以在实验环境里用Telnet连接OpenResty服务器试一下，手动发送HTTP请求头，试验各种正确和错误的情况。</p><p>先启动OpenResty服务器，然后用组合键“Win+R”运行telnet，输入命令“open www.chrono.com 80”，就连上了Web服务器。</p><p><img src="https://static001.geekbang.org/resource/image/34/7b/34fb2b5899bdb87a3899dd133c0c457b.png" alt=""></p><p>连接上之后按组合键“CTRL+]”，然后按回车键，就进入了编辑模式。在这个界面里，你可以直接用鼠标右键粘贴文本，敲两下回车后就会发送数据，也就是模拟了一次HTTP请求。</p><p>下面是两个最简单的HTTP请求，第一个在“:”后有多个空格，第二个在“:”前有空格。</p><pre><code>GET /09-1 HTTP/1.1
Host:   www.chrono.com


GET /09-1 HTTP/1.1
Host : www.chrono.com
</code></pre><p>第一个可以正确获取服务器的响应报文，而第二个得到的会是一个“400 Bad Request”，表示请求报文格式有误，服务器无法正确处理：</p><pre><code>HTTP/1.1 400 Bad Request
Server: openresty/1.15.8.1
Connection: close
</code></pre><h2>常用头字段</h2><p>HTTP协议规定了非常多的头部字段，实现各种各样的功能，但基本上可以分为四大类：</p><ol>
<li>通用字段：在请求头和响应头里都可以出现；</li>
<li>请求字段：仅能出现在请求头里，进一步说明请求信息或者额外的附加条件；</li>
<li>响应字段：仅能出现在响应头里，补充说明响应报文的信息；</li>
<li>实体字段：它实际上属于通用字段，但专门描述body的额外信息。</li>
</ol><p>对HTTP报文的解析和处理实际上主要就是对头字段的处理，理解了头字段也就理解了HTTP报文。</p><p>后续的课程中我将会以应用领域为切入点介绍连接管理、缓存控制等头字段，今天先讲几个最基本的头，看完了它们你就应该能够读懂大多数HTTP报文了。</p><p>首先要说的是<strong>Host</strong>字段，它属于请求字段，只能出现在请求头里，它同时也是唯一一个HTTP/1.1规范里要求<strong>必须出现</strong>的字段，也就是说，如果请求头里没有Host，那这就是一个错误的报文。</p><p>Host字段告诉服务器这个请求应该由哪个主机来处理，当一台计算机上托管了多个虚拟主机的时候，服务器端就需要用Host字段来选择，有点像是一个简单的“路由重定向”。</p><p>例如我们的试验环境，在127.0.0.1上有三个虚拟主机：“www.chrono.com”“www.metroid.net”和“origin.io”。那么当使用域名的方式访问时，就必须要用Host字段来区分这三个IP相同但域名不同的网站，否则服务器就会找不到合适的虚拟主机，无法处理。</p><p><strong>User-Agent</strong>是请求字段，只出现在请求头里。它使用一个字符串来描述发起HTTP请求的客户端，服务器可以依据它来返回最合适此浏览器显示的页面。</p><p>但由于历史的原因，User-Agent非常混乱，每个浏览器都自称是“Mozilla”“Chrome”“Safari”，企图使用这个字段来互相“伪装”，导致User-Agent变得越来越长，最终变得毫无意义。</p><p>不过有的比较“诚实”的爬虫会在User-Agent里用“spider”标明自己是爬虫，所以可以利用这个字段实现简单的反爬虫策略。</p><p><strong>Date</strong>字段是一个通用字段，但通常出现在响应头里，表示HTTP报文创建的时间，客户端可以使用这个时间再搭配其他字段决定缓存策略。</p><p><strong>Server</strong>字段是响应字段，只能出现在响应头里。它告诉客户端当前正在提供Web服务的软件名称和版本号，例如在我们的实验环境里它就是“Server: openresty/1.15.8.1”，即使用的是OpenResty 1.15.8.1。</p><p>Server字段也不是必须要出现的，因为这会把服务器的一部分信息暴露给外界，如果这个版本恰好存在bug，那么黑客就有可能利用bug攻陷服务器。所以，有的网站响应头里要么没有这个字段，要么就给出一个完全无关的描述信息。</p><p>比如GitHub，它的Server字段里就看不出是使用了Apache还是Nginx，只是显示为“GitHub.com”。</p><p><img src="https://static001.geekbang.org/resource/image/f1/1c/f1970aaecad58fb18938e262ea7f311c.png" alt=""></p><p>实体字段里要说的一个是<strong>Content-Length</strong>，它表示报文里body的长度，也就是请求头或响应头空行后面数据的长度。服务器看到这个字段，就知道了后续有多少数据，可以直接接收。如果没有这个字段，那么body就是不定长的，需要使用chunked方式分段传输。</p><h2>小结</h2><p>今天我们学习了HTTP的报文结构，下面做一个简单小结。</p><ol>
<li><span class="orange">HTTP报文结构就像是“大头儿子”，由“起始行+头部+空行+实体”组成，简单地说就是“header+body”；</span></li>
<li><span class="orange">HTTP报文可以没有body，但必须要有header，而且header后也必须要有空行，形象地说就是“大头”必须要带着“脖子”；</span></li>
<li><span class="orange">请求头由“请求行+头部字段”构成，响应头由“状态行+头部字段”构成；</span></li>
<li><span class="orange">请求行有三部分：请求方法，请求目标和版本号；</span></li>
<li><span class="orange">状态行也有三部分：版本号，状态码和原因字符串；</span></li>
<li><span class="orange">头部字段是key-value的形式，用“:”分隔，不区分大小写，顺序任意，除了规定的标准头，也可以任意添加自定义字段，实现功能扩展；</span></li>
<li><span class="orange">HTTP/1.1里唯一要求必须提供的头字段是Host，它必须出现在请求头里，标记虚拟主机名。</span></li>
</ol><h2>课下作业</h2><ol>
<li>如果拼HTTP报文的时候，在头字段后多加了一个CRLF，导致出现了一个空行，会发生什么？</li>
<li>讲头字段时说“:”后的空格可以有多个，那为什么绝大多数情况下都只使用一个空格呢？</li>
</ol><p>欢迎你把自己的答案写在留言区，与我和其他同学一起讨论。如果你觉得有所收获，也欢迎把文章分享给你的朋友。</p><p><img src="https://static001.geekbang.org/resource/image/1a/26/1aa9cb1a1d637e10340451d81e87fc26.png" alt="unpreview"></p><p></p>