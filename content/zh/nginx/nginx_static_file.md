---
title : "Nginx系列之nginx静态文件服务"
weight : 5 
---

> nginx作为web服务器，在静态文件服务方面有着卓越的性能，我们可以很方便的搭建文件服务，方便文件在网络上分享，接下来我们就来看一下nginx静态服务的具体配置:

## 1. nginx配置 

```shell
# nginx.conf

user nginx;
error_log /var/log/nginx/error.log;

http {

    server {
		listen 80;

        location / {
			autoindex on;
            root /data/www;
        }
    }
}

```
经过以上简单的配置，nginx -s reload后，nginx即可作为静态文件服务器。这段配置的关键在于server配置端，nginx中使用localtion匹配uri，root来指定文件服务的根目录。autoindex指令作用是当找不到index文件[`默认index.html`]，会以html的格式返回文件服务根目录的文件列表。

## 2. 静态文件规则

当我们访问的uri为/a/b/c.txt时，nginx会到/data/www/找对应目录结构的文件，即/data/www/a/b/c.txt，具体分为以下几种情况：
1. 文件存在，直接返回c.txt.文件的内容;
2. 文件不存在，如果autoindex未开启，则会返回404页面，否则的话nginx会先判断/data/www/a/b目录是否存在，存在直接返回/data/www/a/b的文件列表，否则的话直接返回404页面。

简单说，当文件访问请求到达时，nginx会将请求的uri和root之类后的参数拼在一起，然后去文件系统寻找对应的文件。

## 3. 实际效果
```shell
# /data/www目录结构
[root@localhost www]# tree
.
├── a
└── abc
    └── e

1 directory, 2 files
```
![浏览器访问效果](https://s1.ax1x.com/2020/06/27/N62HGF.gif)

## 4. 总结
在nginx配置中，localtion可以有多个，支持精确匹配、前缀匹配和正则匹配，且他们都有着固定的匹配顺序规则，这些内容会有专门的文章介绍，现在我们只需要知道如何快速搭建自己的文件服务即可。
