---
title : "Nginx模块系列之核心模块"
weight : 11 
---

> Nginx核心模块为nginx提供核心配置功能，包括静态目录配置、localtion匹配、限速以及各种优化参数，下面针对这几方面详细展开来说nginx的核心模块; 

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
设置客户端请求body的最大允许大小，在“ Content-Length”请求标头字段中指定。 如果请求中的大小超过配置的值，则会向客户端返回413(Request Entity Too Large)错误。 请注意，浏览器无法正确显示此错误。将size设置为0将禁用对客户端请求主体大小的检查。


## 3. 优雅的错误处理 

