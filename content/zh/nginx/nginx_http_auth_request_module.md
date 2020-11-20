---
title : "Nginx之Http模块系列之authrequest模块"
weight : 17 
---

> `auth_request`模块主要作用是通过子请求的响应状态码来实现客户端授权。 

## 1. 简介  
`ngx_http_auth_request_module`模块(1.5.4+)根据子请求的响应结果实现客户端授权。如果子请求返回2xx响应代码，则允许访问。如果返回401或403，则使用相应的错误代码拒绝访问。子请求返回的任何其他响应代码都被视为错误。  
对于401错误，客户端还从子请求响应中接收“WWW-Authenticate”标头。  
默认情况下未构建此模块，应使用`--with-http_auth_request_module`配置参数启用它。  


## 2.实例
我们看一个实例，具体分析一下： 

```shell
location /private/ {
    auth_request /auth;
    ...
}

location = /auth {
    proxy_pass ...
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
    proxy_set_header X-Original-URI $request_uri;
}
```
以上的示例配置表示nginx将会客户端请求/private时，通过`auth_request`指令来进行客户端授权，即通过对/auth的访问的响应结果，来决定/private/是否允许继续访问。  

## 3.配置格式
```shell
Syntax:  auth_request uri | off;
Default:  auth_request off;
Context:  http, server, location
```
根据子请求的结果启用授权，并设置将子请求发送到的URI。  

```shell
Syntax:	 auth_request_set $variable value;
Default:  —
Context:  http, server, location
```
授权请求完成后，将variable置为value。该值可能包含授权请求中的变量，例如`$upstream_http_*`。  

## 4.总结
`ngx_http_auth_request_module`可以帮助我们实现对资源的统一权限验证，这在微服务中非常有用，我们可以实现自己的权限认证服务，将所有的资源的请求都通过权限认证服务后再进行处理，提高了系统的安全性。 但同时会增加请求的响应时间，因为此时每次请求都会发起两次http调用。   
