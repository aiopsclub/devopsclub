---
title : "Nginx系列之server_name定义与匹配规则"
weight : 10 
---

>server_name用来指定请求中的Host头部，在上一节的基于域名的虚拟机中，nginx匹配的规则就是根据server_name的不同，结合请求头的Host头部，来决定请求的路由目标。server_name有三种不同的配置格式，且不用配置格式的优先级也不相同。接下来我们学习一下具体的配置格式与匹配顺序。

## 1. server_name的配置格式之通配符匹配

```shell
# nginx.conf

server {
    listen       80;
    server_name  *.example.org;
    ...

}

server {
    listen       80;
    server_name  mail.*;
    ...

}
```
通配符格式中的`*`号只能在域名的开头或结尾，并且`*`号两侧只能是`.`，所以`www.*.example.org`和`w*.example.org`是无效的。`*`号可以匹配多个域名部分，`*.example.org`不仅与`www.example.org`匹配，而且也与`www.sub.example.org`匹配。  
`.example.org`是比较特殊的通配符格式, 可以同时匹配确切名称`example.org`和通配符名称`*.example.org`。

## 2. server_name的配置格式之正则匹配

```shell
server {
    listen       80;
    server_name  ~^(?<user>.+)\.example\.net$;
    ...
}

```
正则匹配格式，必须以`~`开头，比如：`server_name  ~^www\d+\.example\.net$;`。如果开头没有`~`，则nginx认为是精确匹配，或者如果匹配字符中含有`*`号，则会被认为是通配符匹配，不过非法的通配符格式。在逻辑上，需要添加`^`和`$`锚定符号。注意，正则匹配格式中`.`为正则元字符，如果需要匹配`.`，则需要反斜线转义。如果正则匹配中含有`{`和`}`则需要双引号引用起来，避免nginx报错，如果未加双引号，则nginx会报如下错误：`directive "server_name" is not terminated by ";" in ...`。
正则表达式命名捕获的变量可以在nginx进行引用，下面示例:
```shell
server {
    server_name   ~^(www\.)?(?<domain>.+)$;

    location / {
        root   /sites/$domain;
    
    }
}
```
正则表达式捕获也可以通过数字进行引用，下面示例:
```shell
server {
    server_name   ~^(www\.)?(.+)$;
    location / {
        root   /sites/$2;
    }
}
```
数字引用不推荐使用，此种方式容易被覆盖。



## 3. server_name的配置格式之精确匹配
```shell
server {
    listen       80;
    server_name  example.org  www.example.org;
    ...
}
```
精确匹配格式指的除了通配符匹配和正则匹配之外的格式，就这么简单。  

## 4. 特殊匹配格式

```shell
1. server_name ""; 匹配Host请求头不存在的情况。
2. server_name "-"; 无任何意义。
3. server_name "*"; 它被错误地解释为万能的名称。 它从不用作通用或通配符服务器名称。相反，它提供了server_name_in_redirect指令现在提供的功能。 现在不建议使用特殊名称“ *”，而应使用server_name_in_redirect指令。 
```
## 5. 匹配顺序 

```shell
1. 精确的名字
2. 以*号开头的最长通配符名称，例如 *.example.org
3. 以*号结尾的最长通配符名称，例如 mail.*
4. 第一个匹配的正则表达式（在配置文件中出现的顺序）
```

## 6. 优化 
```shell
1. 尽量使用精确匹配;
2. 当定义大量server_name时或特别长的server_name时，需要在http级别调整server_names_hash_max_size和server_names_hash_bucket_size，否则nginx将无法启动。
```
