## **HTTP请求的组成**

从使用者的角度看，一个HTTP请求可以起始于：

1. 浏览器打开一个新的网页（手动输入网址或者点击超链接<a>）；
2. 提交一个表单(<form>)。

但本质上说，以上二种发起方式，都是用户端向HTTP服务器发送的一个URL请求。

一个标准的HTTP请求由以下几个部分组成：

1. <request-line>               // 请求行
2. <headers>/r                        // 请求头
3. <request-body>/r             // 请求体

**说明：**

> request-line：用来说明请求方法(request method)、要访问的资源（URL）以及使用的HTTP版本；
> headers：用来说明服务器要使用的附加信息（/r用于标记结束）；
> request-body：根据需要可在头部信息结束之后增加主体数据，（可选；如果请求方法是GET，则没有这个部分；/r用于标记结束）；

**注意：**

> request-line 中的URL部分必须以application/x-www-form-urlencoded方式编码。
> request-body 的编码方式由头部（headers）信息中的Content-Type指定。
> request-body 的长度由头部（headers）信息中的Content-Length指定。

**例子**

我们在IE浏览器上输入下面的网址：http://localhost:8000/hello/index.html

HTTP请求的头部信息如下：

> GET /hello/index.html HTTP/1.1          // 请求头
> Accept: */*                                                   // 发送端（客户端）希望接受的数据类型
> Accept-Language: zh-cn
> Accept-Encoding: gzip, deflate
> Host: localhost:8000
> Connection: Keep-Alive
> Cookie: JSESSIONID=BBBA54D519F7A320A54211F0107F5EA6

其中，第一行属于request-line，其他都是headers。

**请求方法**

在上面的介绍中，我们知道了，http请求中的request-line，包含了请求方法。

请求方法定义了该请求主要做的事。

根据HTTP标准，HTTP请求可以使用多种请求方法。

HTTP1.0定义了三种请求方法： GET, POST 和 HEAD方法。

HTTP1.1新增了五种请求方法：OPTIONS, PUT, DELETE, TRACE 和 CONNECT 方法。

**超链接请求**

上述例子没有request-body部分，因为他是一个超链接请求，超链接请求的请求方法只能是GET。

如果请求中需要附加主体数据，即增加request-body部分，则必须使用POST方式发送HTTP请求。

HTML超链接（<a></a>）只能用GET方式提交HTTP请求，HTML表单（<form></form>）则可以使用两种方式提交HTTP请求。

## **表单请求**

**使用方法：**

```html
<form action="目标地址" method="发送方式" enctype="数据主体的编码方式"> 
<!-- 各类型的表单域 --> 
<input name="NAME" value="VALUE"/> 
<textarea name="NAME">VALUE</textarea> 
<select name="NAME"> 
<option value="VALUE" selected="selected"/> 
</select> 
</form> 
```

action标签属性的值必须符合URL的要求，其编码必须符合application/x-www-form-urlencoded编码规则，无论使用何种请求方法。如下面的表单：

```html
<!-- 不符合要求的表单 --> 
<form action="checkUser.html?opt=中文" method="POST"> 
</form> 
```

这样的表单是不符合要求的。如果其URL值存在非法字符（如中文字符），应将其进行URL Encoding处理。URL Encoding的处理方法如下：

- 字母数字字符 "a" 到 "z"、"A" 到 "Z" 和 "0" 到 "9" 保持不变。
- 特殊字符 "."、"-"、"*" 和 "_" 保持不变。
- 空格字符 " " 转换为一个加号 "+"。
- 所有其他字符都是不安全的，因此首先使用一种编码机制将它们转换为一个或多个字节。然后对每个字节用一个包含 3 个字符的字符串 "%xy" 表示，其中 xy 为该字节的两位十六进制表示形式。推荐的编码机制是 UTF-8。

将“中文”两个字符进行URL Encoding所得到的值就是“%E4%B8%AD%E6%96%87”。

**请求方法**

method标签属性指定了表单的发送方式，发送方式只有两种：GET及POST。
当以GET方式发送表单时，发送的HTTP请求没有request-body部分，所以不需要指定enctype标签属性。

注意：

GET方式只提交表单域中的数据，action标签属性中如果存在?子句，GET方式将不予处理。如下面的表单：

```html
<form action="checkUser.html?opt=xxx" method="GET"> 
<input type="text" name="username" value="yyy"/> 
<input type="text" name="age" value="zzz"/> 
<input type="submit" value="submit"/> 
</form> 
```

表单提交时没有包括opt属性，HTTP头部信息如下：

> GET /hello/checkUser.html**?username=yyy&age=zzz** HTTP/1.1
> Referer: http://localhost:8000/hello/index.html
> Accept: */*
> Accept-Language: zh-cn
> Accept-Encoding: gzip, deflate
> Host: localhost:8000
> Connection: Keep-Alive
> Cookie: JSESSIONID=BBBA54D519F7A320A54211F0107F5EA6
>
> [End]

