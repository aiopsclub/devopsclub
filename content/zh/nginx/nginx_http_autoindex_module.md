---
title : "Nginx之Http模块系列之autoindex模块"
weight : 18 
---

> `autoindex`模块主要作用是当index文件不存在时返回目录列表至客户端。 

## 1. 简介  
`ngx_http_autoindex_module`模块处理以斜杠('/')结尾的请求，并生成目录列表。通常，当`ngx_http_index_module`模块找不到索引文件时，会将请求传递给`ngx_http_autoindex_module`模块。  


## 2.实例
我们看一个实例，具体分析一下： 

```shell
location / {
    index index.html;
    autoindex on;
}
```
以上的示例配置表示index.html不存在时，nginx将会生成目录列表返回至客户端。  

## 3.配置格式
```shell
Syntax:	autoindex on | off;
Default: autoindex off;
Context: http, server, location
```
启用或禁用目录列表输出。  

```shell
Syntax: autoindex_exact_size on | off;
Default: autoindex_exact_size on;
Context: http, server, location
```
对于HTML格式，指定是在目录列表中输出确切的文件大小，还是四舍五入为千字节，兆字节和千兆字节。
```shell
Syntax:	autoindex_format html | xml | json | jsonp;
Default: autoindex_format html;
Context: http, server, location

This directive appeared in version 1.7.9.
```
设置目录列表的格式。  
使用JSONP格式时，使用callback请求参数设置回调函数的名称，如果参数丢失或值为空，则使用JSON格式。  
可以使用`ngx_http_xslt_module`模块转换XML输出。  

```shell
Syntax:	autoindex_localtime on | off;
Default: autoindex_localtime off;
Context: http, server, location
```
对于HTML格式，指定是在本地时区还是在UTC中输出目录列表中的时间。  

## 4.总结
`ngx_http_autoindex_module`在nginx做为文件下载服务时非常有用，可以方便的浏览文件信息。  
