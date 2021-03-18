1. servlet的生命周期

   服务器启动时(web.xml中配置load-on-startup=1，默认为0)或者第一次请求该servlet时，就会初始化一个Servlet对象，也就是会执行初始化方法init(ServletConfig conf)该servlet对象去处理所有客户端请求，在service(ServletRequest req，ServletResponse res)方法中执行，最后服务器关闭时，才会销毁这个servlet对象，执行destroy()方法

2. **Servlet 类关系结构**

   - **Servlet** 

     ```java
     public interface Servlet {
         void init(ServletConfig var1) throws ServletException;
     
         ServletConfig getServletConfig();
         
         void service(ServletRequest var1, ServletResponse var2) throws ServletException, IOException;
         
         String getServletInfo();
         
         void destroy();
     
     }
     ```

   - **ServletConfig** 

     ```java
     public interface ServletConfig {
         String getServletName();
     
         ServletContext getServletContext();
         
         String getInitParameter(String var1);
         
         Enumeration getInitParameterNames();
     ```

   - **GenericServlet implements Servlet, ServletConfig**

     GenericServlet 实现了 ServletConfig 定义了成员变量`private transient ServletConfig config;`，在项目启动时，通过

          ```java
     public void init(ServletConfig config) throws ServletException {
         this.config = config;
         this.init();
     }
          ```

   init(ServletConfig config)方法，注入ServletConfig ，并提供了一个空参init()方法，防止在需要初始化信息时（重写init()）重写覆盖init(ServletConfig config)方法，导致ServletConfig 为空。

   - **HttpServlet extends GenericServlet**
     HttpServlet 重写了service(ServletRequest req, ServletResponse res)方法。

     ```java
     public void service(ServletRequest req, ServletResponse res) throws ServletException, IOException {
             HttpServletRequest request;
             HttpServletResponse response;
             try {
                 request = (HttpServletRequest)req;
                 response = (HttpServletResponse)res;
             } catch (ClassCastException var6) {
                 throw new ServletException("non-HTTP request or response");
             }
     
             this.service(request, response);
         }
     ```

     `request = (HttpServletRequest)req; response = (HttpServletResponse)res;`强转为HTTP的请求和响应；并通过service(HttpServletRequest req, HttpServletResponse resp) 方法，划分了各种请求方法。

     ```java
     doGet,doPost,doPut.....
     ```

   - 写一个servlet程序；

     1. 继承HttpServlet

        ```java
        public class MySevrlet extends HttpServlet {
            @Override
            protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
                System.out.println("doGEt");
            }
            
            @Override
            protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
                System.out.println("doPost");
            }
        
            @Override
            public void destroy() {
                System.out.println("destroy");
            }
        
            @Override
            public void init() throws ServletException {
                System.out.println("init");
            }
        }
        ```

     2. 配置servletu映射

        ```xml
        <servlet>
            //servlet名
            <servlet-name>MyServlet</servlet-name>
            // 全类名
            <servlet-class>zyc.com.servlet.controller.MySevrlet</servlet-class>
        </servlet>
        <servlet-mapping>
             //servlet名 与上面的一样
            <servlet-name>MyServlet</servlet-name>
            // 访问路径
            <url-pattern>/myservlet</url-pattern>
        </servlet-mapping>
        ```

     3. 访url：http://localhost:8080/study/myservlet。study是通过tomcat配置的根路径

        按照步骤，首先浏览器通过http://localhost:8080/study/myservlet来找到web.xml中的url-pattern，这就是第一步，匹配到了url-pattern后，就会找到第二步servlet的名字MyServlet，知道了名字，就可以通过servlet-name找到第三步，到了第三步，也就能够知道servlet的位置了。然后到其中找到对应的处理方式进行处理。

   

   

