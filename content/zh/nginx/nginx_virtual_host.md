---
title : "Nginx系列之server虚拟主机"
weight : 9 
---

> 业务配置中，我们经常接触nginx的虚拟主机。那什么是虚拟主机呢？其实虚拟主机简单说就是在nginx开启一个个独立的网站，这些网站统一由nginx进行分发，互相隔离。今天我们就来详细说一下nginx的虚拟主机，虚拟主机分为三类：基于域名的虚拟主机、基于ip的虚拟主机、基于端口的虚拟主机三种。

## 1. 基于域名的虚拟主机

```shell
# nginx.conf

worker_processes auto;

error_log /var/log/nginx/error.log info;

events {
    worker_connections  1024;
}

# 简单示例
http {
    server {
        listen      80;
        server_name example.org www.example.org;
        ...
    }
    
    server {
        listen      80;
        server_name example.net www.example.net;
        ...
    }
    
    server {
        listen      80;
        server_name example.com www.example.com;
        ...
    }
}

```
从配置文件中可以知道，开启了三个server，也就是三个虚拟主机，他们都监听在80端口，但是server_name不一样，nginx根据请求中的Host头部，来进行请求的分发，但是如果都没有匹配或者根本就不包含Host头部，nginx会将请求路由至80端口的默认虚拟主机，在上面的配置中，默认虚拟主机是第一个server，这是默认的配置，还可以通过listen之类的default_server参数来制定默认虚拟主机。配置样例如下:   
```shell
server {
    listen      80 default_server;
    server_name example.net www.example.net;
}
```
在实际业务，如果请求中不存在Host头部，我们可以认为这是非法请求，应该进行特殊处理，nginx同样支持该操作，配置如下:  
```shell
server {
    listen      80;
    server_name "";
    return      444;
}
```
在上面的配置中，server_name设置为一个空字符串，它将匹配在没有Host头字段的请求，并且返回一个特殊的nginx的非标准状态码444来关闭连接。 在0.8.48版本之后，server_name ""配置可省略。 

## 2. 基于ip的虚拟主机
```shell
server {
    listen      192.168.1.1:80;
    server_name example.org www.example.org;
    ...
}

server {
    listen      192.168.1.1:80;
    server_name example.net www.example.net;
    ...
}

server {
    listen      192.168.1.2:80;
    server_name example.com www.example.com;
    ...
}
```
看上面的配置，定义了两个server，即两个虚拟机主机，不同点在于监听在不同的ip以及server_name，这就是基于ip的虚拟主机以及基于域名的虚拟主机的混合。在请求处理中，nginx的匹配规则如下：  
nginx首先根据请求中对应的ip和端口与listen指令后的ip和端口匹配，筛选虚拟主机。然后，在筛选出的虚拟主机中，通过server_name与Host请求头部进行匹配，来决定请求的路由。如果没有找到对应的虚拟机主机，请求将由默认服务器处理。

## 3. 基于端口的虚拟主机
```shell
server {
    listen      192.168.1.1:80;
    server_name example.org www.example.org;
    ...
}

server {
    listen      192.168.1.1:90;
    server_name example.net www.example.net;
    ...
}
```
其实简单的讲，基于ip和基于域名的虚拟主机是一类，因为nginx在进行请求匹配时，会将ip和端口放在一起考虑，所以两者的匹配规则是一致，在这里就不在进行赘述。  

## 4. 虚拟主机的合理配置
在实际业务中，我们可能在一台虚拟机上面配置很多虚拟主机，如果配置在一个文件中，这将会导致文件臃肿，最好的方式是编程的思维，将虚拟主机配置在单独文件中，通过include导入到主配置文件即可。

## 5. 总结
nginx的虚拟主机，我们业务中最常用的功能，希望同学们好好掌握，记住nginx的虚拟主机的匹配规则，更改的把握nginx，才能更好的服务于业务。

