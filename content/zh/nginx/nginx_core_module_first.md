---
title : "Nginx模块系列之核心模块(上)"
weight : 11 
---

> Nginx核心模块为nginx提供核心配置功能，包括静态目录配置、localtion匹配、限速以及各种优化参数，下面针对这几方面详细展开来说nginx的核心模块, 此部分内容分为上中下三节; 

## 1. 静态服务配置之root和alias   
root和alias都可以在配置静态服务时发挥重要的作用，二者可以达到相同的功能，但是也有很大的不同，每个都有其适应的场景。  

`alias`: alias后直接加路径，实现请求路径的替换。比如:  

```shell
location /i/ {
    alias /data/w3/images/;
}
# 当访问/i/top.gif，/data/w3/images/top.gif将发送给客户端。

```
在配置alias的路径时，可以包含除$document_root和$realpath_root外的变量。当alias用在正则模式的的localtion匹配时，localtion正则匹配中应该包含正则捕获并在alias中引用，示例如下:

```shell
location ~ ^/users/(.+\.(?:gif|jpe?g|png))$ {
    alias /data/w3/images/$1;
}
```
当localtion匹配alias指令的最后部分，可用root指令代替，更容易理解，示例如下:

```shell
location /images/ {
    alias /data/w3/images/;

}

location /images/ {
    root /data/w3;

}
# 以上两种的配置功能完全一致，但root指令更容易理解与简洁。

```
`root`: 直接加路径，指定请求的根目录。  
示例:  

```shell
location /i/ {
    root /data/w3;
}
```
当请求/i/top.gif，/data/w3/i/top.gif将会发送给客户端。
在配置root的路径时，可以包含除$document_root和$realpath_root外的变量。使用root指令通过简单指定路径即可获取请求文件的路径，但是无法达到对请求URI的修改，此时需要使用alias指定来配置。



## 2. 客户端大文件上传的配置需求 
`client_max_body_size`:  size，单位可以k m g等 
设置客户端请求body的最大允许大小，即"Content-Length"请求头字段中指定值。如果请求中的对应大小超过配置的值，则会向客户端返回413(Request Entity Too Large)错误。 请注意，浏览器无法正确显示此错误。将size设置为0将禁用对客户端请求主体大小的检查。


## 3. 优雅的错误处理 
`error_page`: error_page code ... [=[response]] uri;   
配置上下文为http,server,location,if in location,无默认值。
功能为定义将为指定错误显示的URI。  

i述配置中code为对应的异常状态码，比如404,403,500,502等，此处可以指定多个，空格分隔即可。[=[response]]表示将对应错误码转为指定的状态码，比如200。uri为返回给客户端的响应uri，uri可含有变量。  

示例:
```shell
error_page 404             /404.html;
error_page 500 502 503 504 /50x.html;
```

这会导致内部重定向到指定的uri，而客户端请求方法已更改为“GET”（对于“GET”和“HEAD”以外的所有方法）。  

示例:
```shell
error_page 404 =200 /empty.gif;
```
上述通过"=response"，来改变响应码。

如果错误响应是由代理服务器或FastCGI/uwsgi/SCGI/gRPC服务器处理的，并且服务器可能返回不同的响应代码(例如200、302、401或404)，则可以使用以下配置进行处理:

```shell
error_page 404 = /404.php;
```

可以看到以上配置中其实是省略了response，默认服务器返回的状态码一致。 
如果在内部重定向期间无需更改URI和方法，则可以将错误处理传递到命名location:

```shell
location / {
    error_page 404 = @fallback;

}

location @fallback {
    proxy_pass http://backend;

}
```
如果uri处理导致错误，则将最后一次发生的错误的状态代码返回给客户端。  
也可以使用URL重定向进行错误处理:  

```shell
error_page 403      http://example.com/forbidden.html;
error_page 404 =301 http://example.com/notfound.html;
```
在上面的示例中，默认情况下，响应代码302返回给客户机。它只能被更改为一个重定向状态码(301,302,303,307，和308)。  
当且仅当当前级别上没有定义`error_page`指令时，这些指令才从上一级继承。

## 4. 静态大文件处理优化 
`directio`: dirrectio size | off; 默认为off，配置上下文：http,server,location。首次在nginx 0.7.7版本中引入。  
当我们配置size后，当文件大小超过size后，将启用对应系统的directio相关系统调用来对文件进行处理，这在nginx作为静态大文件下载服务时，非常有用。在nginx 0.7.15后，当配置sendfile指令后，该指令自动禁用。  
示例：
```shell
directio 4m;
```
在linux相关系统中，我们也可以使用aio指令来对大文件下载进行优化。
`aio`: aio on | off | threads[=pool]; 默认为off，配置上下文：http, server, location, 引入在0.8.11版本。  
```shell
location /video/ {
    aio            on;
    output_buffers 1 64k;
}
```
以上配置，即可打开aio(即异步io)配置。在linux中，aio需要kernel 2.6.22版本支持。  

```shell
location /video/ {
    aio            on;
    directio       512;
    output_buffers 1 128k;

}
```
在Linux上，directio仅可用于读取在512字节边界（对于XFS为4K）上对齐的块。 未对齐结尾的文件以阻塞模式读取。 对于字节范围请求和不是从文件开头开始的FLV请求也是如此：在文件的开头和结尾读取未对齐的数据将被阻塞。