当以POST方式发送表单时，表单域中的数据将作为request-body提交，action标签属性中的?子句将在request-line中得以保留。如下面的表单：

```text
<form action="checkUser.html?opt=xxx" method="POST"> 
<input type="text" name="username" value="yyy"/> 
<input type="text" name="age" value="zzz"/> 
<input type="submit" value="submit"/> 
</form> 
```

表单提交时，HTTP头部信息如下：

> POST /hello/checkUser.html**?opt=xxx** HTTP/1.1
> Referer: http://localhost:8000/hello/index.html
> Accept: */*
> Accept-Language: zh-cn
> Content-Type: application/x-www-form-urlencoded    //发送端（客户端|服务器）发送的实体数据的数据类型。
> Accept-Encoding: gzip, deflate
> Host: localhost:8000
> Content-Length: 20
> Connection: Keep-Alive
> Cache-Control: no-cache
> Cookie: JSESSIONID=BBBA54D519F7A320A54211F0107F5EA6
>
> **username=yyy&age=zzz** [End]

**需要注意的是：**

以GET方式提交表单时，每个表单域的NAME与VALUE要以URL的方式提交，所以每个表单域的NAME与VALUE均要进行URL Encoding处理。不过这个操作通常是由用户端浏览器完成的。如下面的表单：

```html
<form action="checkUser.html" method="GET"> 
<input type="hidden" name="opt" value="中文"/> 
<input type="text" name="username" value="yyy"/> 
<input type="text" name="age" value="zzz"/> 
<input type="submit" value="submit"/> 
</form> 
```

其中表单域opt的VALUE是中文字符“中文”，在表单提交时，用户端浏览器会自动将其进行URL Encoding。HTTP头部信息如下：

> GET /hello/checkUser.html?**opt=%E4%B8%AD%E6%96%87**&username=yyy&age=zzz HTTP/1.1
> Referer: http://localhost:8000/hello/index.html
> Accept: */*                         
> Accept-Language: zh-cn
> Accept-Encoding: gzip, deflate
> Host: localhost:8000
> Connection: Keep-Alive
> Cookie: JSESSIONID=BBBA54D519F7A320A54211F0107F5EA6
>
> [End]

**数据主体的编码方式**

在HTTP请求中，**request-line总是以application/x-www-form-urlencoded方式编码**。**enctype标签属性只对request-body起作用**。也就是说只有在method="POST"的情况下，设置enctype才起作用。
设置enctype标签属性后，在HTTP请求的头部（headers）信息中会多出一行Content-Type信息，并且request-body部分将会以Content-Type指定的MIME进行编码。这些操作都是由客户端浏览器自动完成的。

在没有指定enctype标签属性时，表单以默认的application/x-www-form-urlencoded方式对request-body进行编码。
如果表单域中的NAME或VALUE含有非法字符（如中文字符），客户端浏览器会自动对其进行URL Encoding处理。如下面的表单：

```html
<form action="checkUser.html" method="POST"> 
<input type="hidden" name="opt" value="中文"/> 
<input type="text" name="username" value="yyy"/> 
<input type="text" name="age" value="zzz"/> 
<inupt type="submit" value="submit"/> 
</form> 
```

表单提交时，HTTP头部信息如下：

