---
title : "Nginx系列之nginx配置文件"
weight : 3 
---

> Nginx有很多功能，那这些功能的控制是怎么样的呢？这就需要nginx配置文件来支持，nginx的配置逻辑很强大和灵活，支持逻辑判断等高级功能，但这并不意味nginx的配置很复杂，接下来就开始学习如何配置nginx吧。

## nginx配置文件示例 

```shell
user nginx;
worker_processes  1;
events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    server {
        listen       80;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
}
```

## nginx配置文件解析

Nginx由模块组成，模块的行为受配置文件中的指令控制。指令分为简单伪指令和块指令。一个简单的指令由名称和参数组成，名称和参数之间用空格分隔，并以分号(;)结尾。块指令的结构与简单指令的结构相同，但是它不是以分号结尾，而是以一组大括号({和})包含，其大括号内部由可由简单指令和块指令组成。如果块指令在括号内包含其他指令，则将其称为context(比如：events，http，server和localtion）。

在配置文件中，放置在任何content外部的指令都被视为在main上下文中。events和http指令位于main上下文中，server位于http上下文中，location位于server中。
"＃"号后的内容被视为注释。

## 示例配置解析
由nginx的配置规则可知，在示例文件中，可以看到user, worker_processes等简单指令， events，http，locacation等块指令，nginx中大部分指令都有默认值，可根据需要进行修改。
在实际使用中，我们不需要从头开始写配置，nginx安装完成后，提供样例配置文件，我们可以在此基础上按照我们的业务要求进行定制化修改即可。

## 总结
万事开头难，第一次接触nginx配置文件，可能觉得很复杂，那么多指令，我该如何记忆。其实不用过于担心，在nginx的官方文档中，对所有的配置配置都进行了详细的解释，我们可以参考官方文档即可，并且常用的指令很少，我相信，多看几次，你也可以成为nginx配置高手。 
具体的功能如何配置，我们在具体的应用场景中再具体分析；
