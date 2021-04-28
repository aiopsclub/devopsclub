---
title : "Nginx之Http模块系列之empty_gif模块"
weight : 20 
---

> `empty_gif`模块主要是用于发出单像素透明GIF。 

## 1. 简介  
`ngx_http_empty_gif_module`模块，用于发出单像素透明GIF。


## 2.配置示例

```shell
location = /_.gif {
    empty_gif;
}
```
当匹配到`/_.gif`的请求时，返回单像素透明gif做为http响应体。

## 3.配置格式
```shell
Syntax:	empty_gif;
Default:	—
Context:	location
```
默认不开启，只存在于localtion上下文中。

## 4.总结
`ngx_http_empty_gif_module`没有太多可介绍，我们主要记住其主要作用，在业务需要时，进行配置即可。  
