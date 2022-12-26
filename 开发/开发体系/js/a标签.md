## 怎么修改a标签的请求头

如果你想修改 a 标签发送的 HTTP 请求的请求头，你可以使用 JavaScript 中的 XMLHttpRequest 对象。

例如，你可以使用下面的代码来修改 a 标签发送的 HTTP 请求的 User-Agent 请求头：

```js
Copy codeconst link = document.querySelector('a');
link.addEventListener('click', function(event) {
  event.preventDefault(); // 阻止 a 标签的默认行为（即跳转到 href 指向的 URL）
  const xhr = new XMLHttpRequest();
  xhr.open('GET', link.href);
  xhr.setRequestHeader('User-Agent', 'MyCustomUserAgent');
  xhr.send();
});
```

上面的代码使用了 XMLHttpRequest 对象的 open() 和 setRequestHeader() 方法来修改 a 标签发送的 HTTP 请求的 User-Agent 请求头。

注意，这种方法只能在浏览器中使用，并且会导致 a 标签的默认行为被阻止（即不会跳转到 href 指向的 URL）。如果你想要在修改请求头后继续跳转到 href 指向的 URL，你可以在发送请求后使用 window.location.href 来跳转。

## XMLHttpRequest能请求重定向的地址吗

当 XMLHttpRequest 对象发送的 HTTP 请求得到了服务器的响应，浏览器会根据响应的状态码来判断是否需要进行重定向。例如，如果响应的状态码是 301 或 302，浏览器会自动重定向到响应头中的 Location 指定的地址。

XMLHttpRequest 对象本身是不会自动进行重定向的，但是你可以使用 XMLHttpRequest 对象的 onreadystatechange 事件来捕获重定向的响应，并手动进行重定向。

例如，你可以使用下面的代码来手动进行重定向：

```js
Copy codeconst xhr = new XMLHttpRequest();
xhr.open('GET', '/redirect');
xhr.onreadystatechange = function() {
  if (xhr.readyState === XMLHttpRequest.DONE) {
    if (xhr.status === 301 || xhr.status === 302) {
      window.location.href = xhr.getResponseHeader('Location');
    }
  }
};
xhr.send();
```

上面的代码使用了 XMLHttpRequest 对象的 onreadystatechange 事件来捕获重定向的响应，并使用 window.location.href 来跳转到重定向的地址。