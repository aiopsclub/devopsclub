---
title : "Nginx之Http模块系列之访问控制模块"
weight : 14 
---

> 接下来我们开始逐个模块讲解nginx，相信这部分结束后，大家对nginx支持的模块功能能做到心知肚明。 

## 1. 简介  
`ngx_http_access_module`模块可以限制对某些客户端地址对服务器的访问。


## 2.实例
我们看一个实例，具体分析一下： 

```shell
location / {
    deny  192.168.1.1;
    allow 192.168.1.0/24;
    allow 10.1.1.0/16;
    allow 2001:0db8::/32;
    deny  all;
}
```
Nginx会依次检查访问控制规则，直到找到第一个匹配规则，allow则允许，deny则禁止访问。在此示例中，仅允许IPv4网络10.1.1.0/16和192.168.1.0/24(不包括地址192.168.1.1)以及IPv6网络2001:0db8::/32进行访问。 

## 3.配置格式
指令: allow address | CIDR | unix: | all; 
默认值: 无 
配置上下文: http, server, location, limit_except 
允许访问指定的网络或地址。如果指定特殊值unix:(1.5.1)，则允许访问所有UNIX域套接字。 
另外一个指令为deny，配置格式和allow一致，deny的功能为拒绝访问。
## 4. 注意点
`ngx_http_access_module`模块使用时，需确保nginx能获取客户端的真实地址，否则不会生效。  