在Linux上同时启用AIO和sendfile时，AIO用于大于或等于directio指令中指定的大小的文件，而sendfile用于较小的文件或禁用directio的文件。

示例:
```shell
location /video/ {
    sendfile       on;
    aio            on;
    directio       8m;

}
```
另外nginx在处理读取和发送文件时，可采用多线程的方式(1.7.11)，该方式不阻塞工作进程。默认情况下，禁用多线程，应在编译时使用--with-threads配置参数启用它。 当前，多线程仅与epoll，kqueue和eventport方法兼容。 仅在Linux上支持文件的多线程发送。
示例: 
```shell
location /video/ {
    sendfile       on;
    aio            threads;

}
```
aio具体所使用的线程池配置可由poll指令配置，参考http://nginx.org/en/docs/ngx_core_module.html#thread_pool，指定线程池的配置如下:

```shell
aio threads=pool$disk;
```

## 5. 自定义http头部传递规则控制
控制自定义http头部的合法性主要有`ignore_invalid_headers`和`underscores_in_headers`。  

`ignore_invalid_headers`: 控制无效头部是否应该被忽略，默认on, 合法的头部由有效名称由英文字母，数字，连字符[-]和可能的下划线组成(由`underscores_in_headers`指令控制)。  

`underscores_in_headers`: 控制客户端请求头字段中是否可以含有下划线。 禁止使用下划线时，名称中包含下划线的请求标头字段将被标记为无效，默认为off。 
 
以上两个指令配置上下文: http, server。  

注意:  
如果指令是在server级别指定的，则仅当server为默认server时才使用其值。指定的值也适用于监听在相同地址和端口上所有虚拟服务器。


## 6. keepalive长连接
* `keepalive_disable`: 控制不同浏览器keepalive的禁用情况。 配置格式: keepalive_disable none | browser ...; 默认值: keepalive_disable msie6;   

```shell
browser参数指定将受影响的浏览器。可指定多个。 
1. msie6 禁用与旧版本MSIE的keepalive连接。 
2. safari 禁用与macOS和类似macOS的操作系统上的Safari和类似Safari的浏览器的keepalive链接。 
3. none 启用与所有浏览器的保持活动连接。
```
* `keepalive_requests`: 设置keepalive连接的最大服务请求数。 请求数量到达最大值，将关闭连接。配置格式: keepalive_requests number; 默认值: keepalive_requests 100;   
 
注意: 定期关闭连接对于释放每个连接的内存分配是必要的。因此，使用过高的最大请求数可能会导致过度的内存使用，不建议这样做。

* `keepalive_timeout`: 设置keepalive最大的超时时长，配置格式: keepalive_timeout timeout [header_timeout]; 默认值: keepalive_timeout 75s;  
 
第一个参数设置超时时长，在这段时间中，如果客户端连接保持活动状态，那么在服务的keepalive连接也将处于打开状态直到到达超时时长。零值将禁用客户端的keepalive连接。可选的第二个参数在"Keep-Alive: timeout = time"响应头中设置一个值。 两个参数可以不同。  

## 7. 传输速率限制
* `limit_except`: 限制http请求方法，无默认值，配置上下文为location。配置格式:`limit_except` method ... { ...  }    

```shell
limit_except GET {
    allow 192.168.1.0/32;
    deny  all;
}
```
在上面的配置中，只允许来自192.168.1.0/32网段的GET和HAED请求。  

method参数: GET，HEAD，POST，PUT，DELETE，MKCOL，COPY，MOVE，OPTIONS，PROPFIND，PROPPATCH，LOCK，UNLOCK或PATCH。 允许GET方法时HEAD方法也被允许。  

可以使用`ngx_http_access_module`，`ngx_http_auth_basic_module`和`ngx_http_auth_jwt_module(1.13.10)`模块指令来对请求http方法进行进一步限制。  

* `limit_rate`:  limit_rate rate; 默认值: limit_rate 0; 配置上下文: http, server, location, if in location。  

限制向客户端传输响应的速率。 该速率以每秒字节数指定。 零值禁用速率限制。 该限制是根据请求设置的，因此，如果客户端同时打开两个连接，则总速率将是指定限制的两倍。  
rate参数可以含有变量，结合map指令就可以做到不同条件配置不同的速率，这使得配置起来更加的灵活,示例如下:  
```shell
map $slow $rate {
    1     4k;
    2     8k;

}

limit_rate $rate;
```

速率限制也可以在代理服务器响应的“ X-Accel-Limit-Rate”标头字段中设置。 可以使用proxy_ignore_headers，fastcgi_ignore_headers，uwsgi_ignore_headers和scgi_ignore_headers指令禁用此功能。

* limit_rate_after:  limit_rate_after size; 默认值：limit_rate_after 0;配置上下文: http, server, location, if in location。  

通过limit_rate_after指令，我们可以设置客户端传输的起始容量，达到此限制后开启速率限制。  

```shell
location /flv/ {
    flv;
    limit_rate_after 500k;
    limit_rate       50k;

}
```
在上面的配置中，当客户端连接传输达到500k时，将开始速率限制。  

## 总结 
这次就说到这里，nginx核心模块中最常使用的location还没登场，放下下次单独聊聊，并加上nginx一些优化选项，敬请期待!