> POST /hello/checkUser.html HTTP/1.1
> Accept: */*
> Referer: http://localhost:8000/hello/index.jsp
> Accept-Language: zh-cn
> Content-Type: application/x-www-form-urlencoded
> Accept-Encoding: gzip, deflate
> Host: localhost:8000
> Content-Length: 43
> Connection: Keep-Alive
> Cache-Control: no-cache
> Cookie: JSESSIONID=4EF9C5B81356481F470F3C60D9E77D94
>
> **opt=%E4%B8%AD%E6%96%87**&username=yyy&age=zzz
> [End]

如果表单中包含需要上传的文件数据，则在指定method="POST"的同时还要指定enctype="multipart/form-data"。如下面的表单：

```html
<form action="checkUser.html?opt=xxx" method="POST" 
enctype="multipart/form-data"> 
<input type="text" name="username" value="yyy"/> 
<input type="text" name="age" value="zzz"/> 
<input type="file" name="file" /> 
<inupt type="submit" value="submit"/> 
</form> 
```

表单提交时HTTP头部信息如下：

> POST /hello/checkUser.html?opt=xxx HTTP/1.1
> Accept: */*
> Referer: http://localhost:8000/hello/index.html
> Accept-Language: zh-cn
> **Content-Type: multipart/form-data; boundary=---------------------------7d931c5d043e**
> Accept-Encoding: gzip, deflate
> Host: localhost:8000
> **Content-Length: 382**
> Connection: Keep-Alive
> Cache-Control: no-cache
> Cookie: JSESSIONID=6FE3D8E365DF9FE26221A32624470D24
>
> -----------------------------7d931c5d043e
> Content-Disposition: form-data; name="username"
>
> yyy
> -----------------------------7d931c5d043e
> Content-Disposition: form-data; name="age"
>
> zzz
> -----------------------------7d931c5d043e
> Content-Disposition: form-data; name="file"; filename="C:/1.txt"
> Content-Type: text/plain
>
> hello
> -----------------------------7d931c5d043e--
>
> [End]

常见的MediaType：

- text/html：HTML格式
- text/plain：纯文本格式
- text/xml：  XML格式
- image/gif：gif图片格式
- image/jpeg：jpg图片格式
- image/png：png图片格式
- application/xhtml+xml：XHTML格式
- application/xml： XML数据格式
- application/atom+xml：Atom XML聚合格式
- application/json：JSON数据格式
- application/pdf：pdf格式
- application/msword： Word文档格式
- application/octet-stream： 二进制流数据（如常见的文件下载）
- application/x-www-form-urlencoded：<form encType=" ">中默认的encType，form表单数据被编码为key/value格式发送到服务器（表单默认的提交数据的格式）
- multipart/form-data： 需要在表单中进行文件上传时，就需要使用该格式

### Spring MVC中关于关于Content-Type类型信息的使用

总结：

- Spring MVC中主要基于`@RequestMapping`标注使用，其中headers, consumes,produces,都是使用Content-Type中使用的各种媒体格式内容，来进行访问的控制和过滤。
   Spring MVC 中`RequestMapping`中的Class定义：

  

  ```java
  @Target({ElementType.METHOD, ElementType.TYPE})  
  @Retention(RetentionPolicy.RUNTIME)  
  @Documented  
  @Mapping  
  public @interface RequestMapping {  
        String[] value() default {};  
        RequestMethod[] method() default {};  
        String[] params() default {};  
        String[] headers() default {};  
        String[] consumes() default {};  
        String[] produces() default {};  
  }
  ```

  > value:  指定请求的实际地址， 比如 /action/info之类。
  >  method：  指定请求的method类型， GET、POST、PUT、DELETE等
  >  **consumes： 指定处理请求的提交内容类型（Content-Type），例如application/json, text/html;**
  >
  > ​						**consumes="application/json"方法仅处理request Content-Type为“application/json”类型的请求**
  >
  >  **produces:    指定返回的内容类型，仅当request请求头中的(Accept)类型中包含该指定类型才返回**
  >
  > ​						**produces="application/json"仅处理request请求中Accept头中包含了"application/json"的请求，方法返回json数据**
  >
  >  params： 指定request中必须包含某些参数值是，才让该方法处理
  >  headers： 指定request中必须包含某些指定的header值，才能让该方法处理请求
  >
  > ​					params="myParam=myValue"：只处理请求中含有参数myParam，并且参数myParam的值为myValue
  >
  > ​					headers="Referer=http://www.ifeng.com/"：表示只处理请求中含有Referer，且Referer=http://www.ifeng.com/ 
  >
  > 其中，consumes， produces使用content-typ信息进行过滤信息；headers中可以使用content-type进行过滤和判断。

  基于`@RequestMapping`衍生版：

  - `@GetMapping`
  - `@PostMapping`
  - `@PutMapping`
  - `@PatchMapping`
  - `@DeleteMapping`

- `GET`请求时是否定义`Content-Type`并无很大的影响，因为GET没有请求体，所有的数据都是通过url带过去，所以必须是"key=value"的格式，所以在springmvc端使用`@RequestParam String id`这种格式即可，或者不写`@RequestParam`也可以，不写的话默认是@RequestParam

