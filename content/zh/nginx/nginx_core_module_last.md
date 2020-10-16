---
title : "Nginx模块系列之核心模块(下)"
weight : 13 
---

> 随着讲解的深入，nginx核心模块的知识点我们已经学的差不多了，下面我们就在工作中，在nginx核心模块中可能遇到的配置来具体的看一看。

## 1.优化日志输出，减少不必要的文件未找到的错误日志输出
指令: `log_not_found`on | off;  
默认值: `log_not_found` on;  
配置上下文: http, server, location  

log_not_found指令可以配置当文件不存在时，是否写入error_log，如果我们不关心此类日志，可以直接关闭，或者针对特定location进行关闭，非常灵活;

## 2.多条件访问控制
指令: satisfy all | any;  
默认值: satisfy all;  
配置上下文: http, server, location  

如果所有(all)或至少一个(any)`ngx_http_access_module`，`ngx_http_auth_basic_module`，`ngx_http_auth_request_module`或`ngx_http_auth_jwt_module`模块允许访问，则允许访问。
示例:  
```shell
location / {
    satisfy any;

    allow 192.168.1.0/32;
    deny  all;

    auth_basic           "closed site";
    auth_basic_user_file conf/htpasswd;
}

```
上面的配置中，只要ip满足规则或者basic auth认证正常就可以访问。换句话说，如果想访问对应的localtion的话，要么ip符合规则，要么通过basic auth认证。

## 3.指定文件查找顺序

指令: try_files file ... uri;   
      try_files file ... =code;  
默认值: 无  
配置上下文: server, location  

按指定顺序检查文件是否存在，并使用找到的第一个文件进行请求处理; 该处理在当前上下文中执行。文件的路径是根据root和alias指令, 从file参数构造的。可以通过在名称末尾指定斜杠来检查目录是否存在，例如“$uri/”。 如果未找到任何文件，则进行内部重定向到最后一个参数中指定的uri。

示例:
```shell
location /images/ {
    try_files $uri /images/default.gif;

}

location = /images/default.gif {
    expires 30s;

}

```
最后一个参数也可以指向一个指定的位置，如下面的示例所示。从0.7.51版本开始，最后一个参数也可以是一个code,即状态码:

```shell
location / {
    try_files $uri $uri/index.html $uri.html =404;

}
```

在react相关部署中，nginx常用try_files来进行配置:

```
location / {
    try_files $uri $uri/ /index.html;
}

```
## 4.核心模块提供的内置变量

nginx核心模块提供很多内置变量，在我们做一些逻辑处理时很有用，我把常用的变量在下面列出来，未出现的可直接查看官方文档;
```shell
$arg_name: 请求行中的参数名称, 例如?a=1, $arg_a的值就为1;

$args: 请求行中的参数

$binary_remote_addr: 客户端地址（采用二进制格式），对于IPv4地址，值的长度始终为4个字节，对于IPv6地址，值的长度始终为16个字节

$cookie_name: 对应名称cookie

$document_uri: 和$uri一样

$host: 按照以下优先顺序：请求行中的主机名，或“Host”请求标头字段中的主机名，或与请求匹配的服务器名

$hostname: 主机名

$http_name: 任意请求头字段, 变量名称name的最后一部分是将http的header字段名称转换为小写字母，并用下划线代替短划线

$https: 如果连接以SSL模式运行，则为“on”，否则为空字符串

$is_args: “?”如果请求行包含参数，否则为空字符串

$remote_addr: 客户端地址

$remote_port: 客户端端口

$remote_user: basic auth身份验证随附的用户名

$request_filename: 当前请求的文件路径（基于root或alias伪指令以及请求URI）

$request_method: 请求方法，通常是“GET”或“POST”

$request_uri: 完整的原始请求URI（带有参数）

$scheme: 请求协议, “http”或“https”

$server_addr: 接受请求的服务器的地址

$server_name: 接受请求的服务器的名称

$status: 响应状态码

$uri: 请求中的当前URI，已规范化
```


## 5. 总结 
nginx核心模块的讲解已基本完毕，更详细的细节还需要大家仔细阅读nginx的官方文档即可;
