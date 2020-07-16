---
title : "Nginx系列之websocket反向代理"
weight : 8 
---

> WebSocket 是 HTML5 开始提供的一种在单个 TCP 连接上进行全双工通讯的协议。该协议使得客户端和服务器之间的数据交换变得更加简单，允许服务端主动向客户端推送数据。在 WebSocket API 中，浏览器和服务器只需要完成一次握手，两者之间就直接可以创建持久性的连接，并进行双向数据传输。在 WebSocket API 中，浏览器和服务器只需要做一个握手的动作，然后，浏览器和服务器之间就形成了一条快速通道。两者之间就直接可以数据互相传送。 如此强大的协议，从1.3.13版本开始，nginx添加对webdocket反向代理支持，让我们的websocket处理能力大大提升。

## 1. nginx配置 

```shell
# nginx.conf

worker_processes auto;

error_log /var/log/nginx/error.log info;

events {
    worker_connections  1024;
}

# 简单示例
http {
    upstream backend {
        server 127.0.0.1:8000;
    }

    location /chat/ {
        proxy_pass http://backend;

        # 主要websocket代理配置, $http_upgrade是指http协议头部Upgrade的值. 
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# 复杂示例, 由于Connection协议头的值取决于Upgrade的值，我们可以利用map模块，动态生成Connection头的值，配置如下:

http {

    upstream backend {
        server 127.0.0.1:8000;
    }

    # map指令的含义，根据$http_upgrade不同值来对$connection_upgrade变量进行赋值，默认为upgrade；$connection_upgrade可以再后续配置中进行引用即可;
    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    server {

        location /chat/ {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
        }
    }
}


```
经过以上简单的配置，nginx -s reload后，nginx即可作为websocket反向代理服务器。这段配置的关键在于server配置段中的proxy_http_version、proxy_set_header指令，分别设置http_veresion、Upgrade、Connection头部，从而实现http到webdocket的升级。

## 2. 总结
nginx的websocket代理虽然比较特殊，但是配置起来异常简单。它同样可以利用`ngx_http_upstream_module`模块，实现服务器逻辑组，这样使我们的架构更加的灵活。