- 除`GET`外的这几种（`POST、DELETE、PUT、PATCH`）都是有请求体（`body`）的，且他们之间的差异不大：

  - 当请求时定义Content-Type为`application/json;charset=utf-8`时，请求体中的数据（不管是不是json格式）都只能用@RequestBody获取，且一个方法参数列表最多写一个@RequestBody;
  - 当然你也可以在请求url上带其他的queryString参数，然后在springmvc使用String id或@RequestParam String id获取。

  > @RequestParam是无法获取请求体（body）中的参数的，springmvc会报错：Required String parameter 'name' is not present。
  >  所以这种情况只能使用@RequestBody获取请求体中的参数。
  >  至于你使用Bean接收还是String接收取决你的需求，Bean接收更方便，不需要再次反序列化，而String接收可以更灵活，可以对接收到的字段进行检查。

- 当请求时未定义Content-Type（`默认为application/x-www-form-urlencoded; charset=UTF-8`），请求体中的数据都必须是key=values的类型，可以是使用@RequestBody获取整个请求体中的多个参数，也可以使用@RequestParam获取单个参数

### 4.案例



```java
GET
    url//请求的url
        http://localhost:9080/api/thirdparty/policy?id=1
    header//请求时header中携带的参数
        Content-Type:application/json; charset=utf-8 //是否定义没啥区别
    queryString//请求时携带的参数
        name=abc    //无法定义成json格式，必须是key=value格式
    springmvc//后台接收的方式
        String name
        @RequestParam String name //有无@RequestParam都行
        //无法使用@RequestBody,因为get没有body
```



```java
POST
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type未定义 //默认值Content-Type:application/x-www-form-urlencoded; charset=UTF-8
    body
        name=abc    // 若body中的是json格式数据如："{'name':'abc'}"，
        		    // 则后台无法获取到参数name，从而无法访问接口
    springmvc
        @RequestBody String name 
            name="abc"
        String id
            id="1"
 
POST
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type:application/json; charset=utf-8
    body
        {'name':'abc'}
    springmvc
        @RequestBody String body //@RequestBody是获取request的整个body体的数据,并且只能获取body中的数据,
                                 //如果body中没有json数据，请求则报错Required request body is missing:
            body="{'name':'abc'}"
        String id
            id="1"
 
POST
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type未定义 //默认值Content-Type:application/x-www-form-urlencoded; charset=UTF-8
    body
        {'name':'abc'}
    springmvc
        @RequestBody String body //这时的@RequestBody是获取queryString的参数+body参数URL编码后的值,因为有{}字符
            body="id=1&%7B%27name%27%3A%27abc%27%7D="
        @RequestParam String id
            id="1"
 
POST
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type:application/x-www-form-urlencoded; charset=UTF-8
    body
        name=abc
    springmvc
        @RequestBody String body //这时的@RequestBody是获取queryString的参数+body参数URL编码后的值
            body="id=1&name=abc"
        @RequestParam String id
            id="1"
```



```properties
DELETE
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type未定义 //默认值Content-Type:application/x-www-form-urlencoded; charset=UTF-8
    body
        name=abc
    springmvc
        @RequestBody String body //这时的@RequestBody是获取整个body数据,注意和post不同哦
            body="name=abc"
        @RequestParam String id
            id="1"
 
 
DELETE
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type:application/json; charset=utf-8
    body
        {'name':'abc'}
    springmvc
        @RequestBody String body //这时的@RequestBody是获取整个body数据,同样请求时未有body数据就报错
            body="{'name':'abc'}"
        @RequestParam String id
            id="1"
```



```properties
PUT
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type未定义 //默认值Content-Type:application/x-www-form-urlencoded; charset=UTF-8
    body
        {'name':'abc'}
    springmvc
        @RequestBody String body //这时的@RequestBody是获取整个body数据,同样请求时未有body数据就报错
            body="{'name':'abc'}"
        @RequestParam String id
            id="1"
PUT
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type:application/json; charset=utf-8
    body
        {'name':'abc'}
    springmvc
        @RequestBody String body //这时的@RequestBody是获取整个body数据,同样请求时未有body数据就报错
            body="{'name':'abc'}"
        @RequestParam String id
            id="1"
```



```properties
PATCH
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type:application/json; charset=utf-8
    body
        {'name':'abc'}
    springmvc
        @RequestBody String body //这时的@RequestBody是获取整个body数据,同样请求时未有body数据就报错
            body="{'name':'abc'}"
        @RequestParam String id
            id="1"
 
PATCH
    url
        http://localhost:9080/api/thirdparty/policy?id=1
    header
        Content-Type未定义 //默认值Content-Type:application/x-www-form-urlencoded; charset=UTF-8
    body
        {'name':'abc'}
    springmvc
        @RequestBody String body //这时的@RequestBody是获取整个body数据,同样请求时未有body数据就报错
            body="{'name':'abc'}"
        @RequestParam String id
            id="1"
```



