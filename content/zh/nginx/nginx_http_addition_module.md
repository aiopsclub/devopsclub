---
title : "Nginx之Http模块系列之addition模块"
weight : 15 
---

> addition模块可以通过子请求响应内容来更改response响应体，位置可以是response前或者后。 

## 1. 简介  
`ngx_http_addition_module`模块是一个在响应之前和之后添加文本的过滤器。 默认情况下未构建此模块，应使用`--with-http_addition_module`配置参数启用它。  


## 2.实例
我们看一个实例，具体分析一下： 

```shell
location / {
    add_before_body /before_action;
    add_after_body  /after_action;
}
```
以上的示例配置表示nginx将会在响应体之前添加`/before_action`子请求的内容，在响应体之后添加`/after_action`的子请求的内容。

## 3.配置格式
```shell
Syntax:	add_before_body uri;  
Default: —  
Context: http, server, location  
```
在响应正文之前添加给定的子请求而返回的文本。 uri为空字符串(“”)时，将取消从先前配置级别继承的配置值。    

```shell
Syntax:	add_after_body uri;  
Default: —  
Context: http, server, location   
```
与`add_before_body`指令类似，`add_after_body`是在响应正文之后添加子请求的返回的文本。   

```shell
Syntax:	addition_types mime-type ...;    
Default:  addition_types text/html;    
Context:  http, server, location   
```
该指令出现在0.7.9版本之后。  

除了“text/html”之外，还允许在具有指定MIME类型的响应中添加文本。“*”表示与任何MIME类型(0.8.29)匹配。

