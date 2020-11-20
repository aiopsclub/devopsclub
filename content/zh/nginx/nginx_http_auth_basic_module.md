---
title : "Nginx之Http模块系列之basicauth模块"
weight : 16 
---

> `basic_auth`模块为nginx提供了“HTTP Basic Authentication“协议的支持。 

## 1. 简介  
`ngx_http_auth_basic_module`模块使得nginx可以通过使用“HTTP Basic Authentication”协议验证用户名和密码来限制对资源的访问。  


## 2.实例
我们看一个实例，具体分析一下： 

```shell
location / {
    auth_basic           "closed site";
    auth_basic_user_file conf/htpasswd;
}
```
以上的示例配置表示nginx将会在localtion匹配的请求中开启BasicAuth支持，realm为"closed site"，用户名和密码文件为conf/htpasswd.  

## 3.配置格式
```shell
Syntax: auth_basic string | off;
Default:    
auth_basic off;
Context:    http, server, location, limit_except
```
启用基于“HTTP Basic Authentication”协议的用户名和密码的验证。指定的参数string用作领域，参数值可以包含变量(1.3.10、1.2.7)，特殊值off取消了从先前的配置级别`auth_basic`指令效果的继承。    

```shell
Syntax:	auth_basic_user_file file;
Default: —
Context: http, server, location, limit_except
```
指定以下保存用户名和密码的文件，格式如下:  

```shell
# comment
name1:password1
name2:password2:comment
name3:password3
```
file参数可以包含变量。  

密码类型可以是三种类型:    
* 用crypt()函数加密;可以通过使用Apache HTTP Server发行版中的`htpasswd`或`openssl passwd`命令生成。
* 使用基于MD5的密码算法(apr1)的Apache变体进行哈希处理;可以使用相同的工具生成；
* 由RFC2307中所述的“{scheme} data”语法(1.0.3+)指定;当前实施的方案包括PLAIN(一个示例, 不应使用)，SHA(1.3.13)(普通的SHA-1哈希, 不应使用)和SSHA(基于salt的SHA-1哈希，主要被默写软件包使用, 特别是OpenLDAP和Dovecot)。  

## 4.总结
`ngx_http_auth_basic_module`可以帮助我们在http资源没有任何保护的情况下，添加基础的认证。在某些业务条件下，非常有用。  
